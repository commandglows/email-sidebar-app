# Source Sidebar for Flutter

This public repository owns `source_sidebar_flutter`, the native,
provider-neutral source inbox and reading interface consumed by CommandGlows
applications. It is a Flutter implementation, not a WebView wrapper.

The deployed Vercel preview runs the real package with synthetic sources. Its
actions are deliberately simulated: the preview contains no Readwise token,
performs no network mutation, and cannot alter a real library.

The original v0/React prototype remains available in Git history as the initial
interaction reference; it is no longer an active application or deployment.

The current Flutter rebuild deliberately preserves that prototype's visual
grammar: a 64 px global header, Gmail-like navigation rail, dense single-line
desktop rows, compact mobile rows, and an in-place reading surface.

## Visual proof

The proof images below are generated from the real Flutter preview with only
synthetic sources. They cover both primary layouts at the approved desktop and
mobile viewports.

![Desktop source list](shipglows_data/visual-proof/desktop-list.png)

![Mobile reader](shipglows_data/visual-proof/mobile-reader.png)

## Repository layout

- `packages/source_sidebar_flutter`: reusable Flutter presentation package.
- `demo`: Flutter Web preview consuming the package by local path.
- `scripts/vercel-build.sh`: reproducible Vercel build with Flutter 3.41.7.
- `shipglows_data/visual-proof`: inspected desktop and mobile reference
  captures for the current Flutter implementation.

## Run the preview locally

```bash
cd demo
flutter pub get
flutter run -d chrome
```

## Validate

```bash
cd packages/source_sidebar_flutter
flutter analyze
flutter test

cd ../../demo
flutter analyze
flutter test
flutter build web --release
```

Licensed under the MIT License.
