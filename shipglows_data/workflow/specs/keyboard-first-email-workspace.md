---
artifact: implementation_spec
metadata_schema_version: "1.0"
artifact_version: "1.1.1"
project: email-sidebar-app
created_at: "2026-09-02T21:39:00Z"
updated_at: "2026-09-03T00:00:00Z"
status: verified
source_skill: 100-sg-spec
source_model: gpt-5
scope: keyboard-first-email-workspace
owner: Diane
confidence: high
risk_level: medium
security_impact: no
docs_impact: yes
linked_systems:
  - packages/source_sidebar_flutter
  - demo
depends_on: []
supersedes: []
next_review: "2026-10-02"
next_step: establish the canonical code-to-documentation map before closure
---

# Title

Keyboard-first email workspace

## Status

Implemented and verified in the provider-neutral package and synthetic demo; closure awaits the repository's canonical code-to-documentation map.

## User Story

As an operator processing email-derived sources, I can navigate accounts, messages, long-form content, and every processing action with the keyboard so that I never need to reach for the mouse or recover from a focus trap.

## Minimal Behavior Contract

When the workspace has focus, documented shortcuts move between messages, open and close the reader, scroll the reader, switch accounts, request a summary, and distribute the current message to one or more projects. Available actions expose immediate visible state; unavailable or failed host actions remain recoverable and restore focus. Commands must not intercept editable text, and the keyboard help must list only actions that the host actually supports. A missed edge case is returning from a dialog or a changed account to a message that no longer exists; focus must land on the nearest valid workspace target.

## Success Behavior

The operator can complete the list-to-read-to-process loop using only keys. Focus remains visible, the selected message and account remain coherent, long content can be traversed by line/page/boundary commands, multi-project selection supports at least two destinations, and successful summary or distribution actions provide visible feedback. Widget tests prove every command, focus restoration, input protection, and context-sensitive help.

## Error Behavior

Unavailable callbacks omit their shortcuts from help and do nothing when invoked. Host callback failures keep the message selected, restore a valid focus target, clear busy state, and expose a host-renderable error instead of trapping input. Empty accounts, removed messages, cancelled dialogs, duplicate project selections, and stale selections all return to a stable navigable state.

## Problem

The package already supports message navigation, open/back, search, archive, confirmed delete, single-destination move, Later, zoom, and keyboard help. It does not provide complete reader scrolling, account switching, on-demand summary, multi-project distribution, or a keyboard shortcut for the existing project-ingest action. The demo also proves only synthetic single-project ingestion.

## Solution

Extend the provider-neutral package with typed host-owned accounts, project destinations, summary and multi-project callbacks; add collision-free configurable shortcuts and accessible keyboard-operated choosers; own reader scrolling and focus restoration inside the package; update the synthetic demo and public keyboard contract; and add focused regression tests.

## Scope In

- Previous/next message in list and reader.
- Open, close, search, native focus traversal, and visible focus restoration.
- Reader line/page scrolling plus start/end navigation.
- Previous/next account and an account chooser when accounts are supplied.
- Summary request for the active message.
- Single or multiple project selection and submission in one operation.
- Existing archive, confirmed delete, move, Later, zoom, and contextual help.
- Synthetic demo behavior, package README, changelog, and widget tests.

## Scope Out

- Real email-provider authentication, synchronization, or account discovery.
- Real AI summarization, persistence, authorization, or project APIs.
- Release builds, deployment, or production claims.
- Redesign of the established visual language.

## Constraints

- Keep the package provider-neutral and host-callback driven.
- Preserve current public constructors where possible; additions must be optional and backward compatible.
- Do not fire alphabetic commands while an editable text control owns focus.
- Use maintained Flutter primitives for dialogs, focus, scrolling, semantics, and keyboard actions.
- Visual values remain governed by ThemeData and SourceSidebarStyle; no screen-local design literals.
- Preserve unrelated ENVIRONMENT.md changes.

## Test Contract

Surface: Flutter widget package and synthetic demo. Automated proof covers shortcuts, focus, reader scrolling, account switching, summary, multi-project selection, cancellation, missing callbacks, editable-text protection, and help visibility. Run package and demo Flutter test suites, formatting/analyzer checks, and the design-system drift scan. No provider, auth, deployment, or manual production proof is claimed.

## Dependencies

- Flutter SDK and existing package dependencies only.
- Host callbacks for accounts, summary, projects, and side effects.
- Existing SourceSidebar focus, action, dialog, and style patterns.

## Invariants

- Destructive deletion always requires confirmation.
- Host-owned operations cannot run concurrently for the same workspace.
- Account/project identifiers remain opaque provider-neutral strings.
- Project selection is de-duplicated and never submitted empty.
- Keyboard help reflects runtime capability, not theoretical bindings.
- Existing shortcut customization and disabling remain supported.

## Links & Consequences

The public package API, demo integration, README, changelog, and widget tests change together. Consumers remain source-compatible because new inputs are optional. Any change to shortcut ordering revalidates collision behavior and editable-text protection.

First-party guidance retained for implementation: Flutter's Focus and Shortcuts/Actions documentation establishes the framework-native focus and command architecture; W3C APG keyboard-interface guidance establishes visible, predictable focus, separation of focus from multi-selection, Tab traversal between components, and focus containment/restoration for modal dialogs. These principles are adapted to Flutter rather than copied as web implementation details.

