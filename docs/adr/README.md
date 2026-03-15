# Architecture Decision Records (ADR)

本プロジェクトのアーキテクチャ意思決定記録です。

## ADRとは

ADR（Architecture Decision Record）は、アーキテクチャ上の重要な意思決定とその背景・理由を記録する文書です。
本プロジェクトでは [MADR](https://adr.github.io/madr/) をベースに、YAML frontmatterによる機械可読メタデータを組み合わせた形式を採用しています。

## ディレクトリ構成

```
docs/adr/
├── README.md              # 本ファイル（ADR一覧・運用ガイド）
├── templates/
│   └── adr-template.md    # ADRテンプレート
├── frontend/              # フロントエンド（Vue.js）に関する決定
├── infrastructure/        # ビルド・開発環境に関する決定
└── process/               # 開発プロセス・運用に関する決定
```

## ADR一覧

### Frontend

（今後追加予定）

### Infrastructure

（今後追加予定）

### Process

（今後追加予定）

## 運用ルール

### ADRを作成するタイミング

以下のような意思決定を行った場合にADRを作成します：

- 技術スタックの選定・変更（フレームワーク、ライブラリ、ツール）
- アーキテクチャパターンの採用（コンポーネント設計、状態管理方式など）
- 機能の実装方式の決定（特に複数の選択肢がある場合）
- 開発プロセスやルールの策定・変更
- 将来の方針に影響する技術的判断の保留・延期

### ADRのライフサイクル

1. **proposed（提案中）**: PRで提出し、チームレビューを受ける
2. **accepted（承認済）**: レビュー承認後、マージ時にステータスを変更
3. **deprecated（非推奨）**: 決定が古くなり、推奨されなくなった場合
4. **superseded（置換済）**: 新しいADRに置き換えられた場合（`superseded_by` に後継ADRを記載）

### ADRの作成手順

1. `docs/adr/templates/adr-template.md` をコピー
2. 該当するカテゴリディレクトリに `NNNN-title-with-dashes.md` として配置
3. YAML frontmatter とすべてのセクションを記入
4. PRとして提出し、レビューを受ける
5. 本ファイル（README.md）のADR一覧にエントリを追加

### 命名規則

- ファイル名: `NNNN-title-with-dashes.md`（例: `0001-use-vue3-composition-api.md`）
- 番号はカテゴリごとに連番（0001から開始）
- タイトルは英語のケバブケースで簡潔に

### YAML frontmatter について

各ADRにはYAML frontmatterを含めます。これにより：

- AIエージェント（Devin等）がメタデータを高速にパースしてフィルタリング可能
- `tags` や `category` による横断検索が可能
- `impact` フィールドにより、コード変更時に関連ADRを特定可能
- `related` や `superseded_by` によりADR間の関係を追跡可能

詳細はテンプレートを参照してください。
