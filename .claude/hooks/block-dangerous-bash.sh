#!/usr/bin/env bash
#
# block-dangerous-bash.sh
# Claude Code PreToolUse hook（matcher: "Bash"）。
# 標準入力で受け取る JSON の .tool_input.command を検査し、
#   - 高確度の破壊的操作      → exit 2（完全ブロック / DENY）
#   - 復元可能だが要注意の操作 → exit 0 + ask-JSON（確認プロンプト / ASK）
#   - それ以外                → exit 0（許可 / ALLOW）
# とする。判定は best-effort（厳密な SQL/シェルパーサではない）。
#
# 設計方針: 狭く強制（誤検知を出さない範囲で確度の高いものだけ DENY）＋
#           グレーゾーンは ASK、文脈依存は AGENTS.md で明文化（hook 対象外）。
#
# 本ファイルは 2 系統の実装を統合した版:
#   (A) epro-saas #3109 系（Codex レビュー P1-1/P1-2/P1-3 反映済み）
#       ヒアドキュメント除去・セグメント分割・git 呼び出しトークナイザ
#   (B) beyonds-claude PR #64 系
#       クォート潰しによる誤検知抑止・シークレット読み出し DENY・テンプレ除外の一元化
#
# 前処理:
#   - ヒアドキュメント本文（データであってコマンドではない）を判定前に除去する（R1）。
#     << はクォート内・コメント内では演算子として扱わず、1行に複数並ぶ形（P2-4）や
#     終端行が見つからない場合（フェイルクローズ：本文候補を解析対象へ戻す）にも対応する。
#     ただし mysql/psql/mariadb 経由の SQL はヒアドキュメントで渡すのが常道なので、
#     DB クライアント行の本文だけは元の行に連結して残す（DENY #2 の捕捉率を維持する）。
#   - 複合コマンド（; / && / || / パイプ / 改行）はセグメントに分割し、セグメント単位で
#     判定する（R3）。無関係なセグメント同士の単語結合による誤検知を防ぐ。分割はクォート
#     （'...' / "..."）を考慮する簡易版であり、$( ) やバッククォートによるネストした
#     コマンド置換の中までは解釈しない（完全なシェルパーサは目指さない）。
#   - 各セグメントについて「クォート内を空白に潰したコピー」を作り、**コマンドが起動されて
#     いるか**の判定はそのコピーで、**引数が何か**の判定は原文で行う。
#     `git commit -m "git push --force は禁止"` のような散文を実行コマンドと取り違えない。
#   - git 判定は「git と push が文字列中のどこかにあるか」ではなく、セグメント内で
#     実際に git がコマンド語として書かれているか（環境変数代入・command/env/exec/sudo/
#     nice/nohup/time 等のランチャーを読み飛ばした先頭語）で行う（R2 / P1-2）。
#   - git push のサブコマンド判定はグローバルオプションのホワイトリストに頼らず、
#     git --help のシノプシスに基づく分類でトークンを歩く。未知のオプションに遭遇した
#     場合は見逃す（fail open）よりも push の可能性ありとして扱う（P1-3）。
#   - DENY 時のメッセージには、検出ルール名とどのセグメントの何にマッチしたかを含める（R4）。
#
# 環境変数:
#   GUARDRAIL_DISABLE=1            このセッションでガードレールを無効化
#   GUARDRAIL_PROTECTED_BRANCHES  push を禁止するブランチ（既定: "main master"）
#
set -o pipefail

PROTECTED_BRANCHES="${GUARDRAIL_PROTECTED_BRANCHES:-main master}"

cmd=""

# ---- JSON から .tool_input.command を取り出す（jq → python3 の順、無ければ fail-open）----
extract_command() {
  local input="$1" out rc
  if command -v jq >/dev/null 2>&1; then
    out="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    rc=$?
    # jq が存在しても失敗しうる（入力が壊れている・jq が古い）。その場合は黙って
    # 素通しせず python3 にフォールバックする。
    if [ "$rc" -eq 0 ]; then
      printf '%s' "$out"
      return 0
    fi
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("command", "") or "")
except Exception:
    pass' 2>/dev/null
    return 0
  fi
  return 1
}

deny() {
  local rule="$1"
  local reason="$2"
  local detail="${3:-}"
  {
    echo "🚫 beyonds-claude-guardrails によりブロックしました。"
    echo "   コマンド: $cmd"
    echo "   検出ルール: $rule"
    if [ -n "$detail" ]; then
      echo "   該当箇所: $detail"
    fi
    echo "   理由: $reason"
    echo "   どうしても必要なら内容を確認のうえ手動実行するか、このセッション限定で GUARDRAIL_DISABLE=1 を設定してください。"
  } >&2
  exit 2
}

