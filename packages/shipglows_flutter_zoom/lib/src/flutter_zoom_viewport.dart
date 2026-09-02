import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps a Flutter application surface filled while scaling its complete UI.
class FlutterZoomViewport extends StatefulWidget {
  const FlutterZoomViewport({
    super.key,
    required this.child,
    this.initialZoom = 1,
    this.minimumZoom = 0.75,
    this.maximumZoom = 1.5,
    this.zoomStep = 0.1,
    this.resetShortcuts = const [
      SingleActivator(LogicalKeyboardKey.digit0, control: true),
      SingleActivator(LogicalKeyboardKey.digit0, meta: true),
    ],
    this.onZoomChanged,
  }) : assert(minimumZoom > 0),
       assert(maximumZoom >= minimumZoom),
       assert(initialZoom >= minimumZoom && initialZoom <= maximumZoom),
       assert(zoomStep > 0);

  final Widget child;
  final double initialZoom;
  final double minimumZoom;
  final double maximumZoom;
  final double zoomStep;
  final List<ShortcutActivator> resetShortcuts;
  final ValueChanged<double>? onZoomChanged;

  @override
  State<FlutterZoomViewport> createState() => _FlutterZoomViewportState();
}

class _FlutterZoomViewportState extends State<FlutterZoomViewport> {
  late double _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom;
  }

  @override
  void didUpdateWidget(FlutterZoomViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _zoom = _zoom.clamp(widget.minimumZoom, widget.maximumZoom).toDouble();
  }

  void _setZoom(double value) {
    final next = value.clamp(widget.minimumZoom, widget.maximumZoom).toDouble();
    if (next == _zoom) return;
    setState(() => _zoom = next);
    widget.onZoomChanged?.call(next);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    final isModifiedScroll =
        event is PointerScrollEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed);
    if (!isModifiedScroll && event is! PointerScaleEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (
      resolvedEvent,
    ) {
      final double direction;
      if (resolvedEvent is PointerScaleEvent) {
        if (resolvedEvent.scale == 1) return;
        direction = resolvedEvent.scale > 1 ? 1 : -1;
      } else {
        final scrollEvent = resolvedEvent as PointerScrollEvent;
        if (scrollEvent.scrollDelta.dy == 0) return;
        direction = scrollEvent.scrollDelta.dy < 0 ? 1 : -1;
      }
      _setZoom(_zoom + direction * widget.zoomStep);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{
      for (final shortcut in widget.resetShortcuts)
        shortcut: const _ResetZoomIntent(),
    };
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _ResetZoomIntent: CallbackAction<_ResetZoomIntent>(
            onInvoke: (_) => _setZoom(widget.initialZoom),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth ||
                    !constraints.hasBoundedHeight) {
                  return widget.child;
                }
                return SizedBox(
                  key: const ValueKey('shipglows-flutter-zoom-viewport'),
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: ClipRect(
                    child: Transform.scale(
                      alignment: Alignment.topLeft,
                      scale: _zoom,
                      child: FractionallySizedBox(
                        alignment: Alignment.topLeft,
                        widthFactor: 1 / _zoom,
                        heightFactor: 1 / _zoom,
                        child: SizedBox.expand(
                          key: const ValueKey('shipglows-flutter-zoom-content'),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetZoomIntent extends Intent {
  const _ResetZoomIntent();
}
