# newsletter_studio_flutter

A provider-neutral, keyboard-first Flutter workspace for turning selected
sources into a reviewable newsletter draft. The package owns composition,
source provenance, preview states, delivery review, adaptive layouts, and the
interaction contract. The host owns storage, authorization, audience consent,
HTML rendering, provider adapters, delivery, and analytics.

The component never stores provider credentials, downloads remote email HTML,
or sends a message by itself. Every external effect crosses a typed callback.

```dart
NewsletterStudio(
  draft: draft,
  availableSources: sources,
  audience: audienceSummary,
  sender: senderSummary,
  design: designSummary,
  capabilities: const NewsletterStudioCapabilities(
    canTest: true,
    canSchedule: true,
    canSend: true,
  ),
  onDraftChanged: updateLocalDraft,
  onSaveDraft: saveDraft,
  onResolveAudience: resolveEligibleAudience,
  onValidateDraft: validateOnServer,
  onRenderPreview: renderProviderNeutralPreview,
  onSendTest: requestTestDelivery,
  onSchedule: requestSchedule,
  onSend: requestImmediateDelivery,
  onLoadDeliveryStatus: loadDeliveryStatus,
  onLoadAnalytics: loadAggregateAnalytics,
)
```

Consumers should pin an immutable Git commit:

```yaml
newsletter_studio_flutter:
  git:
    url: https://github.com/commandglows/email-sidebar-app.git
    ref: <commit-sha>
    path: packages/newsletter_studio_flutter
```

## Host boundary

The supplied `NewsletterDraft` is controlled host state. The package keeps an
optimistic working copy, reports every edit through `onDraftChanged`, and can
debounce `onSaveDraft`. Revision-aware test receipts become stale as soon as
the draft changes. Local checks are merged with authoritative host validation
before the review drawer opens.

`onSchedule` and `onSend` are reachable only after review and a second explicit
confirmation. Keyboard commands can open review but never trigger either
delivery callback directly. The host must repeat authorization, consent,
sender, suppression, idempotency, and revision checks server-side.

Remote source content must be sanitized before it enters the models. Keep
recipient identities, credentials, unsubscribe records, raw tracking data, and
provider payloads out of this public presentation package.

## Keyboard contract

- `J` / `K` or arrow keys: navigate sources and reclaim row focus.
- `X`: attach or detach the selected source.
- Enter: open the selected source through the host callback.
- F6 / Shift+F6: move among source, editor, inspector, and action zones.
- Ctrl/Command+P: toggle preview.
- Ctrl/Command+Shift+T: request a test delivery.
- Ctrl/Command+Enter: open delivery review.
- Ctrl/Command+0: reset workspace zoom.
- Escape: close the current transient surface.
- `?`: show keyboard help.

Alphabetic commands are ignored while an editable control owns focus. Every
binding is replaceable or disableable through `NewsletterStudioShortcuts`.

## Styling and responsive behavior

Hosts map semantic colors and layout tokens through `NewsletterStudioStyle`.
The default experience uses three panes at expanded widths, source and
inspector rails at medium widths, and a bottom navigation on compact screens.
Ctrl/Command+mouse wheel scales the whole workspace while Flutter text scaling
continues to operate independently.

The in-app preview is intentionally marked approximate. Received-client HTML,
dark-mode behavior, remote-image policy, unsubscribe behavior, and
deliverability require separate backend and inbox proof.