ask() {
  local reason="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

# ===== クォート内を空白に潰したコピー =====
# 「コマンドが起動されているか」の判定はこのコピーで行い、「引数が何か」の判定は原文で行う。
# コミットメッセージ・PR 本文に書かれた散文（`git commit -m "rm -rf / は禁止"`）を
# 実行コマンドと取り違えないため。クォートが閉じていない場合は解析を諦めて原文を返す
# （見逃すより誤検知側に倒す）。
#
# ただしクォートの中身が「空白もシェルメタ文字も含まない 1 語」の場合だけは潰さずに
# そのまま残す。シェルにとって `"git" push` は `git push` と完全に等価であり、潰すと
# クォートを 1 つ足すだけで全ルールを迂回できてしまうため（Codex レビュー指摘）。
# 散文は必ず空白を含むので、この緩和で誤検知は増えない。
blank_quoted() {
  local c="$1" ch q="" out="" buf="" i n
  n=${#c}
  for (( i = 0; i < n; i++ )); do
    ch="${c:i:1}"
    if [ -n "$q" ]; then
      if [ "$ch" = "$q" ]; then
        q=""
        # 中身が「ファイル名・オプション相当の 1 語」なら復元、それ以外は同じ長さの空白へ潰す。
        # 判定はホワイトリスト（空白・シェルメタ文字・展開記号を一切含まない語のみ通す）。
        if [[ $buf =~ ^[A-Za-z0-9._/@:=+,~^-]+$ ]]; then
          out="$out$buf "
        else
          out="$out${buf//?/ } "
        fi
        buf=""
      else
        buf="$buf$ch"
      fi
      continue
    fi
    case "$ch" in
      \'|\")
        q="$ch"
        buf=""
        out="$out "
        ;;
      *)
        out="$out$ch"
        ;;
    esac
  done
  if [ -n "$q" ]; then
    printf '%s' "$c"
    return
  fi
  printf '%s' "$out"
}

# mysql/mariadb/psql がコマンドとして起動されているか
# /usr/bin/mysql のような絶対パス起動も拾えるよう前境界に / を含める。
# 後境界に < > を含めるのは `mysql<<SQL` / `mysql<dump.sql` のように空白を空けずに
# リダイレクトが続く書き方を取りこぼさないため。
is_db_client() {
  [[ $1 =~ (^|[[:space:]\;\&\|/])(mysql|mariadb|psql)([[:space:]<>]|$) ]]
}

# シェルインタプリタがコマンドとして起動されているか（bash <<'EOF' ... EOF 形式）。
# この場合ヒアドキュメント本文は「データ」ではなく実行されるスクリプトなので、
# 除去せず判定対象に残す必要がある。python/node 等は本文がシェルではないので対象外。
is_shell_interpreter() {
  [[ $1 =~ (^|[[:space:]\;\&\|/])(bash|sh|zsh|ksh|dash)([[:space:]]|$) ]]
}

# テンプレ（秘密値を含まない）ファイルの basename 判定。.env.example.{顧客}.{環境} 等のバリアント含む。
# 読み取り（is_secret_read）と書き込み（is_env_write）の除外リストはこの1箇所で管理する。
is_template_base() {
  case "$1" in
    .env.example|.env.example.*|.env.sample|.env.sample.*|.env.dist|*.public.env)
      return 0
      ;;
  esac
  return 1
}

