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
    this.readerLineDown = const [
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
    ],
    this.readerLineUp = const [
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
    ],
    this.readerPageDown = const [SingleActivator(LogicalKeyboardKey.pageDown)],
    this.readerPageUp = const [SingleActivator(LogicalKeyboardKey.pageUp)],
    this.readerStart = const [SingleActivator(LogicalKeyboardKey.home)],
    this.readerEnd = const [SingleActivator(LogicalKeyboardKey.end)],
    this.nextAccount = const [SingleActivator(LogicalKeyboardKey.bracketRight)],
    this.previousAccount = const [
      SingleActivator(LogicalKeyboardKey.bracketLeft),
    ],
    this.chooseAccount = const [
      SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true),
      SingleActivator(LogicalKeyboardKey.keyA, meta: true, shift: true),
    ],
    this.summarize = const [
      SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true),
      SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
    ],
    this.distribute = const [
      SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true),
      SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true),
    ],
    this.ingest = const [
      SingleActivator(LogicalKeyboardKey.keyI, control: true, shift: true),
      SingleActivator(LogicalKeyboardKey.keyI, meta: true, shift: true),
    ],
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
  final List<ShortcutActivator> readerLineDown;
  final List<ShortcutActivator> readerLineUp;
  final List<ShortcutActivator> readerPageDown;
  final List<ShortcutActivator> readerPageUp;
  final List<ShortcutActivator> readerStart;
  final List<ShortcutActivator> readerEnd;
  final List<ShortcutActivator> nextAccount;
  final List<ShortcutActivator> previousAccount;
  final List<ShortcutActivator> chooseAccount;
  final List<ShortcutActivator> summarize;
  final List<ShortcutActivator> distribute;
  final List<ShortcutActivator> ingest;
  final List<ShortcutActivator> resetZoom;
  final List<ShortcutActivator> help;
}
