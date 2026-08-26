import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'source_sidebar_item.dart';
import 'source_sidebar_style.dart';

class SourceSidebar extends StatefulWidget {
  const SourceSidebar({
    required this.items,
    required this.onSelected,
    super.key,
    this.title = 'Sources',
    this.selectedId,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.emptyMessage = 'No sources to review.',
    this.style = const SourceSidebarStyle(),
    this.onRefresh,
    this.onLoadMore,
    this.onIngest,
    this.onMarkSeen,
    this.onArchive,
    this.onDelete,
    this.onOpenExternal,
  });

  final String title;
  final List<SourceSidebarItem> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String emptyMessage;
  final SourceSidebarStyle style;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final SourceItemCallback? onIngest;
  final SourceItemCallback? onMarkSeen;
  final SourceItemCallback? onArchive;
  final SourceItemCallback? onDelete;
  final SourceItemCallback? onOpenExternal;

  @override
  State<SourceSidebar> createState() => _SourceSidebarState();
}

class _SourceSidebarState extends State<SourceSidebar> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _pendingAction;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<SourceSidebarItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((item) {
          return item.title.toLowerCase().contains(query) ||
              item.authorOrPublisher.toLowerCase().contains(query) ||
              item.summary.toLowerCase().contains(query) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  SourceSidebarItem? get _selectedItem {
    final selectedId = widget.selectedId;
    if (selectedId == null) return null;
    for (final item in widget.items) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  void _moveSelection(int delta) {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final current = items.indexWhere((item) => item.id == widget.selectedId);
    final next = current < 0
        ? 0
        : (current + delta).clamp(0, items.length - 1).toInt();
    widget.onSelected(items[next].id);
  }

  Future<void> _runAction(
    String name,
    SourceSidebarItem item,
    SourceItemCallback callback,
  ) async {
    if (_pendingAction != null) return;
    setState(() => _pendingAction = name);
    try {
      await callback(item);
    } finally {
      if (mounted) setState(() => _pendingAction = null);
    }
  }

  Future<void> _confirmDelete(SourceSidebarItem item) async {
    final callback = widget.onDelete;
    if (callback == null || _pendingAction != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this source?'),
        content: Text(
          '“${item.title}” will be removed from the shared source library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _runAction('delete', item, callback);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyJ): _NextSourceIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): _NextSourceIntent(),
        SingleActivator(LogicalKeyboardKey.keyK): _PreviousSourceIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _PreviousSourceIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _FocusSearchIntent(),
      },
      child: Actions(
        actions: {
          _NextSourceIntent: CallbackAction<_NextSourceIntent>(
            onInvoke: (_) => _moveSelection(1),
          ),
          _PreviousSourceIntent: CallbackAction<_PreviousSourceIntent>(
            onInvoke: (_) => _moveSelection(-1),
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) => _searchFocus.requestFocus(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < widget.style.compactBreakpoint;
              final selected = _selectedItem;
              if (compact && selected != null) {
                return _DetailPane(
                  item: selected,
                  style: widget.style,
                  pendingAction: _pendingAction,
                  showBack: true,
                  onBack: () => widget.onSelected(null),
                  onIngest: widget.onIngest == null
                      ? null
                      : () => _runAction('ingest', selected, widget.onIngest!),
                  onMarkSeen: widget.onMarkSeen == null
                      ? null
                      : () => _runAction('seen', selected, widget.onMarkSeen!),
                  onArchive: widget.onArchive == null
                      ? null
                      : () =>
                            _runAction('archive', selected, widget.onArchive!),
                  onOpenExternal: widget.onOpenExternal == null
                      ? null
                      : () => _runAction(
                          'open',
                          selected,
                          widget.onOpenExternal!,
                        ),
                  onDelete: widget.onDelete == null
                      ? null
                      : () => _confirmDelete(selected),
                );
              }

              final list = _ListPane(
                title: widget.title,
                items: _filteredItems,
                selectedId: widget.selectedId,
                isLoading: widget.isLoading,
                isLoadingMore: widget.isLoadingMore,
                hasMore: widget.hasMore,
                errorMessage: widget.errorMessage,
                emptyMessage: widget.emptyMessage,
                style: widget.style,
                searchController: _searchController,
                searchFocus: _searchFocus,
                onSearchChanged: (value) => setState(() => _query = value),
                onSelected: widget.onSelected,
                onRefresh: widget.onRefresh,
                onLoadMore: widget.onLoadMore,
              );

              if (compact) return list;
              return Row(
                children: [
                  SizedBox(width: widget.style.listWidth, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: selected == null
                        ? const _NoSelection()
                        : _DetailPane(
                            item: selected,
                            style: widget.style,
                            pendingAction: _pendingAction,
                            onIngest: widget.onIngest == null
                                ? null
                                : () => _runAction(
                                    'ingest',
                                    selected,
                                    widget.onIngest!,
                                  ),
                            onMarkSeen: widget.onMarkSeen == null
                                ? null
                                : () => _runAction(
                                    'seen',
                                    selected,
                                    widget.onMarkSeen!,
                                  ),
                            onArchive: widget.onArchive == null
                                ? null
                                : () => _runAction(
                                    'archive',
                                    selected,
                                    widget.onArchive!,
                                  ),
                            onOpenExternal: widget.onOpenExternal == null
                                ? null
                                : () => _runAction(
                                    'open',
                                    selected,
                                    widget.onOpenExternal!,
                                  ),
                            onDelete: widget.onDelete == null
                                ? null
                                : () => _confirmDelete(selected),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ListPane extends StatelessWidget {
  const _ListPane({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.emptyMessage,
    required this.style,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onSelected,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final String title;
  final List<SourceSidebarItem> items;
  final String? selectedId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String emptyMessage;
  final SourceSidebarStyle style;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSelected;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: style.contentPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    tooltip: 'Refresh sources',
                    onPressed: isLoading ? null : onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
          ),
          Padding(
            padding: style.listPadding,
            child: SearchBar(
              controller: searchController,
              focusNode: searchFocus,
              hintText: 'Search sources',
              leading: const Icon(Icons.search),
              trailing: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: onSearchChanged,
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null && items.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: errorMessage!,
        actionLabel: onRefresh == null ? null : 'Try again',
        onAction: onRefresh,
      );
    }
    if (items.isEmpty) {
      return _MessageState(icon: Icons.inbox_outlined, message: emptyMessage);
    }
    return ListView.builder(
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: style.listPadding,
            child: OutlinedButton(
              onPressed: isLoadingMore ? null : onLoadMore,
              child: isLoadingMore
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          );
        }
        final item = items[index];
        final selected = item.id == selectedId;
        return Semantics(
          selected: selected,
          button: true,
          label: '${item.title}, ${item.authorOrPublisher}',
          child: Padding(
            padding: style.listPadding,
            child: Material(
              color: selected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(style.itemRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(style.itemRadius),
                onTap: () => onSelected(item.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!item.seen)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.authorOrPublisher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({
    required this.item,
    required this.style,
    required this.pendingAction,
    this.showBack = false,
    this.onBack,
    this.onIngest,
    this.onMarkSeen,
    this.onArchive,
    this.onDelete,
    this.onOpenExternal,
  });

  final SourceSidebarItem item;
  final SourceSidebarStyle style;
  final String? pendingAction;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onIngest;
  final VoidCallback? onMarkSeen;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final busy =
        pendingAction != null ||
        item.processingState == SourceProcessingState.processing;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: style.contentPadding,
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: 'Back to sources',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                _ActionIcon(
                  tooltip: 'Open in source library',
                  icon: Icons.open_in_new,
                  onPressed: busy ? null : onOpenExternal,
                ),
                _ActionIcon(
                  tooltip: 'Mark as seen',
                  icon: Icons.visibility_outlined,
                  onPressed: busy ? null : onMarkSeen,
                ),
                _ActionIcon(
                  tooltip: 'Archive source',
                  icon: Icons.archive_outlined,
                  onPressed: busy ? null : onArchive,
                ),
                _ActionIcon(
                  tooltip: 'Delete source',
                  icon: Icons.delete_outline,
                  onPressed: busy ? null : onDelete,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: style.contentPadding,
              child: SelectionArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.authorOrPublisher,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(item.sourceType)),
                          Chip(label: Text(item.location)),
                          ...item.tags.map((tag) => Chip(label: Text(tag))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(item.content),
                      if (onIngest != null) ...[
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: busy ? null : onIngest,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Send to project'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return const _MessageState(
      icon: Icons.article_outlined,
      message: 'Select a source to read it.',
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextSourceIntent extends Intent {
  const _NextSourceIntent();
}

class _PreviousSourceIntent extends Intent {
  const _PreviousSourceIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}