# ===== R1: ヒアドキュメント本文の除去（Codex レビュー P1-1 / P2-4 対応版）=====
# ヒアドキュメントの中身は実行されないデータであり、原則として判定対象から除外する
# （誤検知の主因）。
# << はクォート内・コメント内では単なる文字であり演算子ではないため、行を文字単位で
# 走査してクォート（'...' / "..."、行をまたいで状態を引き継ぐ）とコメント（行頭または
# 空白/;/&/| の直後に現れる # 以降、行末まで）を追跡したうえで検出する。
# 対応形式: <<WORD / <<'WORD' / <<"WORD" / <<-WORD（終端行の先頭タブのみ除去）。
# ヒアストリング <<< は本文を持たないため対象外。
# 1行に複数のヒアドキュメントが並ぶ形（cat <<A <<B）も宣言順にキューで処理する（P2-4）。
# フェイルクローズ: 開始したヒアドキュメントに対応する終端行が最後まで見つからない場合
# （誤検出、あるいは実際に閉じていない入力）、本文として溜めていた行を捨てずに解析対象へ
# 戻す。無条件に読み飛ばして危険なコマンドを見逃す方が、誤検知より遥かに危険なため。
#
# keep-db モード（$2 = "keep-db"）: ヒアドキュメントの開始が DB クライアント行
# （mysql/psql/mariadb）にある場合だけ、本文を捨てずに**開始行そのものへ連結して**残す。
# 独立した行として残さないのは、後段のセグメント分割で SQL が mysql から切り離され
# is_db_client の判定を外してしまうため。連結時にシェルのメタ文字（; | & クォート）は
# 空白へ潰す（SQL 本文であってシェルではないので、潰しても判定に必要な語は失われない）。
strip_heredocs() {
  local s="$1"
  local mode="${2:-}"
  local -a out_lines=()
  local -a pending_body=()
  local -a hd_delims=()
  local -a hd_strips=()
  local -a hd_keeps=()
  local hd_idx=0
  local in_heredoc=0
  local in_squote=0 in_dquote=0
  local line check pb sanitized last
  local tab
  tab="$(printf '\t')"

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_heredoc" = "1" ]; then
      check="$line"
      if [ "${hd_strips[$hd_idx]}" = "1" ]; then
        check="${check#"${check%%[!$'\t']*}"}"
      fi
      if [ "$check" = "${hd_delims[$hd_idx]}" ]; then
        hd_idx=$((hd_idx + 1))
        pending_body=()
        if [ "$hd_idx" -ge "${#hd_delims[@]}" ]; then
          in_heredoc=0
          hd_delims=()
          hd_strips=()
          hd_keeps=()
          hd_idx=0
        fi
      else
        pending_body+=("$line")
        case "${hd_keeps[$hd_idx]}" in
          db)
            if [ "${#out_lines[@]}" -gt 0 ]; then
              sanitized="$line"
              sanitized="${sanitized//;/ }"
              sanitized="${sanitized//|/ }"
              sanitized="${sanitized//&/ }"
              sanitized="${sanitized//\'/ }"
              sanitized="${sanitized//\"/ }"
              last=$(( ${#out_lines[@]} - 1 ))
              out_lines[$last]="${out_lines[$last]} ${sanitized}"
            fi
            ;;
          exec)
            # bash <<EOF の本文は実行されるスクリプトそのもの。独立した行として残す
            out_lines+=("$line")
            ;;
          expand)
            # クォートされていない終端語のヒアドキュメントは本文が展開されるため、
            # コマンド置換だけは実際に実行される。その行だけ判定対象に残す。
            # 置換の開始・終了記号は `;` に均しておく。そうしないと `foo: $(git push ...)` の
            # git がコマンド位置と認識されず、後続のルールが素通ししてしまう。
            case "$line" in
              *'$('*|*'`'*)
                sanitized="$line"
                sanitized="${sanitized//\$(/; }"
                sanitized="${sanitized//\`/; }"
                sanitized="${sanitized//)/ ; }"
                out_lines+=("$sanitized")
                ;;
            esac
            ;;
        esac
      fi
      continue
    fi

    out_lines+=("$line")
    hd_delims=()
    hd_strips=()
    hd_keeps=()
    hd_idx=0

    local ch i len raw at_word_start in_comment j has_dash k c2 hd_quoted hd_prefix
    len=${#line}
    i=0
    in_comment=0
    at_word_start=1
    while [ "$i" -lt "$len" ]; do
      ch="${line:$i:1}"
      if [ "$in_squote" = "1" ]; then
        [ "$ch" = "'" ] && in_squote=0
        i=$((i + 1))
        at_word_start=0
        continue
      fi
      if [ "$in_comment" != "1" ] && [ "$ch" = '\' ] && [ $((i + 1)) -lt "$len" ]; then
        i=$((i + 2))
        at_word_start=0
        continue
      fi
      if [ "$in_dquote" = "1" ]; then
        [ "$ch" = '"' ] && in_dquote=0
        i=$((i + 1))
        at_word_start=0
        continue
      fi
      if [ "$in_comment" = "1" ]; then
        i=$((i + 1))
        continue
      fi
      case "$ch" in
        "'")
          in_squote=1
          i=$((i + 1))
          at_word_start=0
          continue
          ;;
        '"')
          in_dquote=1
          i=$((i + 1))
          at_word_start=0
          continue
          ;;
        '#')
          if [ "$at_word_start" = "1" ]; then
            in_comment=1
            i=$((i + 1))
            continue
          fi
          ;;
      esac
      if [ "$ch" = "<" ] && [ "${line:$((i + 1)):1}" = "<" ]; then
        j=$((i + 2))
        has_dash=0
        if [ "${line:$j:1}" = "-" ]; then
          has_dash=1
          j=$((j + 1))
        fi
        while [ "${line:$j:1}" = " " ] || [ "${line:$j:1}" = "$tab" ]; do
          j=$((j + 1))
        done
        if [ "${line:$j:1}" != "<" ]; then
          raw=""
          k="$j"
          while [ "$k" -lt "$len" ]; do
            c2="${line:$k:1}"
            case "$c2" in
              " "|";"|"&"|"|") break ;;
              *) [ "$c2" = "$tab" ] && break ;;
            esac
            raw="${raw}${c2}"
            k=$((k + 1))
          done
          if [ -n "$raw" ]; then
            # 終端語がクォート/エスケープされていれば本文は展開されない（リテラル）
            hd_quoted=0
            case "$raw" in
              \'*|\"*|\\*) hd_quoted=1 ;;
            esac
            case "$raw" in
              \'*\') raw="${raw#\'}"; raw="${raw%\'}" ;;
              \"*\") raw="${raw#\"}"; raw="${raw%\"}" ;;
            esac
            raw="${raw#\\}"
            hd_delims+=("$raw")
            if [ "$has_dash" = "1" ]; then
              hd_strips+=("1")
            else
              hd_strips+=("0")
            fi
            # この << より前（＝実際に起動されるコマンド部分）を見て本文の扱いを決める。
            # 起動判定はクォート潰し版で行う（散文に紛れた mysql/bash で誤判定しない）。
            hd_prefix="$(blank_quoted "${line:0:$i}")"
            if [ "$mode" = "keep-db" ] && is_db_client "$hd_prefix"; then
              hd_keeps+=("db")
            elif is_shell_interpreter "$hd_prefix"; then
              hd_keeps+=("exec")
            elif [ "$hd_quoted" = "0" ]; then
              hd_keeps+=("expand")
            else
              hd_keeps+=("0")
            fi
            in_heredoc=1
            i=$k
            at_word_start=0
            continue
          fi
        fi
        i=$((i + 2))
        at_word_start=0
        continue
      fi
      case "$ch" in
        " "|";"|"&"|"|")
          at_word_start=1
          ;;
        *)
          if [ "$ch" = "$tab" ]; then
            at_word_start=1
          else
            at_word_start=0
          fi
          ;;
      esac
      i=$((i + 1))
    done
  done <<< "$s"

  # フェイルクローズ: 最後までヒアドキュメントが閉じなかった場合、溜めていた本文候補行を
  # 解析対象に戻す（危険なコマンドの見逃し防止。誤検出だった場合も安全側に倒れるだけ）。
  # keep-db で既に連結済みの行がここで重複することがあるが、判定結果は変わらない。
  if [ "$in_heredoc" = "1" ] && [ "${#pending_body[@]}" -gt 0 ]; then
    for pb in "${pending_body[@]}"; do
      out_lines+=("$pb")
    done
  fi

  local result="" first=1 ol
  for ol in "${out_lines[@]}"; do
    if [ "$first" = "1" ]; then
      result="$ol"
      first=0
    else
      result="${result}"$'\n'"${ol}"
    fi
  done
  printf '%s' "$result"
}

