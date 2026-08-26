# source_sidebar_flutter

A provider-neutral Flutter source workspace rebuilt from the interaction and
visual grammar of the v0 React prototype in this repository.

The package owns the global search header, left navigation and labels, dense
inbox rows, in-place reading, responsive behavior, keyboard focus, accessible
actions, and state presentation. It deliberately does not know about Readwise,
authentication, project routing, agents, or persistence. Applications supply
already-sanitized plain-text content and callbacks.

```dart
SourceSidebar(
  title: 'Technical sources',
  items: items,
  selectedId: selectedId,
  onSelected: selectSource,
  onOpenLibrary: openProviderLibrary,
  onIngest: ingestSource,
  onArchive: archiveSource,
  onDelete: deleteSource,
)
```

Hosts can map their semantic palette through `SourceSidebarStyle.colors` and
can add provider-neutral widgets to `topBarActions`. The package includes
inbox, unread, processed, archived, search, and tag filters without mutating
the supplied collection.

Consumers should pin an immutable Git commit:

```yaml
source_sidebar_flutter:
  git:
    url: https://github.com/commandglows/email-sidebar-app.git
    ref: <commit-sha>
    path: packages/source_sidebar_flutter
```

Never pass unsanitized HTML or remote-image markup into `content`. Provider
credentials and destructive-action authorization belong to the host.
