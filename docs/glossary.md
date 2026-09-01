---
title: vue-laravel-file-manager ユビキタス言語辞書
version: "1.0"
updated: 2026-08-07
owner: matsuzaki@beyonds.ai
status: draft
abstract: |
  vue-laravel-file-manager リポジトリ内で使う用語の正式表記と、コード上の識別子との対応を定めた辞書。
  対象は本リポジトリのみ（eportal-saas 等の呼び出し側には適用しない）。網羅辞書ではなく、表記がブレている語・コード名と日本語がズレている語だけを扱う。
  本リポジトリは OSS（alexusmai/vue-laravel-file-manager）のフォークであり、収録対象は beyondS が加えた差分と `src/lang/ja.js` に限る。
  収録 13 語。コードと日本語が一致していない既知の不整合 10 件。
  実装が正、本文書はその写像。矛盾を見つけたら §8 に追記する。
tags: [vue-laravel-file-manager, eportal-saas, ユビキタス言語, 用語集, 命名]
related: [docs/adr/README.md, AGENTS.md]
---

# vue-laravel-file-manager ユビキタス言語辞書

文責：AI（松崎）

## 1. この文書の位置づけ

本リポジトリの UI 文言・コードコメント・Issue で使う日本語表記を一つに寄せるための辞書。同じ物が「資料／ファイル」「フォルダ／ディレクトリ」のように複数の呼び名で書かれている状態を減らすことが目的で、用語の網羅は目的ではない。

### 1.1 前提：本リポジトリは OSS のフォーク

upstream は `alexusmai/vue-laravel-file-manager`（`git remote -v` で確認）。コード本体・UI 構造・多言語ファイル 17 言語分は upstream 由来で、beyondS が加えたのは upstream からの差分 40 ファイル（`git diff --stat upstream/master...HEAD` 実測）だけである。

したがって本辞書は **upstream 由来の一般的なファイルマネージャ用語を収録しない**。収録対象は次の 2 つに限る。

- beyondS が新規追加した `src/lang/ja.js`（196 行、全行が beyondS 追加）
- beyondS が改変した `src/` 配下のコンポーネント・ストア

### 1.2 スコープ

- **対象**: 本リポジトリ内の UI 文言・コード・コメント。
- **対象外**: 呼び出し側の eportal-saas。ディスク名（「全施設共通」「施設別」）やアカウント種別の定義はあちら側にあり、本リポジトリのコードには一切現れない（`src` 配下に「施設」の grep ヒットは 0 件）。
- **対象外**: 全社共通の会社名・サービス名の表記ルール（`beyonds-brand` / `beyonds-master-data` が正）。
- **対象外**: upstream にそのまま残っている英語文言・他言語の翻訳ファイル。

### 1.3 使い方

新しくコードを書くとき・文書を書くときは「正式表記」の列を使う。「使わない別名」に載っている語は書かない。実装が辞書と食い違っていたら**実装が正**で、辞書側を直す（§8 に不整合として記録する）。

## 2. エントリの読み方

各エントリは 4 項目だけを持つ。定義を長く書くと必ず腐るので、一行で足りない説明は該当コードへの参照に留める。

| 項目 | 意味 |
|------|------|
| 正式表記 | 文書・UI・コメントで使う日本語。これ以外を使わない |
| 使わない別名 | 実際に混在している表記。見つけたら正式表記に直す |
| コード上の識別子 | 変数名・API パス・翻訳キー。**リネーム対象ではない**（コードは英語のまま） |
| 定義 | 一行の定義。境界が曖昧な語は「〜ではない」を明示する |

## 3. 資料に関する用語

本リポジトリでもっとも表記がブレている領域。同一の物を、バックエンド API は `material`、UI 文言はほぼすべて「ファイル」、アップロードボタンだけが「資料」と呼んでいる。