# ===== R3: 複合コマンドのセグメント分割 =====
# ; / && / || / | および改行をトップレベル区切りとして分割する。
# '...' / "..." の中の区切り文字・引用符は分割対象にしない簡易パーサ（クォート追跡と
# バックスラッシュエスケープのみ対応。$( ) やバッククォートの中身までは解析しない
# ＝ネストしたコマンド置換内の危険操作は捕捉できない）。
SEGMENTS=()
split_into_segments() {
  local c="$1"
  SEGMENTS=()
  local cur="" ch nxt prev i len
  local in_squote=0 in_dquote=0
  len=${#c}
  i=0
  while [ "$i" -lt "$len" ]; do
    ch="${c:$i:1}"
    if [ "$in_squote" = "1" ]; then
      cur="${cur}${ch}"
      [ "$ch" = "'" ] && in_squote=0
      i=$((i + 1))
      continue
    fi
    # bare / ダブルクォート内どちらもバックスラッシュは次の1文字をエスケープ扱いにする
    if [ "$ch" = '\' ] && [ $((i + 1)) -lt "$len" ]; then
      cur="${cur}${ch}${c:$((i + 1)):1}"
      i=$((i + 2))
      continue
    fi
    if [ "$in_dquote" = "1" ]; then
      cur="${cur}${ch}"
      [ "$ch" = '"' ] && in_dquote=0
      i=$((i + 1))
      continue
    fi
    case "$ch" in
      "'")
        in_squote=1
        cur="${cur}${ch}"
        i=$((i + 1))
        continue
        ;;
      '"')
        in_dquote=1
        cur="${cur}${ch}"
        i=$((i + 1))
        continue
        ;;
    esac
    nxt="${c:$((i + 1)):1}"
    if { [ "$ch" = "&" ] && [ "$nxt" = "&" ]; } || { [ "$ch" = "|" ] && [ "$nxt" = "|" ]; }; then
      SEGMENTS+=("$cur")
      cur=""
      i=$((i + 2))
      continue
    fi
    # 単独の & はバックグラウンド実行の区切り（`true & git push --force ...`）なので分割する。
    # ただしリダイレクトの一部（2>&1 / >&2 / &>log / &>>log / <&3 / <&-）は区切りではないため、
    # 直前が > か <、あるいは直後が > の & は文字として扱う。
    # 直前 < を除外しないと `git push <&3 --force origin main` が `git push <` と
    # `3 --force origin main` に割れて force-push を取りこぼす（Codex レビュー指摘）。
    if [ "$ch" = "&" ]; then
      prev=""
      [ "$i" -gt 0 ] && prev="${c:$((i - 1)):1}"
      if [ "$prev" != ">" ] && [ "$prev" != "<" ] && [ "$nxt" != ">" ]; then
        SEGMENTS+=("$cur")
        cur=""
        i=$((i + 1))
        continue
      fi
    fi
    # `>|` は noclobber を無視した上書きリダイレクトであってパイプではない。
    # ここで分割すると `echo x >| .env` が `echo x >` と ` .env` に割れて env-write を取りこぼす。
    if [ "$ch" = "|" ]; then
      prev=""
      [ "$i" -gt 0 ] && prev="${c:$((i - 1)):1}"
      if [ "$prev" = ">" ]; then
        cur="${cur}${ch}"
        i=$((i + 1))
        continue
      fi
    fi
    case "$ch" in
      ";"|"|"|$'\n')
        SEGMENTS+=("$cur")
        cur=""
        i=$((i + 1))
        continue
        ;;
    esac
    cur="${cur}${ch}"
    i=$((i + 1))
  done
  SEGMENTS+=("$cur")

  # 空白のみのセグメントは判定対象外
  local -a kept=()
  local s
  for s in "${SEGMENTS[@]}"; do
    [ -z "${s//[[:space:]]/}" ] && continue
    kept+=("$s")
  done
  SEGMENTS=("${kept[@]}")
}

