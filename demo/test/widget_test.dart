import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:source_sidebar_preview/main.dart';

void main() {
  testWidgets('previews the shared sidebar and simulates project ingestion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SourceSidebarPreviewApp());
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Cybersecurity'), findsOneWidget);

    await tester.tap(find.textContaining('Designing resilient').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to project'));
    await tester.pumpAndSettle();

    expect(find.text('demo-processed'), findsOneWidget);
  });

  testWidgets('offers a compact list before a source is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SourceSidebarPreviewApp());

    expect(find.text('Sources'), findsOneWidget);
    expect(find.byTooltip('Source filters'), findsOneWidget);
    expect(find.byTooltip('Refresh sources'), findsWidgets);
  });

  testWidgets('demonstrates Later keyboard action', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SourceSidebarPreviewApp());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pumpAndSettle();

    expect(find.text('Moved to Later in this demo.'), findsOneWidget);
  });

  testWidgets('opens the unified Newsletter Studio with synthetic hooks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SourceSidebarPreviewApp());
    await tester.tap(find.byTooltip('Open Newsletter Studio'));
    await tester.pumpAndSettle();

    expect(find.text('Health Signals · Weekly draft'), findsOneWidget);
    expect(find.text('Review and schedule'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('does not prove received-client rendering'),
      findsOneWidget,
    );
  });
}
