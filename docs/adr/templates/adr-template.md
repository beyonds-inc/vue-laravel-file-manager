---
# === 機械可読メタデータ（YAML frontmatter） ===
title: "{短いタイトル: 解決した課題と採用した方式を表すもの}"
description: "{1文での要約}"
type: adr
adr_number: "NNNN"
category: ""                 # frontend | infrastructure | process
tags:
  - ""                       # 関連する技術・機能タグ
status: proposed             # proposed | accepted | deprecated | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: ""                   # 起案者（チーム名 or 個人名）
superseded_by: ""            # 置換先ADR（例: frontend/0005）。空なら未置換
related:                     # 関連ADR（例: frontend/0001）
  - ""
impact:                      # コード変更時にDevinが関連ADRを特定するためのフィールド
  - area: ""                 # 影響するディレクトリ or ファイルパス
    description: ""          # 影響の概要
---

# ADR-{NNNN}: {短いタイトル}

## ステータス

{status}（{日付}）

## コンテキストと課題

{このADRが対処する問題の背景を2〜3文で説明する。}
{課題を疑問文で表現してもよい。関連するIssueやドキュメントへのリンクを含める。}

## 決定要因（Decision Drivers）

- {決定要因1: 例えば技術的制約、ビジネス要件、品質要件など}
- {決定要因2}
- ...

## 検討した選択肢

### 選択肢1: {タイトル}

{選択肢の概要を1〜2文で説明}

- 良い点: {メリット1}
- 良い点: {メリット2}
- 悪い点: {デメリット1}

### 選択肢2: {タイトル}

{選択肢の概要を1〜2文で説明}

- 良い点: {メリット1}
- 悪い点: {デメリット1}
- 悪い点: {デメリット2}

### 選択肢3: {タイトル}

（必要に応じて追加）

## 決定内容

*{採用した選択肢}を採用する。*

{選択の理由を簡潔に説明する。}

### 実装ガイドライン

{実装時に守るべき具体的な方針やルールがあれば記載する。}

## 結果（Consequences）

### ポジティブ

- {良い結果1}
- {良い結果2}

### ネガティブ

- {悪い結果・トレードオフ1}
- {悪い結果・トレードオフ2}

## 関連ADR

- {関連するADRへのリンク（例: [ADR frontend/0001: Vue 3 Composition API の採用](../frontend/0001-use-vue3-composition-api.md)）}

## 参考リンク

- {外部ドキュメント、RFC、ライブラリのURLなど}