# ===== R2: git が実コマンド語として書かれているかの判定（Codex レビュー P1-2 対応版）=====
# セグメント先頭の空白・単純な環境変数代入（VAR=value ...）を読み飛ばした残り文字列が
# git（または /path/to/git）で始まる場合にのみ「git 呼び出し」とみなす。
# echo/grep/コメント等の引数・プローズ中に git という単語が出現するだけでは真としない。
#
# command / env / exec / sudo / nice / nohup / time は引数をそのまま実コマンドとして
# 実行するランチャーなので、その背後の git も検出する。bash -c / sh -c / su -c は引数が
# 「新たな文字列としてのシェルコマンド」であり再帰的な構文解析が必要になるため対象外
# （完全なシェルパーサは目指さない方針）。
GIT_LAUNCHERS=" command env exec sudo nice nohup time "

# 絶対パス・相対パス起動（/usr/bin/env git push ...）も同じランチャーとして扱う。
# パス接頭辞は「/ で始まる語」に限定し、bare な語は完全一致のままにする
# （env という名前のローカル変数・引数を誤ってランチャー扱いしないため）。
is_launcher_word() {
  local w="$1"
  case "$w" in
    /*|./*|../*) w="${w##*/}" ;;
  esac
  case "$GIT_LAUNCHERS" in
    *" $w "*) return 0 ;;
  esac
  return 1
}

git_invocation_tail() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  while [[ $s =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
    s="${BASH_REMATCH[1]}"
  done

  if [[ $s =~ ^(/[^[:space:]]*/)?git([[:space:]]|$) ]]; then
    printf '%s' "$s"
    return 0
  fi

  local first_word="${s%%[[:space:]]*}"
  is_launcher_word "$first_word" || return 1

  # ランチャー語・環境変数代入・オプションらしきトークン（-... 形式）を読み飛ばし、
  # その先頭が git そのものか確認する。ランチャーやオプションの正確な文法（値を
  # 取るかどうか等）までは解釈しないため、辿り着いた語が git と確認できない場合は
  # オプションの値を語として誤読している可能性がある（例: sudo -u root git push）。
  # その場合は見逃す（fail open）よりも、セグメント内のどこかに git という語が単語
  # 境界付きで存在すれば「git 呼び出しかもしれない」として扱う方が安全（fail-toward-DENY）。
  local rest="$s"
  local w
  while [ -n "$rest" ]; do
    w="${rest%%[[:space:]]*}"
    if is_launcher_word "$w" || [[ $w =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]] || [[ $w == -* ]]; then
      if [[ $rest =~ ^[^[:space:]]+[[:space:]]+(.*)$ ]]; then
        rest="${BASH_REMATCH[1]}"
      else
        rest=""
      fi
      continue
    fi
    break
  done

  if [[ $rest =~ ^(/[^[:space:]]*/)?git([[:space:]]|$) ]]; then
    printf '%s' "$rest"
    return 0
  fi

  if [[ $s =~ (^|[[:space:]])(git([[:space:]].*)?)$ ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

is_git_command() {
  git_invocation_tail "$1" >/dev/null
}

# ===== git push サブコマンドの判定（Codex レビュー P1-3 対応版）=====
# git のグローバルオプションを列挙してホワイトリスト化すると、そこに無いオプション
# （--no-pager / -P / --exec-path=... / --bare 等）が来た瞬間に fail open してしまう
# （P1-3）。そのため git --help のシノプシスに基づく分類でトークンを歩き、
#   - 値を取らない真偽値オプション → 1 トークン読み飛ばす
#   - 値が = で同一トークンに埋め込まれるオプション → 1 トークン読み飛ばす
#   - 値を必ず別トークンで取るオプション（-C / -c）→ 2 トークン読み飛ばす
#   - push という語に到達 → push と判定
#   - 上記どれにも当てはまらない - 始まりの未知オプション → 確信が持てないため
#     push の可能性ありとして扱う（fail-toward-DENY。これがホワイトリスト方式との
#     最大の違い）
#   - - で始まらない語に到達 → それが実際のサブコマンドであり push 以外なら安全に false
GIT_NOVAL_OPTS=" -v --version -h --help --html-path --man-path --info-path -p --paginate -P --no-pager --no-replace-objects --bare --literal-pathspecs --no-literal-pathspecs --glob-pathspecs --no-glob-pathspecs --icase-pathspecs --no-optional-locks --no-lazy-fetch --no-advice "
GIT_INLINEVAL_OPT_PREFIXES=" --exec-path --git-dir= --work-tree= --namespace= --super-prefix= --config-env= "
GIT_SEPVAL_OPTS=" -C -c "

is_git_push() {
  local tail
  tail="$(git_invocation_tail "$1")" || return 1

  local rest
  if [[ $tail =~ ^(/[^[:space:]]*/)?git([[:space:]]+(.*))?$ ]]; then
    rest="${BASH_REMATCH[3]}"
  else
    return 1
  fi

  local -a toks
  read -ra toks <<< "$rest"
  local n=${#toks[@]}
  local idx=0 t p matched_inline

  while [ "$idx" -lt "$n" ]; do
    t="${toks[$idx]}"
    if [ "$t" = "push" ]; then
      return 0
    fi
    case " $GIT_NOVAL_OPTS " in
      *" $t "*)
        idx=$((idx + 1))
        continue
        ;;
    esac
    matched_inline=0
    for p in $GIT_INLINEVAL_OPT_PREFIXES; do
      case "$t" in
        "$p"*)
          matched_inline=1
          break
          ;;
      esac
    done
    if [ "$matched_inline" = "1" ]; then
      idx=$((idx + 1))
      continue
    fi
    case " $GIT_SEPVAL_OPTS " in
      *" $t "*)
        idx=$((idx + 2))
        continue
        ;;
    esac
    case "$t" in
      -*)
        # 未知のオプション。確信を持てないため push の可能性ありとして扱う（P1-3）
        return 0
        ;;
      *)
        # ダッシュで始まらない最初の語 = 実際のサブコマンド。push 以外なら安全に false
        return 1
        ;;
    esac
  done

  # ここまでオプションらしき語だけで終わりサブコマンドが見えなかった。
  # 確信が持てないため push の可能性ありとして扱う。
  return 0
}

