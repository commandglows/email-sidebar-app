# source_sidebar_flutter

A provider-neutral Flutter source inbox extracted from the interaction model of
the v0 React prototype in this repository.

The package owns list/detail interaction, responsive behavior, keyboard focus,
accessible actions, and state presentation. It deliberately does not know about
Readwise, authentication, project routing, agents, or persistence. Applications
supply already-sanitized plain-text content and callbacks.

```dart
SourceSidebar(
  title: 'Technical sources',
  items: items,
  selectedId: selectedId,
  onSelected: selectSource,
  onIngest: ingestSource,
  onArchive: archiveSource,
  onDelete: deleteSource,
)
```

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