| 正式表記 | 使わない別名 | コード上の識別子 | 定義 |
|----------|--------------|------------------|------|
| 資料 | ファイル、ドキュメント、マテリアル | `/api/materials/get-material-link`, `GET_MATERIAL_LINK_ENDPOINT`, `fetchMaterialLink()`, `material_not_found` | eportal-saas 上で施設に配布する文書。この画面が扱う対象そのもの。UI で「資料」と書いているのは `NavbarBlock.vue:31` の資料アップロードボタン 1 箇所だけ（§8-1） |
| ファイル | 資料 | `files`, `file.path`, `fileExist`, `lang.response.fileNotFound` | file-manager の内部データ構造としての 1 ファイル。ドメイン上は「資料」と同じ物を指しており、別概念ではない |
| フォルダ | ディレクトリ | `directories`, `dir`, `directoryExist`, `setSelectedDirectory` | 資料を格納する階層。`ja.js` が同じ物に「フォルダ」と「ディレクトリ」の両方を当てている（§8-2） |
| 説明 | ファイル説明、資料説明 | `file.description`, `lang.manager.table.description` | 資料 1 件に付く説明文。beyondS が追加した一覧列で upstream には無い。バックエンドが `description` を返す前提で、`TableView.vue:109` は未定義を考慮していない |

## 4. 名前に関する用語

`basename` と `filename` の違いが実装上の意味を持つ。名前変更で拡張子を変更不可にした改修（コミット `e841480`）以降、両者を混同すると壊れる。

| 正式表記 | 使わない別名 | コード上の識別子 | 定義 |
|----------|--------------|------------------|------|
| ファイル名 | 名前 | `filename`, `RenameModal.filename` | **拡張子を除いた**部分。名前変更で編集できるのはここだけで、拡張子は固定表示される（`RenameModal.vue:17-21`）。一覧の表示にもこれを使う（`TableView.vue:85`、未定義なら `basename` にフォールバック） |
| ファイル名（拡張子込み） | 名前、ベース名 | `basename`, `RenameModal.basename` | 拡張子を含む完全名。重複チェック（`fileExist`）・ダウンロード時の保存名（`contextMenuActions.js` の `setAttribute('download', ...)`）・ポップアップの見出しはこれを使う。`filename + '.' + extension` で組み立てる |

## 5. 権限・アカウントに関する用語

右クリックメニューの表示可否は、ほぼすべて「アクセス権限」と「管理者かどうか」の 2 つで決まる（`contextMenuRules.js`）。

| 正式表記 | 使わない別名 | コード上の識別子 | 定義 |
|----------|--------------|------------------|------|
| アクセス権限 | 権限、ACL、RW 権限 | `acl`, `file.acl`, `directory.acl`, `isEverySelectedItemRW` | 資料／フォルダ 1 件に対する読み書き可否。`0`=アクセス不可 / `1`=読み取り専用 / `2`=読み書き可能（`lang.modal.properties.access_0`〜`access_2`）。切り取り・名前変更・削除の可否はこの値が `2` かどうかで決まる |
| 管理者 | 編集者、エディタ、Editor | グローバル変数 `isEditor` | eportal-saas 側が画面に埋め込むアカウント種別フラグ。true のときフォルダの削除が許可される（`contextMenuRules.js:140-145`）。**`lang.modal.editor`（「エディタ」）や `editRule` / `canEdit` の editor はコードエディタを指す別概念で、この語とは無関係**（§8-4） |
| 施設アカウント | medical、医療機関アカウント | `contextMenuRules.js:141` のコメント `medical users` | `isEditor` が false のアカウント。フォルダを削除できない。アカウント定義そのものは eportal-saas 側にあり、本リポジトリは真偽値を受け取るだけ |

## 6. 表示・操作に関する用語

| 正式表記 | 使わない別名 | コード上の識別子 | 定義 |
|----------|--------------|------------------|------|
| プレビュー | 閲覧 | `PreviewModal`, `viewAction()`, `GET.preview()`, `preview` エンドポイント | 資料をモーダルで表示する操作。Word / PDF 変換（`sendFileToServer()`）とホバー時の画像表示も同じエンドポイントを使う。右クリックのラベルだけ「閲覧」になっている（§8-3） |
| URL | ファイルリンク、アクセスリンク | `copyUrlAction()`, `fetchMaterialLink()`, レスポンスの `link` | 資料 1 件を指す共有可能なリンク。DB 上の ID から生成されるためバックエンドに問い合わせる。**`file.path`（ディスク上のパス）とは別物**で、パスから組み立ててはいけない |
| 更新日時 | 修正日時 | `file.timestamp`, `timestampToDate()`, `lang.manager.table.date` | 資料の最終更新時刻。一覧の列見出しは「更新日時」、プロパティ画面は「修正日時」で、同じ `timestamp` を指す（§8-5） |
| ファイルサイズ | サイズ | `file.size`, `bytesToHuman()`, `lang.info.size` | 資料のバイトサイズ。`ja.js` が同じ値に「ファイルサイズ」と「サイズ」の両方を当てている（§8-6） |

