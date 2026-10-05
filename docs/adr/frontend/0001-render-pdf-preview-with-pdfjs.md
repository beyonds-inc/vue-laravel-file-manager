---
# === 機械可読メタデータ（YAML frontmatter） ===
title: "PDF プレビューをブラウザの PDF ビューアーではなく pdf.js で描く"
description: "PDF プレビューで、ブラウザごとの表示の違いと、閲覧者でも保存できてしまう問題をなくすため、pdf.js で canvas に描く"
type: adr
adr_number: "0001"
category: frontend
tags:
  - pdf-preview
  - pdfjs
  - download-restriction
status: proposed
created: 2026-10-03
updated: 2026-10-03
author: "中井"
superseded_by: ""
related:
  - ""
impact:
  - area: "src/components/modals/views/PdfPreviewModal.vue"
    description: "PDF を iframe ではなく pdf.js で canvas に描く"
  - area: "vite.config.js"
    description: "pdf.js が Node.js のときだけ使う import.meta.url を置き換える"
  - area: "package.json"
    description: "pdfjs-dist を追加（版は固定）"
---

# ADR-0001: PDF プレビューをブラウザの PDF ビューアーではなく pdf.js で描く

## ステータス

proposed（2026-10-03）

## コンテキストと課題

PDF プレビュー（eportal-saas #797。Word・Excel を変換した PDF も #824 で同じモーダルに出す）は、PDF の blob URL を iframe で開き、ブラウザの PDF ビューアーに表示させていた。テストで次の 2 点が見つかった（eportal-saas #824 のコメント、2026-10-02）。

- Chrome だけ、モーダルの中で PDF が小さく表示され、読みにくい
- Firefox・Edge の PDF ビューアーには保存（ダウンロード）ボタンがあり、ダウンロードの権限が無い閲覧者（CRA）でもダウンロードできてしまう（EPS 様 QA No.38「閲覧可・ダウンロード不可」に反する）

## 決定要因（Decision Drivers）

- 閲覧者の画面に、PDF を保存する手段を出さない
- Chrome・Edge・Firefox で同じ大きさ・同じ操作で表示する
- ePortal への配置は、ビルドした file-manager.js / css を置く今の手順から大きく変えない
- フォントを埋め込んでいない日本語の PDF も表示できる

## 検討した選択肢

### 選択肢1: iframe のまま、URL に `#toolbar=0` を付ける

- 良い点: 変更が小さい
- 悪い点: Firefox は `#toolbar=0` に従わず、保存ボタンが残る
- 悪い点: Chrome・Edge でもキーボード（Ctrl+S）や右クリックで保存できる。Chrome で小さく表示される問題も残る

### 選択肢2: サーバーで PDF をページごとの画像にして返す

- 良い点: ブラウザに PDF そのものを渡さない
- 悪い点: サーバーに変換の処理と負荷が増える。文字の拡大がきれいにならない

### 選択肢3: pdf.js（pdfjs-dist）で canvas に描く

- 良い点: ブラウザの PDF ビューアーを使わないので、保存・印刷のボタンが出ない。どのブラウザでも同じ表示になる
- 良い点: 拡大・縮小・幅に合わせる、を自前で用意できる
- 悪い点: file-manager.js が約 0.4MB 増える。pdf.js の版を上げるときに ePortal 側の配置も要る

## 決定内容

*選択肢3（pdf.js で canvas に描く）を採用する。*

閲覧者に保存の手段を出さないことが要件で、ブラウザの PDF ビューアーを使う限りこれは満たせないため。

### 実装ガイドライン

- `pdfjs-dist` は版を固定する（package.json の他の依存と同じ）。古いブラウザでも動くよう `legacy` のビルドを使う
- pdf.js の worker と文字のデータ（CMap・標準フォント）は file-manager.js に含めず、ePortal の `laravel/public/vendor/file-manager/pdfjs/<版>/` に置く。資料一覧を開くたびに読み込む量を増やさないため。worker は pdf.js 本体と版がそろっていないと動かないので、版ごとのフォルダにする。場所は ePortal の blade が `fmPdfjsAssetsUrl` で渡す
- 4.1.392 以下は任意のコードを実行できる脆弱性（CVE-2024-4367、4.2.67 で修正）があるため、4.2.67 以上を使う。あわせて `isEvalSupported: false` を指定する
- ePortal は file-manager.js を module ではない `<script>` で読み込むため、bundle に `import.meta` を残さない（pdf.js が Node.js のときだけ使う `import.meta.url` を `vite.config.js` の `define` で置き換える）
- canvas の右クリックメニューは出さない（画像として保存させない）
- ページは見えるところだけ描く（大きな PDF でも重くならないように）

## 結果（Consequences）

### ポジティブ

- 閲覧者の画面に PDF の保存・印刷のボタンが出なくなる
- Chrome・Edge・Firefox で同じ大きさで表示される

### ネガティブ

- file-manager.js が約 0.9MB から約 1.3MB になる
- pdf.js の版を変えるときは、ePortal に worker・CMap・標準フォントの配置が要る（ePortal の README「資料一覧画面のフロントエンド更新手順」）
- PDF のデータはブラウザに渡るため、開発者ツールなどを使えば取り出せる（画面に保存の手段を出さないことが目的で、取り出しを技術的に完全に防ぐものではない）

## 関連ADR

- なし

## 参考リンク

- https://github.com/mozilla/pdf.js
- https://github.com/advisories/GHSA-wgrm-67xf-hhpq（CVE-2024-4367）