# rm + 再帰 + 強制 + 危険なトップレベルターゲット（/, ~, ., $HOME 等）がトークンとして存在
# $1: 原文（ターゲット判定用。"$HOME" のようにクォートされることがある）
# $2: クォート潰し版（起動・フラグ判定用）
is_dangerous_rm() {
  local c="$1" b="${2:-$1}"
  # /bin/rm のような絶対パス起動も拾えるよう前境界に / を含める
  [[ $b =~ (^|[[:space:]\;\&\|/])rm([[:space:]]|$) ]] || return 1
  { [[ $b =~ (^|[[:space:]])-[A-Za-z]*[rR][A-Za-z]* ]] || [[ $b =~ --recursive ]]; } || return 1
  { [[ $b =~ (^|[[:space:]])-[A-Za-z]*f[A-Za-z]* ]] || [[ $b =~ --force ]]; } || return 1
  local -a words
  read -ra words <<< "$c"
  local w
  for w in "${words[@]}"; do
    # 周囲のクォートを 1 層除去し ${HOME} を $HOME に正規化（"$HOME" / '${HOME}' を同一視）
    w="${w%\"}"; w="${w#\"}"
    w="${w%\'}"; w="${w#\'}"
    [ "$w" = '${HOME}' ] && w='$HOME'
    case "$w" in
      "/"|"/*"|"~"|"~/"|"~/*"|'$HOME'|'$HOME/'|'$HOME/*'|"."|"./"|"./*"|".."|"../"|"../*")
        printf '%s' "$w"
        return 0
        ;;
    esac
  done
  return 1
}

# mysql/mariadb/psql 経由で DB を破壊しうる SQL（DROP/TRUNCATE/ALTER..DROP/WHERE 無し DELETE）
# $1: 原文（SQL は -e "DROP TABLE x" のようにクォートされるので原文で見る）
# $2: クォート潰し版（DB クライアントの起動判定用）
is_db_destructive() {
  local c="$1" b="${2:-$1}"
  is_db_client "$b" || return 1
  local u
  u="$(printf '%s' "$c" | tr '[:lower:]' '[:upper:]')"
  if [[ $u =~ DROP[[:space:]]+(TABLE|DATABASE|SCHEMA) ]]; then
    printf '%s' "${BASH_REMATCH[0]}"
    return 0
  fi
  if [[ $u =~ TRUNCATE ]]; then
    printf '%s' "TRUNCATE"
    return 0
  fi
  if [[ $u =~ ALTER[[:space:]]+TABLE.*DROP ]]; then
    printf '%s' "ALTER TABLE ... DROP"
    return 0
  fi
  if [[ $u =~ DELETE[[:space:]]+FROM ]] && ! [[ $u =~ WHERE ]]; then
    printf '%s' "DELETE FROM (WHERE無し)"
    return 0
  fi
  return 1
}

# 保護ブランチへの push
# $1: 原文（ブランチ名は "main" のようにクォートされることがある）
# $2: クォート潰し版（git push の起動判定用）
is_push_protected() {
  local c="$1" b="${2:-$1}"
  is_git_push "$b" || return 1
  local br re re_qualified
  for br in $PROTECTED_BRANCHES; do
    # 前境界: 行頭/空白/refspec の :（HEAD:main）/+（force refspec の +main）/クォート。
    # 後境界: 空白/クォート/行末。/ は前境界に含めない（feature/main を誤検出しないため）。
    re="(^|[[:space:]:+'\"])${br}([[:space:]'\"]|\$)"
    if [[ $c =~ $re ]]; then
      printf '%s' "$br"
      return 0
    fi
    # 完全修飾 refspec（HEAD:refs/heads/main / +refs/heads/main / origin refs/heads/master）も拾う。
    # 直前の re は / を前境界に含めないため refs/heads/main を取りこぼす（バイパス防止）。
    re_qualified="(^|[[:space:]:+'\"])refs/heads/${br}([[:space:]'\"]|\$)"
    if [[ $c =~ $re_qualified ]]; then
      printf '%s' "refs/heads/${br}"
      return 0
    fi
  done
  return 1
}

