# Repository Guidelines

## ADR（Architecture Decision Records）
- アーキテクチャ上の重要な意思決定を行った場合は `docs/adr/` 配下にADRとして記録すること。テンプレートは `docs/adr/templates/adr-template.md` を使用。
- 既存のADRに影響する変更を行う場合は、該当ADRのステータスを更新すること（deprecated / superseded）。
- コード変更時は `docs/adr/` 内のADRを参照し、関連する決定事項に準拠した実装を行うこと。

<!-- ▼▼▼ beyonds-claude-guardrails: ここから AGENTS.md / CLAUDE.md に貼り付け ▼▼▼ -->

## ガードレール（全 AI エージェント共通の禁止事項）

以下は Claude Code / Devin / Codex / Copilot / Cursor すべてに適用する。`.claude/settings.json` の
`permissions.deny` と PreToolUse hook（`block-dangerous-bash.sh`）が一部を機械的に強制するが、
機械判定できない操作は本セクションで明文化する。

### 禁止（機械強制 + 明文）

- 機密値（環境変数 / トークン / API 鍵 / パスワード）を標準出力・ログ・コメント・PR・コミットメッセージに出力しない。
- `.env*`（テンプレ `.env.example(.*)` / `.env.sample(.*)` / `.env.dist` / `*.public.env` を除く）/ 証明書（`*.pem` `*.key` `*.p12` `*.pfx`）/ `auth.json` / `credentials.json` の変更・コミットをしない。
- `master` `dev` への直接 push、force push（`--force-with-lease` を除く）、`--no-verify` をしない。
- 破壊的 DB 操作（`DROP` / `TRUNCATE` / `WHERE` 無し `DELETE` / `ALTER ... DROP`）を人間の承認なしに実行しない。
- 本番環境への操作（`migrate --force` / デプロイ / `supervisorctl` / 本番 DB 接続での書込）を人間の承認なしに実行しない。

### 高リスク操作チェックリスト（本番・DB・破壊操作の前に必ず通す）

1. **宣言**: 何をするかを 1 文で明示する。
2. **影響範囲**: 対象（環境 / テーブル / ファイル）と巻き戻し可否を特定する。
3. **バックアップ**: DB ダンプ / git コミット等の復旧手段があるか確認する。
4. **検証**: staging / dev で先に試す。
5. **承認**: 人間の明示的な GO を得る。
6. **実行**: 上記が揃ってから実行し、結果を報告する。

<!-- ▲▲▲ beyonds-claude-guardrails: ここまで ▲▲▲ -->
