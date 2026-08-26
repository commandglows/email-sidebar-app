import 'package:flutter/material.dart';
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
}