# 強制 push（--force / -f）。--force-with-lease は安全なので許可
# $1: 原文（+refspec がクォートされることがある）
# $2: クォート潰し版（起動・フラグ判定用）
is_force_push() {
  local c="$1" b="${2:-$1}"
  is_git_push "$b" || return 1
  # --force-with-lease 単体は安全なので許可する。ただし「--force-with-lease が含まれる」
  # ことを理由に早期 return すると `git push --force-with-lease --force` のような同時指定を
  # 見逃すため、各フラグを個別に判定する（Codex レビュー指摘）。
  # --force-with-lease 自体は下の 2 つの正規表現のどちらにもマッチしない
  # （--force の直後が - / -f 側は先頭境界と末尾境界のどちらも満たさない）。
  if [[ $b =~ --force([[:space:]]|=|$) ]]; then
    printf '%s' "--force"
    return 0
  fi
  if [[ $b =~ (^|[[:space:]])-[A-Za-z]*f[A-Za-z]*([[:space:]]|$) ]]; then
    printf '%s' "${BASH_REMATCH[0]}"
    return 0
  fi
  # + で始まる refspec も強制 push（git push origin +main / +HEAD:main）
  if [[ $c =~ [[:space:]]\+[A-Za-z0-9._/:-]+ ]]; then
    printf '%s' "${BASH_REMATCH[0]}"
    return 0
  fi
  return 1
}

# シークレットファイルの Bash 経由の読み取り（cat/head/grep 等で .env や鍵ファイルを標準出力に出す）。
# permissions.deny(Read) は Read ツール専用で Bash には効かないため、代表的な「ファイル内容を出力する」
# コマンドが秘密ファイルを引数に取るケースだけを補完的に DENY する。
# ベストエフォート: printenv/env の環境変数ダンプ、grep -r の全走査、python/source/cp 経由の
# 間接読み取り等は誤検知が多すぎる／原理的に列挙不能なので捕捉しない（②⑤の明文化で補完）。
# $1: 原文（読み取り対象ファイル名の判定用。'.env' のようにクォートされることがある）
# $2: クォート潰し版（リーダー起動の判定用）
is_secret_read() {
  local c="$1" b="${2:-$1}"
  # リーダー系コマンドが「コマンド位置」で起動されているか判定する。
  # コマンド位置 = 行頭 / 区切り（; & | ( 改行）直後。任意でパス接頭辞（/bin/ 等）を許可。
  # 単なる空白境界にしないのは、コミットメッセージや PR コメントの引用文字列に紛れた
  # 'cat'/'head'/'less' 等の語が .env 風トークンと同居して誤 DENY するのを防ぐため
  # （例: git commit -m "add cat support for .env" を誤ブロックしない）。
  # sudo/env/xargs 等の接頭辞付き（sudo cat .env）や sh -c "cat .env" は捕捉しない
  # ＝ベストエフォートの範囲外（②⑤の明文化と人間レビューで補完）。
  local newline reader_re
  newline=$'\n'
  reader_re="(^|[;&|(${newline}])[[:space:]]*([^[:space:];&|]*/)?(cat|tac|less|more|head|tail|nl|xxd|od|hexdump|strings|base64|grep|egrep|fgrep)([[:space:]])"
  [[ $b =~ $reader_re ]] || return 1
  local -a words
  read -ra words <<< "$c"
  local w base
  for w in "${words[@]}"; do
    # 周囲のクォートを 1 層除去（cat ".env" / cat '.env' を .env と同一視）
    w="${w%\"}"; w="${w#\"}"
    w="${w%\'}"; w="${w#\'}"
    base="${w##*/}"
    # テンプレ（秘密値を含まない）は除外
    if is_template_base "$base"; then
      continue
    fi
    # シークレット相当のファイル名・拡張子
    case "$base" in
      .env|.env.*|*.pem|*.key|*.p12|*.pfx|auth.json|credentials.json|*.secret)
        printf '%s' "$w"
        return 0
        ;;
    esac
    # ホーム配下クレデンシャル（~/.ssh・$HOME/.aws・/Users/x/.config/gcloud 等をパスで判定）
    case "$w" in
      *"/.ssh/"*|*"/.aws/"*|*"/.config/gcloud/"*|*"/.config/gcp/"*)
        printf '%s' "$w"
        return 0
        ;;
    esac
  done
  return 1
}

