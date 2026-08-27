import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keyboard bindings understood by `SourceSidebar`.
///
/// Each list can contain aliases, be replaced by a host, or be set to an empty
/// list to disable that command. The defaults follow the Glows source-review
/// workflow while remaining independent from any source provider.
@immutable
class SourceSidebarShortcuts {
  const SourceSidebarShortcuts({
    this.next = const [
      SingleActivator(LogicalKeyboardKey.keyJ),
      SingleActivator(LogicalKeyboardKey.arrowDown),
    ],
    this.previous = const [
      SingleActivator(LogicalKeyboardKey.keyK),
      SingleActivator(LogicalKeyboardKey.arrowUp),
    ],
    this.open = const [
      SingleActivator(LogicalKeyboardKey.keyO),
      SingleActivator(LogicalKeyboardKey.enter),
    ],
    this.focusSearch = const [
      SingleActivator(LogicalKeyboardKey.slash),
      SingleActivator(LogicalKeyboardKey.keyF, control: true),
      SingleActivator(LogicalKeyboardKey.keyF, meta: true),
    ],
    this.back = const [
      SingleActivator(LogicalKeyboardKey.keyU),
      SingleActivator(LogicalKeyboardKey.escape),
    ],
    this.archive = const [SingleActivator(LogicalKeyboardKey.keyE)],
    this.delete = const [SingleActivator(LogicalKeyboardKey.keyW)],
    this.move = const [SingleActivator(LogicalKeyboardKey.keyV)],
    this.moveToLater = const [SingleActivator(LogicalKeyboardKey.keyL)],
    this.resetZoom = const [
      SingleActivator(LogicalKeyboardKey.digit0, control: true),
      SingleActivator(LogicalKeyboardKey.digit0, meta: true),
    ],
    this.help = const [SingleActivator(LogicalKeyboardKey.slash, shift: true)],
  });

  final List<ShortcutActivator> next;
  final List<ShortcutActivator> previous;
  final List<ShortcutActivator> open;
  final List<ShortcutActivator> focusSearch;
  final List<ShortcutActivator> back;
  final List<ShortcutActivator> archive;
  final List<ShortcutActivator> delete;
  final List<ShortcutActivator> move;
  final List<ShortcutActivator> moveToLater;
  final List<ShortcutActivator> resetZoom;
  final List<ShortcutActivator> help;
}
