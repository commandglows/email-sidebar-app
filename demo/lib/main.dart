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
      title: 'Source Sidebar — Flutter preview',
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
    _remove(item);
    _notify('Archived in this demo. Refresh to restore it.');
  }

  Future<void> _delete(SourceSidebarItem item) async {
    _remove(item);
    _notify('Deleted from this demo. Refresh to restore it.');
  }

  Future<void> _openExternal(SourceSidebarItem item) async {
    _notify('External Reader links are disabled in the public demo.');
  }

  void _replace(
    SourceSidebarItem source, {
    bool? seen,
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
                    location: item.location,
                    processingState: processingState ?? item.processingState,
                    canonicalExternalUrl: item.canonicalExternalUrl,
                  )
                : item,
          )
          .toList(growable: false);
    });
  }

  void _remove(SourceSidebarItem source) {
    setState(() {
      _items = _items.where((item) => item.id != source.id).toList();
      if (_selectedId == source.id) _selectedId = null;
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
      appBar: AppBar(
        title: const Text('Source Sidebar · Flutter preview'),
        actions: [
          const Center(child: Chip(label: Text('Synthetic data'))),
          IconButton(
            tooltip: widget.darkMode ? 'Use light theme' : 'Use dark theme',
            onPressed: () => widget.onThemeChanged(!widget.darkMode),
            icon: Icon(
              widget.darkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SourceSidebar(
          title: 'Reader source library',
          items: _items,
          selectedId: _selectedId,
          isLoading: _loading,
          onSelected: (id) => setState(() => _selectedId = id),
          onRefresh: _refresh,
          onIngest: _ingest,
          onMarkSeen: _markSeen,
          onArchive: _archive,
          onDelete: _delete,
          onOpenExternal: _openExternal,
        ),
      ),
    );
  }
}

List<SourceSidebarItem> _previewSources() => [
  SourceSidebarItem(
    id: 'flutter-architecture',
    title: 'Designing resilient Flutter application boundaries',
    authorOrPublisher: 'Flutter Engineering Weekly',
    summary:
        'A practical field guide to keeping product decisions separate from provider adapters.',
    publishedAt: DateTime.utc(2026, 8, 25),
    sourceType: 'newsletter',
    content:
        '''A resilient Flutter application keeps presentation, domain decisions, and external providers behind clear boundaries.

This synthetic article demonstrates the long-form reading state. Select text, search the library, switch themes, and send the source to a project to evaluate the complete interaction.''',
    tags: const ['shipglows-ready', 'flutter'],
    canonicalExternalUrl: Uri.https('readwise.io', '/reader'),
  ),
  SourceSidebarItem(
    id: 'security-roundup',
    title: 'Security signals worth tracking this week',
    authorOrPublisher: 'Practical AppSec Dispatch',
    summary:
        'Authentication hardening, dependency provenance, and prompt-injection boundaries.',
    publishedAt: DateTime.utc(2026, 8, 24),
    sourceType: 'email',
    content:
        '''Three themes matter this week: authoritative authorization checks, dependency provenance, and treating all imported content as untrusted data.

The production adapters delimit source material before it reaches an agent. This public preview contains no credentials and performs no network mutation.''',
    tags: const ['shipglows-ready', 'security'],
    canonicalExternalUrl: Uri.https('readwise.io', '/reader'),
  ),
  SourceSidebarItem(
    id: 'content-systems',
    title: 'Repurposing research without losing provenance',
    authorOrPublisher: 'Editorial Systems',
    summary:
        'How a shared source library can feed distinct project workflows without becoming a monolith.',
    publishedAt: DateTime.utc(2026, 8, 22),
    sourceType: 'newsletter',
    content:
        '''A source library should own capture and reading. Each product should retain ownership of what happens after selection.

ContentGlows creates an Idea Pool outcome. ShipGlows starts a governed agent conversation. Both applications reuse this same Flutter presentation package.''',
    tags: const ['contentglows-ready', 'workflow'],
    seen: true,
    canonicalExternalUrl: Uri.https('readwise.io', '/reader'),
  ),
  SourceSidebarItem(
    id: 'reader-workflow',
    title: 'A calmer workflow for newsletter research',
    authorOrPublisher: 'Knowledge Ops Notes',
    summary:
        'Capture once, review deliberately, and distribute only when a project needs the source.',
    publishedAt: DateTime.utc(2026, 8, 20),
    sourceType: 'article',
    content:
        '''The useful unit is not the inbox message. It is a durable source with provenance, readable content, and explicit project actions.

Try Ctrl or Command + F to focus search. Use J and K, or the arrow keys, to move through the filtered list.''',
    tags: const ['research', 'reader'],
    seen: true,
    canonicalExternalUrl: Uri.https('readwise.io', '/reader'),
  ),
];
