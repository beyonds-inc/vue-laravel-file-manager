# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ADR（Architecture Decision Records）

アーキテクチャ上の重要な意思決定を行った場合は、`docs/adr/` 配下にADRとして記録してください。

- テンプレート: `docs/adr/templates/adr-template.md`
- 運用ルール: `docs/adr/README.md`
- 技術スタックの選定・変更、アーキテクチャパターンの採用、機能の実装方式の決定など、将来に影響する意思決定はADRとして文書化すること
- 既存のADRに影響する変更を行う場合は、該当ADRのステータスを更新すること（deprecated / superseded）
- コード変更時は `docs/adr/` 内のADRを参照し、関連する決定事項に準拠した実装を行うこと
