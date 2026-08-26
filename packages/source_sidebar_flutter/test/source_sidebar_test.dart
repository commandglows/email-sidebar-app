import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:source_sidebar_flutter/source_sidebar_flutter.dart';

void main() {
  const expandedTestWidth = 1200.0;
  final items = [
    SourceSidebarItem(
      id: 'one',
      title: 'A useful source',
      authorOrPublisher: 'Publisher',
      summary: 'Summary',
      publishedAt: DateTime.utc(2026, 8, 26),
      sourceType: 'email',
      content: 'Sanitized plain-text content.',
      tags: const ['project-ready'],
    ),
  ];

  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: SourceSidebar(items: const [], onSelected: (_) {}),
      ),
    );
    expect(find.text('No sources to review.'), findsOneWidget);
  });

  testWidgets('selects and ingests a source', (tester) async {
    SourceSidebarItem? ingested;
    String? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: SizedBox(
          width: expandedTestWidth,
          child: SourceSidebar(
            items: items,
            onSelected: (id) => selectedId = id,
            onIngest: (item) async => ingested = item,
          ),
        ),
      ),
    );

    await tester.tap(find.text('A useful source').first);
    expect(selectedId, 'one');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: SizedBox(
          width: expandedTestWidth,
          child: SourceSidebar(
            items: items,
            selectedId: selectedId,
            onSelected: (id) => selectedId = id,
            onIngest: (item) async => ingested = item,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Send to project'));
    await tester.pump();
    expect(ingested?.id, 'one');
  });

  testWidgets('requires confirmation before delete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: SizedBox(
          width: expandedTestWidth,
          child: SourceSidebar(
            items: items,
            selectedId: 'one',
            onSelected: (_) {},
            onDelete: (_) async => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Delete source'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this source?'), findsOneWidget);
    expect(deleted, isFalse);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
