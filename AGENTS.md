# Repository Guidelines

## ADR（Architecture Decision Records）
- アーキテクチャ上の重要な意思決定を行った場合は `docs/adr/` 配下にADRとして記録すること。テンプレートは `docs/adr/templates/adr-template.md` を使用。
- 既存のADRに影響する変更を行う場合は、該当ADRのステータスを更新すること（deprecated / superseded）。
- コード変更時は `docs/adr/` 内のADRを参照し、関連する決定事項に準拠した実装を行うこと。