# .env 系ファイルへの上書きリダイレクト（> / >>）または tee。.env.example 等の安全なものは除外
is_env_write() {
  local c="$1"
  local targets t base
  # `>|`（noclobber 無視の上書き）と `tee -- .env` / `tee -a -- .env` も同じ上書き手段なので拾う
  targets="$(printf '%s\n' "$c" \
    | grep -oE '(>>?\|?[[:space:]]*|(^|[[:space:]])tee[[:space:]]+((-a|--)[[:space:]]+)*)[^[:space:];|&<>]+' 2>/dev/null \
    | grep -oE '[^[:space:];|&<>=]+$' 2>/dev/null)"
  [ -z "$targets" ] && return 1
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    # 周囲のクォートを 1 層除去（> ".env" を .env と同一視）
    t="${t%\"}"; t="${t#\"}"
    t="${t%\'}"; t="${t#\'}"
    base="${t##*/}"
    # テンプレ（秘密値を含まない）は除外。除外リストは is_template_base に一元化
    if is_template_base "$base"; then
      continue
    fi
    case "$base" in
      .env|.env.*)
        printf '%s' "$t"
        return 0
        ;;
    esac
  done <<< "$targets"
  return 1
}

# ---- メイン ----
# stdin を builtin で読む（cat 非依存 → fail-open 経路もツール無し環境で動く）
IFS= read -r -d '' input || true

if [ "${GUARDRAIL_DISABLE:-}" = "1" ]; then
  exit 0
fi

if ! cmd="$(extract_command "$input")"; then
  echo "guardrail: jq/python3 が無いためコマンド解析をスキップしました（fail-open）。" >&2
  exit 0
fi

[ -z "$cmd" ] && exit 0

logical_cmd="$(strip_heredocs "$cmd" keep-db)"
# 前処理が何らかの理由で空を返した（TMPDIR 書き込み不可でヒアストリングが失敗した等）場合、
# 黙って全許可になるのを避けて原文で判定する（フェイルクローズ）。
if [ -z "${logical_cmd//[[:space:]]/}" ]; then
  logical_cmd="$cmd"
fi
split_into_segments "$logical_cmd"

# ===== DENY: 高確度の破壊的操作（完全ブロック）=====
# セグメント単位で判定する（R3）。各ルールは「どのセグメントの何にマッチしたか」を
# 該当箇所として提示する（R4）。DENY は ASK より優先するため、全セグメントを先に走査する。
for seg in "${SEGMENTS[@]}"; do
  bseg="$(blank_quoted "$seg")"
  match="$(is_dangerous_rm "$seg" "$bseg")" && deny "dangerous-rm" "ルート/ホーム/カレント等を対象にした再帰的・強制的な rm を検出しました。" "segment=[${seg}] target=${match}"
  match="$(is_db_destructive "$seg" "$bseg")" && deny "db-destructive" "DB を破壊しうる SQL（DROP / TRUNCATE / ALTER..DROP / WHERE 無し DELETE）を検出しました。" "segment=[${seg}] matched=${match}"
  match="$(is_push_protected "$seg" "$bseg")" && deny "protected-branch-push" "保護ブランチ（${PROTECTED_BRANCHES}）への push を検出しました。" "segment=[${seg}] branch=${match}"
  match="$(is_force_push "$seg" "$bseg")" && deny "force-push" "強制 push（--force / -f）を検出しました。共有ブランチでは --force-with-lease を使ってください。" "segment=[${seg}] matched=${match}"
  # --no-verify は独立したトークンとして現れた場合のみ。`--grep=--no-verify` のように
  # 他オプションの値として渡されただけのものを誤 DENY しない。
  if is_git_command "$bseg" && [[ $bseg =~ (^|[[:space:]])--no-verify([[:space:]]|$) ]]; then
    deny "no-verify" "--no-verify による検証スキップを検出しました。pre-commit/pre-push フックは迂回しないでください。" "segment=[${seg}]"
  fi
  match="$(is_env_write "$seg")" && deny "env-write" ".env 系ファイルへの上書きリダイレクトを検出しました（秘密情報の破壊を防止）。" "segment=[${seg}] target=${match}"
  match="$(is_secret_read "$seg" "$bseg")" && deny "secret-read" "シークレットファイル（.env / 鍵 / auth.json 等）を標準出力へ読み出す操作を検出しました（秘密情報の露出を防止）。" "segment=[${seg}] target=${match}"
done

# ===== ASK: 復元可能だが要注意（確認プロンプト）=====
# DENY 側と同じ git 呼び出し判定を使う。`git[[:space:]]+reset` のような素朴な連接では
# `git -C . reset --hard`（グローバルオプション挟み）を取りこぼし、逆に `echo git reset --hard`
# を誤って ASK にしてしまうため（Codex レビュー指摘）。
for seg in "${SEGMENTS[@]}"; do
  bseg="$(blank_quoted "$seg")"
  is_git_command "$bseg" || continue
  if [[ $bseg =~ (^|[[:space:]])reset([[:space:]].*)?[[:space:]]--hard([[:space:]]|$) ]]; then
    ask "git reset --hard は未コミットの変更を失う可能性があります。実行してよいか確認します。"
  fi
  if [[ $bseg =~ (^|[[:space:]])clean([[:space:]].*)?[[:space:]]-[A-Za-z]*f ]]; then
    ask "git clean -f は未追跡ファイルを削除します。実行してよいか確認します。"
  fi
  if [[ $bseg =~ (^|[[:space:]])checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$) ]]; then
    ask "git checkout . は作業ツリーの変更を破棄します。実行してよいか確認します。"
  fi
done

exit 0
