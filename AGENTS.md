# Repository Guidelines

**日本語の用語（資料 / ファイル、フォルダ / ディレクトリ 等）を書く前に [`docs/glossary.md`](docs/glossary.md)（ユビキタス言語辞書）を読むこと。** 正式表記・使ってはいけない別名・対応するコード上の識別子を定義している。辞書と実装が食い違っていたら実装が正で、辞書側を直す（§8）。

## ADR（Architecture Decision Records）
- アーキテクチャ上の重要な意思決定を行った場合は `docs/adr/` 配下にADRとして記録すること。テンプレートは `docs/adr/templates/adr-template.md` を使用。
- 既存のADRに影響する変更を行う場合は、該当ADRのステータスを更新すること（deprecated / superseded）。
- コード変更時は `docs/adr/` 内のADRを参照し、関連する決定事項に準拠した実装を行うこと。
