import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@immutable
class NewsletterStudioShortcuts {
  const NewsletterStudioShortcuts({
    this.next = const [
      SingleActivator(LogicalKeyboardKey.keyJ),
      SingleActivator(LogicalKeyboardKey.arrowDown),
    ],
    this.previous = const [
      SingleActivator(LogicalKeyboardKey.keyK),
      SingleActivator(LogicalKeyboardKey.arrowUp),
    ],
    this.toggleSource = const [SingleActivator(LogicalKeyboardKey.keyX)],
    this.open = const [SingleActivator(LogicalKeyboardKey.enter)],
    this.nextZone = const [SingleActivator(LogicalKeyboardKey.f6)],
    this.previousZone = const [
      SingleActivator(LogicalKeyboardKey.f6, shift: true),
    ],
    this.preview = const [
      SingleActivator(LogicalKeyboardKey.keyP, control: true),
      SingleActivator(LogicalKeyboardKey.keyP, meta: true),
    ],
    this.sendTest = const [
      SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true),
      SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
    ],
    this.review = const [
      SingleActivator(LogicalKeyboardKey.enter, control: true),
      SingleActivator(LogicalKeyboardKey.enter, meta: true),
    ],
    this.close = const [SingleActivator(LogicalKeyboardKey.escape)],
    this.resetZoom = const [
      SingleActivator(LogicalKeyboardKey.digit0, control: true),
      SingleActivator(LogicalKeyboardKey.digit0, meta: true),
    ],
    this.help = const [SingleActivator(LogicalKeyboardKey.slash, shift: true)],
  });

  final List<ShortcutActivator> next;
  final List<ShortcutActivator> previous;
  final List<ShortcutActivator> toggleSource;
  final List<ShortcutActivator> open;
  final List<ShortcutActivator> nextZone;
  final List<ShortcutActivator> previousZone;
  final List<ShortcutActivator> preview;
  final List<ShortcutActivator> sendTest;
  final List<ShortcutActivator> review;
  final List<ShortcutActivator> close;
  final List<ShortcutActivator> resetZoom;
  final List<ShortcutActivator> help;
}
