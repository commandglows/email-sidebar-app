# Source Sidebar for Flutter

This public repository owns `source_sidebar_flutter`, the native,
provider-neutral source inbox and reading interface consumed by CommandGlows
applications. It is a Flutter implementation, not a WebView wrapper.

The deployed Vercel preview runs the real package with synthetic sources. Its
actions are deliberately simulated: the preview contains no Readwise token,
performs no network mutation, and cannot alter a real library.

The original v0/React prototype remains available in Git history as the initial
interaction reference; it is no longer an active application or deployment.

## Repository layout

- `packages/source_sidebar_flutter`: reusable Flutter presentation package.
- `demo`: Flutter Web preview consuming the package by local path.
- `scripts/vercel-build.sh`: reproducible Vercel build with Flutter 3.41.7.

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