## Documentation Coherence

Update the package README keyboard contract, API example, and changelog. Update demo behavior through code and tests; no public provider claim is added.

## Edge Cases

- Empty or one-message account.
- Switching to an account with no selected message.
- Selected message removed during/after an async action.
- Reader content shorter than the viewport or missing a scroll extent.
- Cancelled account/project dialogs.
- One project, two projects, duplicate toggles, and no final selection.
- Summary/distribution callback absent, busy, or failing.
- Shortcut collision introduced by host customization.
- Focus inside search or another editable descendant.
- Narrow/mobile layout and dialog focus restoration.

## Implementation Tasks

1. Add provider-neutral account and project destination models/callback typedefs and export them; validate with analyzer and model tests.
2. Extend SourceSidebarShortcuts with reader scrolling, account, summary, and project-distribution bindings; validate collision order and formatting in help tests.
3. Add reader scroll ownership, guarded intents/actions, account chooser/switching, summary execution, and multi-select project dialog; validate focus and error recovery with widget tests.
4. Wire synthetic multi-account, summary, and multi-project behavior in the demo; validate the end-to-end keyboard scenarios with demo tests.
5. Update README and changelog; run formatter, analyzer, package/demo tests, and design-system drift validation.

## Acceptance Criteria

- Every in-scope operation is reachable without pointer input and appears in `?` help only when available.
- J/K or arrows change messages in both list and reader; O/Enter opens and U/Escape returns.
- Reader scrolling supports line, page, start, and end without moving message selection.
- Account shortcuts switch deterministically and an account chooser is fully keyboard operable.
- Summary invokes exactly once for the active message and restores focus after success/failure.
- Project distribution accepts one or multiple unique projects, including two in one submission.
- Existing archive/delete/move/Later behavior remains green.
- Editable fields suppress application alphabetic shortcuts.
- Package and demo test suites pass with no unrelated files staged.

## Test Strategy

Use deterministic Flutter widget tests with synthetic callbacks and scrollable long content. Assert callback payloads, dialog state, focus owner, scroll offsets, contextual help rows, and safe cancellation. Re-run the complete package and demo suites to catch regressions.

## Risks

- Shortcut collisions: explicit binding order and targeted collision tests.
- Focus traps in dialogs/readers: native Flutter dialog primitives and restoration tests.
- API growth: optional typed inputs and backward-compatible defaults.
- Ambiguous action semantics: names distinguish move/location from distribute/projects.
- Async failure visibility: callback errors remain host-owned but package busy/focus state must recover reliably.

## OWASP Security Gate

Not applicable to this package change because it introduces no network boundary, authentication, authorization, tenant state, secrets, remote parsing, or provider persistence. Host applications retain responsibility for authorization and validation of summary and project callbacks. The package continues to accept sanitized plain text only, keeps opaque identifiers, and never treats client controls as a security boundary.

## ZOMBIES Coverage

- Zero/empty: empty accounts, empty messages, empty project selection.
- One: single account/project/message paths remain usable.
- Many: multiple accounts/projects/messages and long content.
- Boundaries: first/last message, first/last account, reader top/bottom.
- Interface: host callbacks missing or failing.
- Exceptions: cancelled dialogs and async errors clear pending state.
- Security/abuse: identifiers are opaque, deletion stays confirmed, no credentials or remote content are handled.

## Execution Notes

First read `packages/source_sidebar_flutter/lib/src/source_sidebar.dart`, `packages/source_sidebar_flutter/lib/src/source_sidebar_shortcuts.dart`, `packages/source_sidebar_flutter/test/source_sidebar_test.dart`, `demo/lib/main.dart`, and `packages/source_sidebar_flutter/README.md`. Use the existing SourceSidebar architecture and Flutter Shortcuts/Actions system. Keep one integration owner because core widget, demo, tests, and documentation share public API dependencies. Run `dart format` on owned Dart files, `flutter analyze`, package and demo `flutter test`, and the ShipGlows design-system drift scan. Stop for a breaking API requirement, new dependency, provider side effect, security/data boundary, or unrelated dirty-file collision. No parallel writes are planned. Do not touch pre-existing ENVIRONMENT.md changes.

## Open Questions

None. Default bindings may remain host-customizable; the package contract, not a fixed physical keyboard layout, is authoritative.

## Skill Run History

| Date UTC | Skill | Model | Action | Result | Next step |
|----------|-------|-------|--------|--------|-----------|
| 2026-09-02 | 100-sg-spec | gpt-5 | Created implementation contract from approved product plan | reviewed | readiness review |
| 2026-09-02 | 101-sg-ready | gpt-5 | Reviewed behavior, risks, proof, design authority, and external keyboard guidance | ready | implementation |
| 2026-09-03 | 102-sg-start | gpt-5 | Implemented keyboard reading, accounts, summaries, and multi-project distribution | implemented | verification |
| 2026-09-03 | 103-sg-verify | gpt-5 | Ran analyzers, package/demo widget suites, and design-system drift scan | passed | closure |
| 2026-09-03 | 104-sg-end | gpt-5 | Reconciled documentation, scope, and owned delivery paths | partial: canonical code-docs map absent | documentation governance |

## Current Chantier Flow

- Specification: reviewed
- Readiness: ready
- Implementation: complete
- Verification: passed
- Closure: pending canonical code-docs mapping
- Ship: implementation pushed to main
