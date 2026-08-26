---
artifact: design_system_authority
metadata_schema_version: "1.0"
artifact_version: "1.0.0"
project: source-sidebar-flutter
created: "2026-08-26"
updated: "2026-08-26"
status: active
source_skill: 102-sg-start
scope: source-sidebar-flutter-preview
owner: Diane
confidence: high
risk_level: low
security_impact: none
docs_impact: yes
linked_systems:
  - packages/source_sidebar_flutter/lib/src/source_sidebar_style.dart
  - demo/lib/preview_theme.dart
depends_on: []
supersedes: []
evidence:
  - "The package owns provider-neutral layout tokens through SourceSidebarStyle and consumes host ThemeData semantic roles."
  - "The preview owns only its host-level ThemeData through PreviewTheme."
next_review: "2027-02-26"
next_step: none
---

# Source Sidebar Design-System Authority

The reusable package consumes Flutter `ThemeData` and exposes only its semantic
layout adapter through `SourceSidebarStyle`. Host applications own their brand
tokens and map them through `ThemeData`; the package must not introduce a brand.

The public preview's sole host-theme authority is `PreviewTheme`. Demo screens
must not add local color, typography, spacing, radius, elevation, breakpoint, or
motion values. Platform-required Web manifest colors mirror its named seed.
