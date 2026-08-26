import 'package:flutter/material.dart';
import 'package:source_sidebar_flutter/source_sidebar_flutter.dart';

import 'preview_theme.dart';

void main() => runApp(const SourceSidebarPreviewApp());

class SourceSidebarPreviewApp extends StatefulWidget {
  const SourceSidebarPreviewApp({super.key});

  @override
  State<SourceSidebarPreviewApp> createState() =>
      _SourceSidebarPreviewAppState();
}

class _SourceSidebarPreviewAppState extends State<SourceSidebarPreviewApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sources — Flutter preview',
      theme: PreviewTheme.light(),
      darkTheme: PreviewTheme.dark(),
      themeMode: _themeMode,
      home: SourceLibraryDemo(
        darkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: (darkMode) => setState(
          () => _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

class SourceLibraryDemo extends StatefulWidget {
  const SourceLibraryDemo({
    required this.darkMode,
    required this.onThemeChanged,
    super.key,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SourceLibraryDemo> createState() => _SourceLibraryDemoState();
}

class _SourceLibraryDemoState extends State<SourceLibraryDemo> {
  static const _moveDestinations = [
    SourceMoveDestination(id: 'later', label: 'Later'),
    SourceMoveDestination(id: 'reference', label: 'Reference'),
    SourceMoveDestination(id: 'archive', label: 'Archived'),
  ];

  late List<SourceSidebarItem> _items;
  String? _selectedId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _items = _previewSources();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future<void>.delayed(PreviewTheme.simulatedActionDelay);
    if (!mounted) return;
    setState(() {
      _items = _previewSources();
      _selectedId = null;
      _loading = false;
    });
    _notify('Demo library refreshed.');
  }

  Future<void> _ingest(SourceSidebarItem item) async {
    _replace(item, processingState: SourceProcessingState.processing);
    await Future<void>.delayed(PreviewTheme.simulatedActionDelay);
    if (!mounted) return;
    _replace(
      item,
      processingState: SourceProcessingState.processed,
      tags: {...item.tags, 'demo-processed'}.toList(),
    );
    _notify('Sent to the selected project (simulated).');
  }

  Future<void> _markSeen(SourceSidebarItem item) async {
    _replace(item, seen: true);
    _notify('Marked as seen in this demo.');
  }

  Future<void> _archive(SourceSidebarItem item) async {
    _replace(item, location: 'archive');
    setState(() => _selectedId = null);
    _notify('Moved to Archived in this demo.');
  }

  Future<void> _move(
    SourceSidebarItem item,
    SourceMoveDestination destination,
  ) async {
    _replace(item, location: destination.id);
    setState(() => _selectedId = null);
    _notify('Moved to ${destination.label} in this demo.');
  }

  Future<void> _delete(SourceSidebarItem item) async {
    setState(() {
      _items = _items.where((candidate) => candidate.id != item.id).toList();
      _selectedId = null;
    });
    _notify('Deleted from this demo. Refresh to restore it.');
  }

  Future<void> _openExternal(SourceSidebarItem item) async {
    _notify('External Reader links are disabled in the public demo.');
  }

  Future<void> _openLibrary() async {
    _notify('Readwise is disconnected from this synthetic public demo.');
  }

  void _replace(
    SourceSidebarItem source, {
    bool? seen,
    String? location,
    List<String>? tags,
    SourceProcessingState? processingState,
  }) {
    setState(() {
      _items = _items
          .map(
            (item) => item.id == source.id
                ? SourceSidebarItem(
                    id: item.id,
                    title: item.title,
                    authorOrPublisher: item.authorOrPublisher,
                    summary: item.summary,
                    publishedAt: item.publishedAt,
                    sourceType: item.sourceType,
                    content: item.content,
                    tags: tags ?? item.tags,
                    seen: seen ?? item.seen,
                    location: location ?? item.location,
                    processingState: processingState ?? item.processingState,
                    canonicalExternalUrl: item.canonicalExternalUrl,
                  )
                : item,
          )
          .toList(growable: false);
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SourceSidebar(
          title: 'Sources',
          items: _items,
          selectedId: _selectedId,
          isLoading: _loading,
          style: PreviewTheme.sidebarStyle(widget.darkMode),
          topBarActions: [
            IconButton(
              tooltip: widget.darkMode ? 'Use light theme' : 'Use dark theme',
              onPressed: () => widget.onThemeChanged(!widget.darkMode),
              icon: Icon(
                widget.darkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(radius: 16, child: Text('D')),
            ),
          ],
          onSelected: (id) => setState(() => _selectedId = id),
          onRefresh: _refresh,
          onOpenLibrary: _openLibrary,
          onIngest: _ingest,
          onMarkSeen: _markSeen,
          onArchive: _archive,
          onDelete: _delete,
          onOpenExternal: _openExternal,
          moveDestinations: _moveDestinations,
          laterDestinationId: 'later',
          onMove: _move,
        ),
      ),
    );
  }
}

List<SourceSidebarItem> _previewSources() => [
  _source(
    id: 'flutter-architecture',
    publisher: 'Flutter Engineering Weekly',
    title: 'Designing resilient Flutter application boundaries',
    summary: 'Keep product decisions separate from provider adapters.',
    day: 25,
    tags: const ['shipglows-ready', 'flutter'],
    content:
        '''A resilient Flutter application keeps presentation, domain decisions, and external providers behind clear boundaries.

This synthetic article demonstrates the long-form reading state. Select text, search the library, switch themes, and send the source to a project to evaluate the complete interaction.''',
  ),
  _source(
    id: 'security-roundup',
    publisher: 'Practical AppSec Dispatch',
    title: 'Security signals worth tracking this week',
    summary: 'Authentication, provenance, and prompt-injection boundaries.',
    day: 24,
    tags: const ['shipglows-ready', 'security'],
  ),
  _source(
    id: 'content-systems',
    publisher: 'Editorial Systems',
    title: 'Repurposing research without losing provenance',
    summary: 'One source library can feed distinct project workflows.',
    day: 23,
    tags: const ['contentglows-ready', 'workflow'],
    seen: true,
  ),
  _source(
    id: 'dependency-health',
    publisher: 'Dependency Health',
    title: 'The maintenance signals hidden in release notes',
    summary: 'What to extract before an upgrade becomes urgent.',
    day: 22,
    tags: const ['shipglows-ready', 'maintenance'],
  ),
  _source(
    id: 'reader-workflow',
    publisher: 'Knowledge Ops Notes',
    title: 'A calmer workflow for newsletter research',
    summary: 'Capture once, review deliberately, distribute when useful.',
    day: 21,
    tags: const ['research', 'reader'],
    seen: true,
  ),
  _source(
    id: 'health-storytelling',
    publisher: 'Health Narrative Lab',
    title: 'Turning expert interviews into trustworthy stories',
    summary: 'A provenance-first framework for health content.',
    day: 20,
    tags: const ['contentglows-ready', 'health'],
    seen: true,
  ),
  _source(
    id: 'browser-security',
    publisher: 'Browser Security Brief',
    title: 'Passkeys, sessions, and safer recovery flows',
    summary: 'Practical implementation notes from production teams.',
    day: 19,
    tags: const ['shipglows-ready', 'security'],
  ),
  _source(
    id: 'editorial-angles',
    publisher: 'The Editorial Operator',
    title: 'Seven ways to find a sharper content angle',
    summary: 'Move from collected sources to defensible points of view.',
    day: 18,
    tags: const ['contentglows-ready', 'research'],
    processed: true,
  ),
  _source(
    id: 'flutter-performance',
    publisher: 'Flutter Performance Notes',
    title: 'Frame budgets for dense information interfaces',
    summary: 'Keep scrolling smooth without flattening the experience.',
    day: 17,
    tags: const ['shipglows-ready', 'flutter'],
    seen: true,
  ),
  _source(
    id: 'business-models',
    publisher: 'Independent Business Review',
    title: 'Where small software products gain leverage',
    summary: 'Distribution and workflow advantages worth studying.',
    day: 16,
    tags: const ['contentglows-ready', 'business'],
  ),
  _source(
    id: 'supply-chain',
    publisher: 'Secure Supply Chain',
    title: 'A field checklist for package provenance',
    summary: 'Attestations, lockfiles, and the controls between them.',
    day: 15,
    tags: const ['shipglows-ready', 'security'],
    processed: true,
    seen: true,
  ),
  _source(
    id: 'archived-example',
    publisher: 'Product Systems Archive',
    title: 'A source already reviewed and archived',
    summary: 'Synthetic data for testing the archive navigation state.',
    day: 14,
    tags: const ['workflow'],
    location: 'archive',
    seen: true,
  ),
];

SourceSidebarItem _source({
  required String id,
  required String publisher,
  required String title,
  required String summary,
  required int day,
  required List<String> tags,
  String? content,
  bool seen = false,
  bool processed = false,
  String location = 'new',
}) {
  return SourceSidebarItem(
    id: id,
    title: title,
    authorOrPublisher: publisher,
    summary: summary,
    publishedAt: DateTime.utc(2026, 8, day),
    sourceType: 'newsletter',
    content:
        content ??
        '''This synthetic newsletter entry is included to test the density, reading rhythm, and project handoff of the shared Flutter source interface.

Production applications provide sanitized content and decide what “Send to project” means. The shared package remains independent from Readwise and from either product architecture.''',
    tags: tags,
    seen: seen,
    location: location,
    processingState: processed
        ? SourceProcessingState.processed
        : SourceProcessingState.idle,
    canonicalExternalUrl: Uri.https('readwise.io', '/reader'),
  );
}
