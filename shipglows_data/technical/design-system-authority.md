---
artifact: design_system_authority
metadata_schema_version: "1.0"
artifact_version: "1.1.0"
project: source-sidebar-flutter
created: "2026-08-26"
updated: "2026-08-26"
status: active
source_skill: 006-sg-design
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
  - "The package owns provider-neutral layout and semantic color adapters through SourceSidebarStyle and SourceSidebarColors."
  - "The preview owns its explicit light and dark semantic palettes through PreviewTheme."
  - "Inspected Flutter captures exist for list and reader states at 1440x900 and 390x844 under shipglows_data/visual-proof."
next_review: "2027-02-26"
next_step: none
---

# Source Sidebar Design-System Authority

The reusable package consumes Flutter `ThemeData` and exposes semantic layout
and color adapters through `SourceSidebarStyle` and `SourceSidebarColors`. Host
applications own their brand tokens and may map them explicitly; the package
must not introduce a product brand or provider assumption.

The public preview's sole host-theme authority is `PreviewTheme`. It carries the
light and dark palettes derived from the v0 reference: white surfaces, a
blue-gray canvas and search field, pale-blue selection, restrained blue focus,
and compact neutral typography. Demo screens must not add local colors.

`SourceSidebarStyle` remains the sole package authority for breakpoints,
navigation width, global-header height, content padding, radii, row density,
and action sizing. The inspected captures in `shipglows_data/visual-proof`
define the durable visual baseline for this implementation.
