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
    this.onOpenLibrary,
    this.onIngest,
    this.onMarkSeen,
    this.onArchive,
    this.onDelete,
    this.onOpenExternal,
    this.topBarActions = const <Widget>[],
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
  final Future<void> Function()? onOpenLibrary;
  final SourceItemCallback? onIngest;
  final SourceItemCallback? onMarkSeen;
  final SourceItemCallback? onArchive;
  final SourceItemCallback? onDelete;
  final SourceItemCallback? onOpenExternal;
  final List<Widget> topBarActions;

  @override
  State<SourceSidebar> createState() => _SourceSidebarState();
}

class _SourceSidebarState extends State<SourceSidebar> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String _filterId = _FilterId.inbox;
  String? _pendingAction;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  SourceSidebarColors get _colors =>
      widget.style.colors ??
      SourceSidebarColors.fromColorScheme(Theme.of(context).colorScheme);

  List<SourceSidebarItem> get _visibleItems {
    final query = _query.trim().toLowerCase();
    return widget.items
        .where((item) {
          final matchesQuery =
              query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.authorOrPublisher.toLowerCase().contains(query) ||
              item.summary.toLowerCase().contains(query) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query));
          if (!matchesQuery) return false;
          return switch (_filterId) {
            _FilterId.inbox => item.location != 'archive',
            _FilterId.unread => !item.seen && item.location != 'archive',
            _FilterId.processed =>
              item.processingState == SourceProcessingState.processed,
            _FilterId.archive => item.location == 'archive',
            _ =>
              _filterId.startsWith(_FilterId.tagPrefix)
                  ? item.tags.contains(
                      _filterId.substring(_FilterId.tagPrefix.length),
                    )
                  : true,
          };
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

  List<String> get _tags {
    final counts = <String, int>{};
    for (final item in widget.items) {
      for (final tag in item.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final tags = counts.keys.toList()
      ..sort((a, b) {
        final countOrder = counts[b]!.compareTo(counts[a]!);
        return countOrder == 0 ? a.compareTo(b) : countOrder;
      });
    return tags.take(6).toList(growable: false);
  }

  int _countFor(String filterId) {
    return switch (filterId) {
      _FilterId.inbox =>
        widget.items.where((item) => item.location != 'archive').length,
      _FilterId.unread =>
        widget.items
            .where((item) => !item.seen && item.location != 'archive')
            .length,
      _FilterId.processed =>
        widget.items
            .where(
              (item) => item.processingState == SourceProcessingState.processed,
            )
            .length,
      _FilterId.archive =>
        widget.items.where((item) => item.location == 'archive').length,
      _ =>
        filterId.startsWith(_FilterId.tagPrefix)
            ? widget.items
                  .where(
                    (item) => item.tags.contains(
                      filterId.substring(_FilterId.tagPrefix.length),
                    ),
                  )
                  .length
            : 0,
    };
  }

  String get _filterLabel {
    return switch (_filterId) {
      _FilterId.inbox => 'Inbox',
      _FilterId.unread => 'Unread',
      _FilterId.processed => 'Processed',
      _FilterId.archive => 'Archived',
      _ =>
        _filterId.startsWith(_FilterId.tagPrefix)
            ? _filterId.substring(_FilterId.tagPrefix.length)
            : 'Sources',
    };
  }

  void _selectFilter(String id) {
    setState(() => _filterId = id);
    widget.onSelected(null);
  }

  void _moveSelection(int delta) {
    if (_searchFocus.hasFocus) return;
    final items = _visibleItems;
    if (items.isEmpty) return;
    final current = items.indexWhere((item) => item.id == widget.selectedId);
    final next = current < 0
        ? 0
        : (current + delta).clamp(0, items.length - 1).toInt();
    widget.onSelected(items[next].id);
  }

  void _closeReader() => widget.onSelected(null);

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

  Future<void> _showNavigationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: _NavigationPane(
          title: widget.title,
          style: widget.style,
          colors: _colors,
          selectedFilterId: _filterId,
          tags: _tags,
          countFor: _countFor,
          onOpenLibrary: widget.onOpenLibrary,
          onFilterSelected: (id) {
            Navigator.pop(sheetContext);
            _selectFilter(id);
          },
        ),
      ),
    );
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
        SingleActivator(LogicalKeyboardKey.escape): _CloseReaderIntent(),
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
          _CloseReaderIntent: CallbackAction<_CloseReaderIntent>(
            onInvoke: (_) => _closeReader(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < widget.style.compactBreakpoint;
              final showNavigation =
                  constraints.maxWidth >= widget.style.navigationBreakpoint;
              return Material(
                color: _colors.canvas,
                child: Column(
                  children: [
                    _TopBar(
                      title: widget.title,
                      compact: !showNavigation,
                      style: widget.style,
                      colors: _colors,
                      searchController: _searchController,
                      searchFocus: _searchFocus,
                      onSearchChanged: (query) =>
                          setState(() => _query = query),
                      onMenu: _showNavigationSheet,
                      onRefresh: widget.onRefresh,
                      isLoading: widget.isLoading,
                      actions: widget.topBarActions,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (showNavigation)
                            SizedBox(
                              width: widget.style.navigationWidth,
                              child: _NavigationPane(
                                title: widget.title,
                                style: widget.style,
                                colors: _colors,
                                selectedFilterId: _filterId,
                                tags: _tags,
                                countFor: _countFor,
                                onOpenLibrary: widget.onOpenLibrary,
                                onFilterSelected: _selectFilter,
                              ),
                            ),
                          Expanded(
                            child: _selectedItem == null
                                ? _SourceInbox(
                                    items: _visibleItems,
                                    selectedId: widget.selectedId,
                                    filterLabel: _filterLabel,
                                    isLoading: widget.isLoading,
                                    isLoadingMore: widget.isLoadingMore,
                                    hasMore: widget.hasMore,
                                    errorMessage: widget.errorMessage,
                                    emptyMessage: widget.emptyMessage,
                                    compact: compact,
                                    style: widget.style,
                                    colors: _colors,
                                    onSelected: widget.onSelected,
                                    onRefresh: widget.onRefresh,
                                    onLoadMore: widget.onLoadMore,
                                  )
                                : _ReaderPane(
                                    item: _selectedItem!,
                                    items: _visibleItems,
                                    style: widget.style,
                                    colors: _colors,
                                    pendingAction: _pendingAction,
                                    onBack: _closeReader,
                                    onPrevious: () => _moveSelection(-1),
                                    onNext: () => _moveSelection(1),
                                    onIngest: widget.onIngest == null
                                        ? null
                                        : () => _runAction(
                                            'ingest',
                                            _selectedItem!,
                                            widget.onIngest!,
                                          ),
                                    onMarkSeen: widget.onMarkSeen == null
                                        ? null
                                        : () => _runAction(
                                            'seen',
                                            _selectedItem!,
                                            widget.onMarkSeen!,
                                          ),
                                    onArchive: widget.onArchive == null
                                        ? null
                                        : () => _runAction(
                                            'archive',
                                            _selectedItem!,
                                            widget.onArchive!,
                                          ),
                                    onOpenExternal:
                                        widget.onOpenExternal == null
                                        ? null
                                        : () => _runAction(
                                            'open',
                                            _selectedItem!,
                                            widget.onOpenExternal!,
                                          ),
                                    onDelete: widget.onDelete == null
                                        ? null
                                        : () => _confirmDelete(_selectedItem!),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.compact,
    required this.style,
    required this.colors,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onMenu,
    required this.onRefresh,
    required this.isLoading,
    required this.actions,
  });

  final String title;
  final bool compact;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onMenu;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          IconButton(
            tooltip: 'Source filters',
            onPressed: onMenu,
            icon: const Icon(Icons.menu),
          ),
        Icon(Icons.auto_stories_outlined, color: colors.focus),
        SizedBox(width: style.identityGap),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );

    final search = _SourceSearch(
      controller: searchController,
      focusNode: searchFocus,
      style: style,
      colors: colors,
      onChanged: onSearchChanged,
    );

    final refresh = IconButton(
      tooltip: 'Refresh sources',
      onPressed: isLoading ? null : onRefresh,
      icon: isLoading
          ? SizedBox.square(
              dimension: style.actionIconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
    );

    if (compact) {
      return ColoredBox(
        color: colors.surface,
        child: Padding(
          padding: style.searchPadding,
          child: Column(
            children: [
              SizedBox(
                height: style.topBarHeight,
                child: Row(
                  children: [
                    Expanded(child: identity),
                    refresh,
                    ...actions,
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: style.gapMedium),
                child: search,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: style.topBarHeight,
      color: colors.surface,
      padding: style.searchPadding,
      child: Row(
        children: [
          SizedBox(width: style.navigationWidth - 16, child: identity),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: style.searchMaxWidth),
                child: search,
              ),
            ),
          ),
          refresh,
          ...actions,
        ],
      ),
    );
  }
}

class _SourceSearch extends StatelessWidget {
  const _SourceSearch({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.colors,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search sources',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.tune, semanticLabel: 'Search options')
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: colors.searchSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.searchRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.searchRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.searchRadius),
          borderSide: BorderSide(color: colors.focus),
        ),
      ),
    );
  }
}

class _NavigationPane extends StatelessWidget {
  const _NavigationPane({
    required this.title,
    required this.style,
    required this.colors,
    required this.selectedFilterId,
    required this.tags,
    required this.countFor,
    required this.onOpenLibrary,
    required this.onFilterSelected,
  });

  final String title;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final String selectedFilterId;
  final List<String> tags;
  final int Function(String) countFor;
  final Future<void> Function()? onOpenLibrary;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.canvas,
      child: ListView(
        padding: style.navigationPadding,
        children: [
          if (onOpenLibrary != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryActionSurface,
                  foregroundColor: colors.primaryActionForeground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      style.primaryActionRadius,
                    ),
                  ),
                ),
                onPressed: onOpenLibrary,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open library'),
              ),
            ),
            SizedBox(height: style.gapLarge),
          ],
          _NavigationItem(
            label: 'Inbox',
            icon: Icons.inbox_outlined,
            count: countFor(_FilterId.inbox),
            selected: selectedFilterId == _FilterId.inbox,
            style: style,
            colors: colors,
            onTap: () => onFilterSelected(_FilterId.inbox),
          ),
          _NavigationItem(
            label: 'Unread',
            icon: Icons.mark_email_unread_outlined,
            count: countFor(_FilterId.unread),
            selected: selectedFilterId == _FilterId.unread,
            style: style,
            colors: colors,
            onTap: () => onFilterSelected(_FilterId.unread),
          ),
          _NavigationItem(
            label: 'Processed',
            icon: Icons.task_alt_outlined,
            count: countFor(_FilterId.processed),
            selected: selectedFilterId == _FilterId.processed,
            style: style,
            colors: colors,
            onTap: () => onFilterSelected(_FilterId.processed),
          ),
          _NavigationItem(
            label: 'Archived',
            icon: Icons.archive_outlined,
            count: countFor(_FilterId.archive),
            selected: selectedFilterId == _FilterId.archive,
            style: style,
            colors: colors,
            onTap: () => onFilterSelected(_FilterId.archive),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: style.gapExtraLarge),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'Labels',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: colors.foreground),
              ),
            ),
            ...tags.map((tag) {
              final id = '${_FilterId.tagPrefix}$tag';
              return _NavigationItem(
                label: tag,
                icon: Icons.label_outline,
                count: countFor(id),
                selected: selectedFilterId == id,
                style: style,
                colors: colors,
                onTap: () => onFilterSelected(id),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.style,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.selectedSurface
            : colors.canvas.withValues(alpha: 0),
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(style.navigationItemRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(style.navigationItemRadius),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: style.actionIconSize),
                SizedBox(width: style.gapLarge),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (count > 0)
                  Text('$count', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceInbox extends StatelessWidget {
  const _SourceInbox({
    required this.items,
    required this.selectedId,
    required this.filterLabel,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.emptyMessage,
    required this.compact,
    required this.style,
    required this.colors,
    required this.onSelected,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final List<SourceSidebarItem> items;
  final String? selectedId;
  final String filterLabel;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String emptyMessage;
  final bool compact;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final ValueChanged<String?> onSelected;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          Container(
            height: style.toolbarHeight,
            padding: style.toolbarPadding,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Text(
                  filterLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colors.foreground),
                ),
                SizedBox(width: style.gapSmall),
                Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                if (!compact)
                  Text(
                    'J/K to navigate',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh sources',
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
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
        style: style,
        actionLabel: onRefresh == null ? null : 'Try again',
        onAction: onRefresh,
      );
    }
    if (items.isEmpty) {
      return _MessageState(
        icon: Icons.inbox_outlined,
        message: emptyMessage,
        style: style,
      );
    }
    return ListView.separated(
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          Divider(height: style.dividerThickness, color: colors.divider),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: style.contentPadding,
            child: OutlinedButton(
              onPressed: isLoadingMore ? null : onLoadMore,
              child: isLoadingMore
                  ? SizedBox.square(
                      dimension: style.actionIconSize,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          );
        }
        final item = items[index];
        return _DenseSourceRow(
          item: item,
          compact: compact,
          selected: item.id == selectedId,
          style: style,
          colors: colors,
          onTap: () => onSelected(item.id),
        );
      },
    );
  }
}

class _DenseSourceRow extends StatelessWidget {
  const _DenseSourceRow({
    required this.item,
    required this.compact,
    required this.selected,
    required this.style,
    required this.colors,
    required this.onTap,
  });

  final SourceSidebarItem item;
  final bool compact;
  final bool selected;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? colors.selectedSurface
        : item.seen
        ? colors.surface
        : colors.unreadSurface;
    final titleWeight = item.seen ? FontWeight.w500 : FontWeight.w700;

    return Semantics(
      selected: selected,
      button: true,
      label: '${item.title}, ${item.authorOrPublisher}',
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: style.denseRowHeight),
            child: Padding(
              padding: style.rowPadding,
              child: compact
                  ? _compactContent(context, titleWeight)
                  : _wideContent(context, titleWeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactContent(BuildContext context, FontWeight titleWeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UnreadIndicator(item: item, style: style, colors: colors),
        SizedBox(width: style.rowLeadingGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.authorOrPublisher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: titleWeight,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  Text(
                    _dateLabel(item.publishedAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              SizedBox(height: style.denseTextGap),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: titleWeight,
                  color: colors.foreground,
                ),
              ),
              Text(
                item.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wideContent(BuildContext context, FontWeight titleWeight) {
    return Row(
      children: [
        _UnreadIndicator(item: item, style: style, colors: colors),
        SizedBox(width: style.gapMedium),
        SizedBox(
          width: style.publisherColumnWidth,
          child: Text(
            item.authorOrPublisher,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: titleWeight,
              color: colors.foreground,
            ),
          ),
        ),
        SizedBox(width: style.gapLarge),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: titleWeight,
                    color: colors.foreground,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  ' — ${item.summary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (item.tags.isNotEmpty) ...[
          SizedBox(width: style.gapMedium),
          _TagDots(tags: item.tags, style: style, colors: colors),
        ],
        SizedBox(width: style.gapLarge),
        SizedBox(
          width: style.dateColumnWidth,
          child: Text(
            _dateLabel(item.publishedAt),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontWeight: titleWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnreadIndicator extends StatelessWidget {
  const _UnreadIndicator({
    required this.item,
    required this.style,
    required this.colors,
  });

  final SourceSidebarItem item;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: style.actionIconSize,
      child: Center(
        child: item.seen
            ? Icon(
                Icons.article_outlined,
                size: style.actionIconSize,
                color: colors.mutedForeground,
              )
            : Container(
                width: style.unreadIndicatorSize,
                height: style.unreadIndicatorSize,
                decoration: BoxDecoration(
                  color: colors.focus,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}

class _TagDots extends StatelessWidget {
  const _TagDots({
    required this.tags,
    required this.style,
    required this.colors,
  });

  final List<String> tags;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags
          .take(3)
          .map(
            (tag) => Tooltip(
              message: tag,
              child: Padding(
                padding: EdgeInsets.only(left: style.tagDotGap),
                child: Icon(
                  Icons.label,
                  size: 10,
                  color: colors.focus.withValues(alpha: 0.72),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReaderPane extends StatelessWidget {
  const _ReaderPane({
    required this.item,
    required this.items,
    required this.style,
    required this.colors,
    required this.pendingAction,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
    this.onIngest,
    this.onMarkSeen,
    this.onArchive,
    this.onDelete,
    this.onOpenExternal,
  });

  final SourceSidebarItem item;
  final List<SourceSidebarItem> items;
  final SourceSidebarStyle style;
  final SourceSidebarColors colors;
  final String? pendingAction;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
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
    final index = items.indexWhere((candidate) => candidate.id == item.id);
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          Container(
            height: style.toolbarHeight,
            padding: style.toolbarPadding,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                return Row(
                  children: [
                    _ActionIcon(
                      tooltip: 'Back to sources',
                      icon: Icons.arrow_back,
                      onPressed: onBack,
                    ),
                    _ActionIcon(
                      tooltip: 'Archive source',
                      icon: Icons.archive_outlined,
                      onPressed: busy ? null : onArchive,
                    ),
                    _ActionIcon(
                      tooltip: 'Delete source',
                      icon: Icons.delete_outline,
                      color: colors.danger,
                      onPressed: busy ? null : onDelete,
                    ),
                    if (!narrow)
                      _ActionIcon(
                        tooltip: 'Mark as seen',
                        icon: Icons.mark_email_read_outlined,
                        onPressed: busy ? null : onMarkSeen,
                      ),
                    if (!narrow)
                      _ActionIcon(
                        tooltip: 'Open in source library',
                        icon: Icons.open_in_new,
                        onPressed: busy ? null : onOpenExternal,
                      ),
                    if (narrow &&
                        (onMarkSeen != null || onOpenExternal != null))
                      PopupMenuButton<String>(
                        tooltip: 'More source actions',
                        enabled: !busy,
                        onSelected: (action) {
                          if (action == 'seen') onMarkSeen?.call();
                          if (action == 'open') onOpenExternal?.call();
                        },
                        itemBuilder: (context) => [
                          if (onMarkSeen != null)
                            const PopupMenuItem(
                              value: 'seen',
                              child: Text('Mark as seen'),
                            ),
                          if (onOpenExternal != null)
                            const PopupMenuItem(
                              value: 'open',
                              child: Text('Open in source library'),
                            ),
                        ],
                      ),
                    const Spacer(),
                    if (index >= 0)
                      Text(
                        '${index + 1} of ${items.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    _ActionIcon(
                      tooltip: 'Previous source',
                      icon: Icons.chevron_left,
                      onPressed: index <= 0 ? null : onPrevious,
                    ),
                    _ActionIcon(
                      tooltip: 'Next source',
                      icon: Icons.chevron_right,
                      onPressed: index < 0 || index >= items.length - 1
                          ? null
                          : onNext,
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: style.contentPadding,
              child: Center(
                child: SelectionArea(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: style.readerMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: colors.foreground,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                            if (busy)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox.square(
                                  dimension: style.actionIconSize,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: style.gap2XLarge),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.searchSurface,
                              foregroundColor: colors.foreground,
                              child: Text(_initials(item.authorOrPublisher)),
                            ),
                            SizedBox(width: style.gapMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.authorOrPublisher,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: colors.foreground),
                                  ),
                                  SizedBox(height: style.authorMetadataGap),
                                  Text(
                                    '${item.sourceType} · ${_dateLabel(item.publishedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (item.tags.isNotEmpty) ...[
                          SizedBox(height: style.gapExtraLarge),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.searchSurface,
                                      borderRadius: BorderRadius.circular(
                                        style.tagRadius,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.mutedForeground,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                        SizedBox(height: style.gap3XLarge),
                        Text(
                          item.content,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colors.foreground,
                                height: style.readerLineHeight,
                              ),
                        ),
                        if (onIngest != null) ...[
                          SizedBox(height: style.gap4XLarge),
                          FilledButton.icon(
                            onPressed: busy ? null : onIngest,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Send to project'),
                          ),
                        ],
                        SizedBox(height: style.gap4XLarge),
                      ],
                    ),
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
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.style,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final SourceSidebarStyle style;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.outline),
          SizedBox(height: style.gapMedium),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: style.gapMedium),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

abstract final class _FilterId {
  static const inbox = 'inbox';
  static const unread = 'unread';
  static const processed = 'processed';
  static const archive = 'archive';
  static const tagPrefix = 'tag:';
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final initials = parts.map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
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

class _CloseReaderIntent extends Intent {
  const _CloseReaderIntent();
}