## 7. 用語を追加・変更する手順

辞書が実装から遅れると誰も見なくなる。追加・変更は軽い手順で回す。

1. 追加は PR に含める。単独 PR にしない（実装と同じ PR で直す）。
2. UI 文言を足すときは `src/lang/ja.js` に必ずキーを作る。コンポーネントに日本語を直書きしない（§8-7 が既存の違反例）。
3. upstream 由来の語は収録しない。beyondS が触った箇所で表記がブレたときだけ足す。
4. 「使わない別名」に語を追加しても、既存の混在を一括で直そうとしない。触ったファイルだけ直す。

## 8. 既知の不整合（改修待ち）

2026-08-07 時点で実測した、コードと日本語・コードとコードの食い違い。**辞書はこれらを解消していない**。優先度と担当は未決。

| # | 箇所 | 内容 |
|---|------|------|
| 1 | `contextMenuActions.js:138-141` | API は `material_not_found` を返すのに、表示する文言は `lang.response.fileNotFound`（「ファイルが見つかりませんでした！」）。同じ物を API は material、UI は「ファイル」と呼ぶ。UI で「資料」と書くのは `NavbarBlock.vue:31` の 1 箇所のみ |
| 2 | `ja.js:89-91` / `ja.js:111` / `ja.js:177-179` | 同じ物が「フォルダ名」「新しいフォルダ生成」と「ディレクトリが既に存在します」「ディレクトリを生成しました！」に分かれている。`actions.js:113` のコメントも「ディスク最上位ディレクトリ」だが、同じ修正のコミット `91d210c` は「ディスク最上位パス」と書いており 3 通りある |
| 3 | `ja.js:47` / `ja.js:94` | 右クリックの `contextMenu.view` は「閲覧」だが、`viewAction()` が開くのは `PreviewModal` で見出しは「プレビュー」 |
| 4 | `NavbarBlock.vue:47` / `contextMenuRules.js:142` | `NavbarBlock` が `data()` に `isEditor: Number(isEditor)` を持つがテンプレートで未使用（デッドコード）。実際に判定する `contextMenuRules.js:142` は `this.isEditor` ではなく**素のグローバル変数**を参照しており、宣言は本リポジトリに無く eportal-saas 側の埋め込みに依存する。値が渡らなければ `ReferenceError` になる |
| 5 | `ja.js:64` / `ja.js:98` | 「更新日時」と「修正日時」が同じ `timestamp` を指す。ただしプロパティ画面は `propertiesRule()` が `return false` 固定（`contextMenuRules.js:152-154`）で到達不能なため、実害は出ていない |
| 6 | `ja.js:59-60` | `info.size` と `info.selectedSize` がどちらも「ファイルサイズ:」で**同値重複**しており、「合計」と「選択分」を画面上で区別できない。一方 `ja.js:68` / `101` / `126` は「サイズ」 |
| 7 | `contextMenuActions.js:148,155` | 「URLコピーに失敗しました！」が `ja.js` を経由せず直書き。他の通知はすべて `lang.*` 経由で、この 2 箇所だけ多言語化から漏れている |
| 8 | `ja.js:48` / `ja.js:140` | 同じ操作が `contextMenu.zip`「圧縮」と `modal.zip.title`「アーカイブ生成」に分かれている。ただし `zipRule()` / `unzipRule()` が `return false` 固定（`contextMenuRules.js:116,125`）で到達不能なため、辞書には収録していない |
| 9 | `TableView.vue:86,259` | `isFileNew()`（更新から 14 日以内）の表示ラベルが英字 "NEW" 固定で、日本語の正式表記が決まっていない。日数 `14` もマジックナンバーで設定化されていない |
| 10 | ディスク名 | 「全施設共通」「施設別」（コミット `d7c5d29`）は eportal-saas の disk 設定から来る値で、本リポジトリのコードには現れない。`src` 配下の「施設」grep ヒットは 0 件。本辞書の対象外だが、Issue で頻出するため所在だけ記録する |
