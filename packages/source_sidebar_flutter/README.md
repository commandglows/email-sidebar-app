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
  moveDestinations: const [
    SourceMoveDestination(id: 'later', label: 'Later'),
    SourceMoveDestination(id: 'reference', label: 'Reference'),
  ],
  laterDestinationId: 'later',
  onMove: moveSource,
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

## Keyboard contract

The default Glows bindings are `J/K` and the arrow keys to navigate, `O` or
Enter to open, `/` or Ctrl/Command+F to search, `U` or Escape to return,
`E` to archive, `W` to delete with confirmation, `V` to choose a move
destination, `L` to move directly to the configured Later destination, and
`?` to show keyboard help. Tab, Shift+Tab, Enter, and Space continue to use
Flutter's native focus traversal and button activation.

Alphabetic commands are ignored whenever any editable text control owns focus.
The active row uses `SourceSidebarColors.focus`, regains focus after dialogs and
actions, and is scrolled into view during keyboard navigation.

When `laterDestinationId` is configured, Later appears as a counted navigation
state and those items leave Inbox while remaining recoverable there. Without
that configuration, Inbox keeps its previous behavior; other host-defined move
locations remain in Inbox.

Every command accepts a typed list of `ShortcutActivator`s. Replace a list to
customize it or pass an empty list to disable the command without forking:

```dart
shortcuts: const SourceSidebarShortcuts(
  delete: [SingleActivator(LogicalKeyboardKey.keyD)],
  archive: [],
),
```

If two customized bindings collide, the later command in the documented
constructor order wins. Move destinations are host-owned identifiers and
labels; the package does not translate them into provider API concepts.
