# shipglows_flutter_zoom

App-wide zoom for Flutter web and desktop. The viewport stays filled while
Ctrl/Command+mouse wheel or a browser scale signal changes the complete UI.
Ctrl/Command+0 resets the configured zoom.

```dart
FlutterZoomViewport(
  minimumZoom: 0.75,
  maximumZoom: 1.5,
  zoomStep: 0.1,
  child: const MyAppSurface(),
)
```

Consumers should pin an immutable Git commit:

```yaml
shipglows_flutter_zoom:
  git:
    url: https://github.com/commandglows/email-sidebar-app.git
    ref: <commit-sha>
    path: packages/shipglows_flutter_zoom
```
