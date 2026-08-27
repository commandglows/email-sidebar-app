import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'newsletter_studio_hooks.dart';
import 'newsletter_studio_models.dart';
import 'newsletter_studio_shortcuts.dart';
import 'newsletter_studio_style.dart';

class NewsletterStudio extends StatefulWidget {
  const NewsletterStudio({
    required this.draft,
    required this.onDraftChanged,
    super.key,
    this.availableSources = const <NewsletterSourceReference>[],
    this.audience,
    this.sender,
    this.design,
    this.schedule,
    this.testReceipt,
    this.deliveryStatus,
    this.validationIssues = const <NewsletterValidationIssue>[],
    this.capabilities = const NewsletterStudioCapabilities(),
    this.style = const NewsletterStudioStyle(),
    this.shortcuts = const NewsletterStudioShortcuts(),
    this.onSaveDraft,
    this.onAttachSources,
    this.onResolveAudience,
    this.onValidateDraft,
    this.onRenderPreview,
    this.onSendTest,
    this.onSchedule,
    this.onSend,
    this.onUnschedule,
    this.onOpenSource,
    this.onLoadDeliveryStatus,
    this.onLoadAnalytics,
    this.onBack,
    this.topBarActions = const <Widget>[],
  });

  final NewsletterDraft draft;
  final NewsletterDraftChanged onDraftChanged;
  final List<NewsletterSourceReference> availableSources;
  final NewsletterAudienceSummary? audience;
  final NewsletterSenderSummary? sender;
  final NewsletterDesignSummary? design;
  final NewsletterSchedule? schedule;
  final NewsletterTestReceipt? testReceipt;
  final NewsletterDeliveryStatus? deliveryStatus;
  final List<NewsletterValidationIssue> validationIssues;
  final NewsletterStudioCapabilities capabilities;
  final NewsletterStudioStyle style;
  final NewsletterStudioShortcuts shortcuts;
  final NewsletterDraftSave? onSaveDraft;
  final NewsletterSourcesAttacher? onAttachSources;
  final NewsletterAudienceResolver? onResolveAudience;
  final NewsletterDraftValidator? onValidateDraft;
  final NewsletterPreviewRenderer? onRenderPreview;
  final NewsletterTestSender? onSendTest;
  final NewsletterScheduler? onSchedule;
  final NewsletterSender? onSend;
  final NewsletterUnscheduler? onUnschedule;
  final NewsletterSourceOpener? onOpenSource;
  final NewsletterDeliveryStatusLoader? onLoadDeliveryStatus;
  final NewsletterAnalyticsLoader? onLoadAnalytics;
  final VoidCallback? onBack;
  final List<Widget> topBarActions;

  @override
  State<NewsletterStudio> createState() => _NewsletterStudioState();
}

class _NewsletterStudioState extends State<NewsletterStudio> {
  final _workspaceFocus = FocusNode(debugLabel: 'Newsletter studio workspace');
  final _sourcesFocus = FocusNode(debugLabel: 'Newsletter sources zone');
  final _editorFocus = FocusNode(debugLabel: 'Newsletter editor zone');
  final _inspectorFocus = FocusNode(debugLabel: 'Newsletter inspector zone');
  final _actionsFocus = FocusNode(debugLabel: 'Newsletter actions zone');
  final _subjectFocus = FocusNode(debugLabel: 'Newsletter subject');
  final _sourceFocusNodes = <String, FocusNode>{};
  final _sourceKeys = <String, GlobalKey>{};
  final _subjectController = TextEditingController();
  final _preheaderController = TextEditingController();

  late NewsletterDraft _draft;
  NewsletterAudienceSummary? _audience;
  NewsletterPreview? _preview;
  NewsletterTestReceipt? _testReceipt;
  NewsletterDeliveryStatus? _deliveryStatus;
  Map<String, num>? _analytics;
  NewsletterOperationKind _operation = NewsletterOperationKind.idle;
  _InspectorTab _inspectorTab = _InspectorTab.content;
  _CompactPage _compactPage = _CompactPage.write;
  Timer? _autosaveTimer;
  int _editSerial = 0;
  String? _selectedSourceId;
  String? _selectedBlockId;
  String? _lastError;
  bool _showPreview = false;
  late double _zoom;

  NewsletterStudioColors get _colors =>
      widget.style.colors ??
      NewsletterStudioColors.fromColorScheme(Theme.of(context).colorScheme);

  bool get _isEditingText {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool get _isBusy => _operation != NewsletterOperationKind.idle &&
      _operation != NewsletterOperationKind.failed;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _audience = widget.audience;
    _testReceipt = widget.testReceipt;
    _deliveryStatus = widget.deliveryStatus;
    _zoom = widget.style.initialZoom;
    _syncControllers();
    if (_draft.sources.isNotEmpty) {
      _selectedSourceId = _draft.sources.first.id;
    } else if (widget.availableSources.isNotEmpty) {
      _selectedSourceId = widget.availableSources.first.id;
    }
    if (_draft.blocks.isNotEmpty) {
      _selectedBlockId = _draft.blocks.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant NewsletterStudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingIsNewer = widget.draft.id != _draft.id ||
        widget.draft.revision > _draft.revision;
    if (incomingIsNewer) {
      _draft = widget.draft;
      _syncControllers();
    }
    if (widget.audience != oldWidget.audience) {
      _audience = widget.audience;
    }
    if (widget.testReceipt != oldWidget.testReceipt) {
      _testReceipt = widget.testReceipt;
    }
    if (widget.deliveryStatus != oldWidget.deliveryStatus) {
      _deliveryStatus = widget.deliveryStatus;
    }
    _zoom = _zoom
        .clamp(widget.style.minimumZoom, widget.style.maximumZoom)
        .toDouble();
    final sourceIds = widget.availableSources.map((source) => source.id).toSet();
    final removed = _sourceFocusNodes.keys
        .where((id) => !sourceIds.contains(id))
        .toList(growable: false);
    for (final id in removed) {
      _sourceFocusNodes.remove(id)?.dispose();
      _sourceKeys.remove(id);
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _workspaceFocus.dispose();
    _sourcesFocus.dispose();
    _editorFocus.dispose();
    _inspectorFocus.dispose();
    _actionsFocus.dispose();
    _subjectFocus.dispose();
    _subjectController.dispose();
    _preheaderController.dispose();
    for (final node in _sourceFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    if (_subjectController.text != _draft.subject) {
      _subjectController.value = TextEditingValue(
        text: _draft.subject,
        selection: TextSelection.collapsed(offset: _draft.subject.length),
      );
    }
    if (_preheaderController.text != _draft.preheader) {
      _preheaderController.value = TextEditingValue(
        text: _draft.preheader,
        selection: TextSelection.collapsed(offset: _draft.preheader.length),
      );
    }
  }

  void _replaceDraft(NewsletterDraft next, {bool autosave = true}) {
    _editSerial += 1;
    final dirty = next.copyWith(saveState: NewsletterSaveState.dirty);
    setState(() {
      _draft = dirty;
      _preview = null;
      _lastError = null;
    });
    widget.onDraftChanged(dirty);
    if (autosave) _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    final save = widget.onSaveDraft;
    if (save == null) return;
    final serial = _editSerial;
    _autosaveTimer = Timer(widget.style.autosaveDelay, () async {
      if (!mounted) return;
      setState(() => _draft = _draft.copyWith(saveState: NewsletterSaveState.saving));
      widget.onDraftChanged(_draft);
      try {
        final saved = await save(_draft);
        if (!mounted || serial != _editSerial) return;
        setState(() {
          _draft = saved.copyWith(saveState: NewsletterSaveState.saved);
          _lastError = null;
        });
        widget.onDraftChanged(_draft);
      } catch (error) {
        if (!mounted || serial != _editSerial) return;
        setState(() {
          _draft = _draft.copyWith(saveState: NewsletterSaveState.failed);
          _lastError = 'Draft save failed: $error';
        });
        widget.onDraftChanged(_draft);
      }
    });
  }

  NewsletterSourceReference? get _selectedSource {
    final id = _selectedSourceId;
    if (id == null) return null;
    for (final source in widget.availableSources) {
      if (source.id == id) return source;
    }
    return null;
  }

  NewsletterBlock? get _selectedBlock {
    final id = _selectedBlockId;
    if (id == null) return null;
    for (final block in _draft.blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  void _moveSourceSelection(int delta) {
    if (_isEditingText || widget.availableSources.isEmpty) return;
    final current = widget.availableSources.indexWhere(
      (source) => source.id == _selectedSourceId,
    );
    final next = current < 0
        ? 0
        : !_sourcesFocus.hasFocus
            ? current
            : (current + delta)
                  .clamp(0, widget.availableSources.length - 1)
                  .toInt();
    setState(() => _selectedSourceId = widget.availableSources[next].id);
    _focusSelectedSource();
  }

  void _focusSelectedSource() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _selectedSourceId;
      _sourceFocusNodes[id]?.requestFocus();
      final rowContext = _sourceKeys[id]?.currentContext;
      if (rowContext != null && rowContext.mounted) {
        Scrollable.ensureVisible(
          rowContext,
          alignment: 0.5,
          duration: widget.style.focusScrollDuration,
        );
      }
    });
  }

  Future<void> _toggleSelectedSource() async {
    if (_isEditingText || !widget.capabilities.canEdit) return;
    final source = _selectedSource;
    if (source == null) return;
    final attached = _draft.sources.any((candidate) => candidate.id == source.id);
    if (attached && _draft.usedSourceIds.contains(source.id)) {
      setState(() {
        _lastError = 'Remove the source block before detaching this source.';
      });
      return;
    }
    final sources = attached
        ? _draft.sources.where((candidate) => candidate.id != source.id).toList()
        : [..._draft.sources, source];
    final attach = widget.onAttachSources;
    if (attach == null) {
      _replaceDraft(_draft.copyWith(sources: sources));
      return;
    }
    try {
      final next = await attach(_draft, sources);
      if (!mounted) return;
      _replaceDraft(next);
    } catch (error) {
      if (mounted) setState(() => _lastError = 'Source update failed: $error');
    }
  }

  void _insertSelectedSource() {
    if (!widget.capabilities.canEdit) return;
    final source = _selectedSource;
    if (source == null) return;
    final sources = _draft.sources.any((item) => item.id == source.id)
        ? _draft.sources
        : [..._draft.sources, source];
    final block = NewsletterBlock(
      id: 'source-${source.id}-${_draft.blocks.length}',
      type: NewsletterBlockType.source,
      text: source.excerpt,
      label: source.title,
      sourceId: source.id,
    );
    _selectedBlockId = block.id;
    _replaceDraft(_draft.copyWith(sources: sources, blocks: [..._draft.blocks, block]));
  }

  void _addBlock(NewsletterBlockType type) {
    if (!widget.capabilities.canEdit) return;
    final index = _draft.blocks.length;
    final block = NewsletterBlock(
      id: '${type.name}-$index-${_draft.revision}',
      type: type,
      text: switch (type) {
        NewsletterBlockType.heading => 'New section',
        NewsletterBlockType.button => 'Discover more',
        NewsletterBlockType.divider => '',
        NewsletterBlockType.source => 'Source excerpt',
        NewsletterBlockType.text => 'Start writing…',
      },
      label: type == NewsletterBlockType.button ? 'Button label' : null,
    );
    _selectedBlockId = block.id;
    _replaceDraft(_draft.copyWith(blocks: [..._draft.blocks, block]));
  }

  void _updateBlock(NewsletterBlock block) {
    _replaceDraft(
      _draft.copyWith(
        blocks: [
          for (final candidate in _draft.blocks)
            if (candidate.id == block.id) block else candidate,
        ],
      ),
    );
  }

  void _moveBlock(NewsletterBlock block, int delta) {
    if (block.isProtected) return;
    final current = _draft.blocks.indexWhere((candidate) => candidate.id == block.id);
    if (current < 0) return;
    final next = (current + delta).clamp(0, _draft.blocks.length - 1).toInt();
    if (next == current) return;
    final blocks = [..._draft.blocks];
    blocks.removeAt(current);
    blocks.insert(next, block);
    _replaceDraft(_draft.copyWith(blocks: blocks));
  }

  void _removeBlock(NewsletterBlock block) {
    if (block.isProtected) return;
    final blocks = _draft.blocks
        .where((candidate) => candidate.id != block.id)
        .toList(growable: false);
    _selectedBlockId = blocks.isEmpty ? null : blocks.first.id;
    _replaceDraft(_draft.copyWith(blocks: blocks));
  }

  Future<void> _openSelectedSource() async {
    if (_isEditingText) return;
    final source = _selectedSource;
    final open = widget.onOpenSource;
    if (source == null || open == null) return;
    try {
      await open(source.id);
    } catch (error) {
      if (mounted) setState(() => _lastError = 'Could not open source: $error');
    }
  }

  Future<void> _resolveAudience() async {
    final resolve = widget.onResolveAudience;
    if (resolve == null) return;
    setState(() {
      _operation = NewsletterOperationKind.validating;
      _lastError = null;
    });
    try {
      final audience = await resolve(_draft);
      if (!mounted) return;
      setState(() {
        _audience = audience;
        _operation = NewsletterOperationKind.idle;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Audience resolution failed: $error';
      });
    }
  }

  Future<void> _togglePreview() async {
    if (!widget.capabilities.canPreview) return;
    if (_showPreview) {
      setState(() => _showPreview = false);
      return;
    }
    final renderer = widget.onRenderPreview;
    if (renderer == null) {
      setState(() {
        _preview = _localPreview(NewsletterPreviewViewport.desktop);
        _showPreview = true;
      });
      return;
    }
    setState(() {
      _operation = NewsletterOperationKind.previewing;
      _lastError = null;
    });
    try {
      final preview = await renderer(_draft, NewsletterPreviewViewport.desktop);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _showPreview = true;
        _operation = NewsletterOperationKind.idle;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Preview failed: $error';
      });
    }
  }

  NewsletterPreview _localPreview(NewsletterPreviewViewport viewport) {
    final text = _draft.blocks
        .where((block) => block.type != NewsletterBlockType.divider)
        .map((block) => block.text)
        .where((value) => value.trim().isNotEmpty)
        .join('\n\n');
    return NewsletterPreview(
      revision: _draft.revision,
      viewport: viewport,
      subject: _draft.subject,
      preheader: _draft.preheader,
      plainText: text,
    );
  }

  Future<void> _sendTest() async {
    final send = widget.onSendTest;
    if (!widget.capabilities.canTest || send == null || _isBusy) return;
    setState(() {
      _operation = NewsletterOperationKind.testing;
      _lastError = null;
    });
    try {
      final receipt = await send(_draft);
      if (!mounted) return;
      setState(() {
        _testReceipt = receipt;
        _operation = NewsletterOperationKind.idle;
        _inspectorTab = _InspectorTab.send;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Test request failed: $error';
      });
    }
  }

  Future<void> _unschedule() async {
    final unschedule = widget.onUnschedule;
    if (!widget.capabilities.canUnschedule || unschedule == null || _isBusy) {
      return;
    }
    setState(() {
      _operation = NewsletterOperationKind.unscheduling;
      _lastError = null;
    });
    try {
      await unschedule(_draft.id);
      if (!mounted) return;
      setState(() => _operation = NewsletterOperationKind.idle);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Unschedule request failed: $error';
      });
    }
  }

  Future<void> _loadAnalytics() async {
    final load = widget.onLoadAnalytics;
    if (!widget.capabilities.canViewAnalytics || load == null || _isBusy) {
      return;
    }
    setState(() {
      _operation = NewsletterOperationKind.loadingAnalytics;
      _lastError = null;
    });
    try {
      final analytics = await load(_draft.id);
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _operation = NewsletterOperationKind.idle;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Analytics request failed: $error';
      });
    }
  }

  Future<void> _loadDeliveryStatus() async {
    final load = widget.onLoadDeliveryStatus;
    if (!widget.capabilities.canViewDeliveryStatus || load == null || _isBusy) {
      return;
    }
    setState(() {
      _operation = NewsletterOperationKind.loadingStatus;
      _lastError = null;
    });
    try {
      final deliveryStatus = await load(_draft.id);
      if (!mounted) return;
      setState(() {
        _deliveryStatus = deliveryStatus;
        _operation = NewsletterOperationKind.idle;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Delivery status request failed: $error';
      });
    }
  }

  List<NewsletterValidationIssue> _localIssues() {
    final issues = <NewsletterValidationIssue>[...widget.validationIssues];
    void add(NewsletterValidationIssue issue) {
      if (!issues.any((candidate) => candidate.id == issue.id)) {
        issues.add(issue);
      }
    }

    if (_draft.subject.trim().isEmpty) {
      add(
        const NewsletterValidationIssue(
          id: 'subject-empty',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Subject required',
          message: 'Add a subject before delivery review.',
          target: 'subject',
        ),
      );
    }
    final hasContent = _draft.blocks.any(
      (block) => block.type == NewsletterBlockType.divider || block.text.trim().isNotEmpty,
    );
    if (!hasContent) {
      add(
        const NewsletterValidationIssue(
          id: 'content-empty',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Content required',
          message: 'Add at least one meaningful content block.',
          target: 'content',
        ),
      );
    }
    if (_audience == null ||
        _audience?.isResolved != true ||
        (_audience?.eligibleCount ?? 0) == 0) {
      add(
        const NewsletterValidationIssue(
          id: 'audience-unresolved',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Audience unresolved',
          message: 'Resolve an eligible audience before scheduling or sending.',
          target: 'audience',
        ),
      );
    }
    if (widget.sender?.isVerified != true) {
      add(
        const NewsletterValidationIssue(
          id: 'sender-unverified',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Sender not verified',
          message: 'The host must verify the sender identity server-side.',
          target: 'sender',
        ),
      );
    }
    if (_draft.preheader.trim().isEmpty) {
      add(
        const NewsletterValidationIssue(
          id: 'preheader-empty',
          severity: NewsletterIssueSeverity.warning,
          title: 'Preheader missing',
          message: 'A concise preheader improves inbox context.',
          target: 'preheader',
        ),
      );
    }
    if (widget.design?.hasPlainTextAlternative == false) {
      add(
        const NewsletterValidationIssue(
          id: 'plain-text-missing',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Plain-text version missing',
          message: 'Provide an equivalent plain-text message before delivery.',
          target: 'design',
        ),
      );
    }
    final receipt = _testReceipt;
    if (receipt == null || receipt.draftRevision != _draft.revision) {
      add(
        const NewsletterValidationIssue(
          id: 'test-stale',
          severity: NewsletterIssueSeverity.warning,
          title: 'Current revision not tested',
          message: 'Send a test for this exact draft revision.',
          target: 'test',
        ),
      );
    }
    return issues;
  }

  Future<List<NewsletterValidationIssue>> _validate() async {
    final validate = widget.onValidateDraft;
    if (validate == null) return _localIssues();
    setState(() {
      _operation = NewsletterOperationKind.validating;
      _lastError = null;
    });
    try {
      final hostIssues = await validate(_draft, _audience);
      if (!mounted) return _localIssues();
      setState(() => _operation = NewsletterOperationKind.idle);
      final merged = [..._localIssues()];
      for (final issue in hostIssues) {
        final index = merged.indexWhere((candidate) => candidate.id == issue.id);
        if (index < 0) {
          merged.add(issue);
        } else {
          merged[index] = issue;
        }
      }
      return merged;
    } catch (error) {
      if (mounted) {
        setState(() {
          _operation = NewsletterOperationKind.failed;
          _lastError = 'Validation failed: $error';
        });
      }
      return [
        ..._localIssues(),
        NewsletterValidationIssue(
          id: 'host-validation-failed',
          severity: NewsletterIssueSeverity.blocker,
          title: 'Authoritative validation unavailable',
          message: '$error',
        ),
      ];
    }
  }

  Future<void> _openReview() async {
    if (_isBusy) return;
    var issues = await _validate();
    if (!mounted) return;
    setState(() => _compactPage = _CompactPage.review);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close newsletter review',
      transitionDuration: widget.style.reviewTransitionDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: _colors.surface,
            elevation: widget.style.reviewElevation,
            child: SafeArea(
              child: SizedBox(
                width: width < widget.style.compactBreakpoint
                    ? width
                    : widget.style.reviewPanelWidth,
                height: double.infinity,
                child: StatefulBuilder(
                  builder: (dialogContext, setReviewState) => _ReviewPanel(
                    draft: _draft,
                    audience: _audience,
                    sender: widget.sender,
                    schedule: widget.schedule,
                    testReceipt: _testReceipt,
                    issues: issues,
                    capabilities: widget.capabilities,
                    style: widget.style,
                    colors: _colors,
                    isBusy: _isBusy,
                    onResolveAudience: widget.onResolveAudience == null
                        ? null
                        : () async {
                            await _resolveAudience();
                            final refreshed = await _validate();
                            if (!dialogContext.mounted) return;
                            setReviewState(() => issues = refreshed);
                          },
                    onSendTest: widget.onSendTest == null
                        ? null
                        : () async {
                            await _sendTest();
                            final refreshed = await _validate();
                            if (!dialogContext.mounted) return;
                            setReviewState(() => issues = refreshed);
                          },
                    onSchedule:
                        widget.schedule == null || widget.onSchedule == null
                            ? null
                            : () => _confirmSchedule(dialogContext, issues),
                    onSend: widget.onSend == null
                        ? null
                        : () => _confirmSend(dialogContext, issues),
                    onClose: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
    _restoreWorkspaceFocus();
  }

  bool _hasBlockers(List<NewsletterValidationIssue> issues) {
    return issues.any(
      (issue) => issue.severity == NewsletterIssueSeverity.blocker,
    );
  }

  Future<void> _confirmSchedule(
    BuildContext reviewContext,
    List<NewsletterValidationIssue> issues,
  ) async {
    if (_hasBlockers(issues) || !widget.capabilities.canSchedule) return;
    final schedule = widget.schedule;
    final callback = widget.onSchedule;
    if (schedule == null || callback == null) return;
    final confirmed = await _confirmation(
      reviewContext,
      title: 'Schedule this newsletter?',
      message: 'The host will receive a request for ${_scheduleLabel(schedule)}.',
      action: 'Confirm schedule',
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(reviewContext);
    setState(() => _operation = NewsletterOperationKind.scheduling);
    try {
      await callback(_draft, schedule);
      if (mounted) setState(() => _operation = NewsletterOperationKind.idle);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Schedule request failed: $error';
      });
    }
  }

  Future<void> _confirmSend(
    BuildContext reviewContext,
    List<NewsletterValidationIssue> issues,
  ) async {
    if (_hasBlockers(issues) || !widget.capabilities.canSend) return;
    final callback = widget.onSend;
    if (callback == null) return;
    final confirmed = await _confirmation(
      reviewContext,
      title: 'Send this newsletter now?',
      message: 'This requests delivery to ${_audience?.eligibleCount ?? 0} eligible recipients.',
      action: 'Confirm send',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(reviewContext);
    setState(() => _operation = NewsletterOperationKind.sending);
    try {
      await callback(_draft);
      if (mounted) setState(() => _operation = NewsletterOperationKind.idle);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operation = NewsletterOperationKind.failed;
        _lastError = 'Send request failed: $error';
      });
    }
  }

  Future<bool> _confirmation(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: _colors.danger)
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _scheduleLabel(NewsletterSchedule schedule) {
    final value = schedule.sendAt;
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)} ${schedule.timezoneLabel}';
  }

  void _cycleZone(int delta) {
    if (_isEditingText) return;
    final zones = [_sourcesFocus, _editorFocus, _inspectorFocus, _actionsFocus];
    var current = zones.indexWhere((node) => node.hasFocus);
    if (current < 0) current = 0;
    final next = (current + delta) % zones.length;
    zones[next < 0 ? zones.length - 1 : next].requestFocus();
  }

  void _closeTransientSurface() {
    if (_showPreview) {
      setState(() => _showPreview = false);
      return;
    }
    if (_compactPage != _CompactPage.write) {
      setState(() => _compactPage = _CompactPage.write);
      return;
    }
    widget.onBack?.call();
  }

  void _setZoom(double value) {
    final next = value
        .clamp(widget.style.minimumZoom, widget.style.maximumZoom)
        .toDouble();
    if (next == _zoom) return;
    setState(() => _zoom = next);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        (!HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed)) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      final scroll = resolved as PointerScrollEvent;
      if (scroll.scrollDelta.dy == 0) return;
      _setZoom(
        _zoom + (scroll.scrollDelta.dy < 0 ? 1 : -1) * widget.style.zoomStep,
      );
    });
  }

  Future<void> _showKeyboardHelp() async {
    if (_isEditingText) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard shortcuts'),
        content: const SingleChildScrollView(
          child: Text(
            'J / K  Navigate sources\n'
            'X  Attach or detach source\n'
            'Enter  Open source\n'
            'F6 / Shift+F6  Change focus zone\n'
            'Ctrl/⌘+P  Preview\n'
            'Ctrl/⌘+Shift+T  Send test\n'
            'Ctrl/⌘+Enter  Open review\n'
            'Ctrl/⌘+0  Reset zoom\n'
            'Escape  Close current surface\n'
            'Tab / Shift+Tab  Move focus',
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    _restoreWorkspaceFocus();
  }

  void _restoreWorkspaceFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _workspaceFocus.requestFocus();
    });
  }

  Map<ShortcutActivator, Intent> get _shortcutMap {
    final result = <ShortcutActivator, Intent>{};
    void bind(List<ShortcutActivator> bindings, Intent intent) {
      for (final binding in bindings) {
        result[binding] = intent;
      }
    }

    bind(widget.shortcuts.next, const _NextIntent());
    bind(widget.shortcuts.previous, const _PreviousIntent());
    bind(widget.shortcuts.toggleSource, const _ToggleSourceIntent());
    bind(widget.shortcuts.open, const _OpenIntent());
    bind(widget.shortcuts.nextZone, const _NextZoneIntent());
    bind(widget.shortcuts.previousZone, const _PreviousZoneIntent());
    bind(widget.shortcuts.preview, const _PreviewIntent());
    bind(widget.shortcuts.sendTest, const _TestIntent());
    bind(widget.shortcuts.review, const _ReviewIntent());
    bind(widget.shortcuts.close, const _CloseIntent());
    bind(widget.shortcuts.resetZoom, const _ResetZoomIntent());
    bind(widget.shortcuts.help, const _HelpIntent());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcutMap,
      child: Actions(
        actions: {
          _NextIntent: _GuardedAction<_NextIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _moveSourceSelection(1),
          ),
          _PreviousIntent: _GuardedAction<_PreviousIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _moveSourceSelection(-1),
          ),
          _ToggleSourceIntent: _GuardedAction<_ToggleSourceIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _toggleSelectedSource(),
          ),
          _OpenIntent: _GuardedAction<_OpenIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _openSelectedSource(),
          ),
          _NextZoneIntent: _GuardedAction<_NextZoneIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _cycleZone(1),
          ),
          _PreviousZoneIntent: _GuardedAction<_PreviousZoneIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _cycleZone(-1),
          ),
          _PreviewIntent: CallbackAction<_PreviewIntent>(
            onInvoke: (_) => _togglePreview(),
          ),
          _TestIntent: CallbackAction<_TestIntent>(
            onInvoke: (_) => _sendTest(),
          ),
          _ReviewIntent: CallbackAction<_ReviewIntent>(
            onInvoke: (_) => _openReview(),
          ),
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) => _closeTransientSurface(),
          ),
          _ResetZoomIntent: CallbackAction<_ResetZoomIntent>(
            onInvoke: (_) => _setZoom(widget.style.initialZoom),
          ),
          _HelpIntent: _GuardedAction<_HelpIntent>(
            canInvoke: () => !_isEditingText,
            onInvoke: (_) => _showKeyboardHelp(),
          ),
        },
        child: Focus(
          focusNode: _workspaceFocus,
          autofocus: true,
          child: _ZoomViewport(
            zoom: _zoom,
            onPointerSignal: _handlePointerSignal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildWorkspace(constraints.maxWidth);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(double width) {
    final compact = width < widget.style.compactBreakpoint;
    final expanded = width >= widget.style.expandedBreakpoint;
    return ColoredBox(
      color: _colors.canvas,
      child: Column(
        children: [
          Focus(
            focusNode: _actionsFocus,
            child: _TopBar(
              draft: _draft,
              audience: _audience,
              operation: _operation,
              testReceipt: _testReceipt,
              compact: compact,
              showPreview: _showPreview,
              capabilities: widget.capabilities,
              style: widget.style,
              colors: _colors,
              onBack: widget.onBack,
              onPreview: _togglePreview,
              onTest: _sendTest,
              onReview: _openReview,
              actions: widget.topBarActions,
            ),
          ),
          if (_lastError != null)
            _ErrorBanner(
              message: _lastError!,
              style: widget.style,
              colors: _colors,
              onDismiss: () => setState(() => _lastError = null),
            ),
          Expanded(
            child: compact
                ? _buildCompact()
                : _buildRegular(expanded: expanded),
          ),
        ],
      ),
    );
  }

  Widget _buildRegular({required bool expanded}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expanded)
          SizedBox(width: widget.style.sourcePaneWidth, child: _buildSourcesPane())
        else
          _RailButton(
            tooltip: 'Open sources',
            icon: Icons.library_books_outlined,
            style: widget.style,
            colors: _colors,
            onPressed: () => _showPanelSheet(_buildSourcesPane()),
          ),
        VerticalDivider(
          width: widget.style.dividerThickness,
          thickness: widget.style.dividerThickness,
          color: _colors.divider,
        ),
        Expanded(child: _showPreview ? _buildPreview() : _buildEditor()),
        VerticalDivider(
          width: widget.style.dividerThickness,
          thickness: widget.style.dividerThickness,
          color: _colors.divider,
        ),
        if (expanded)
          SizedBox(
            width: widget.style.inspectorWidth,
            child: _buildInspector(),
          )
        else
          _RailButton(
            tooltip: 'Open inspector',
            icon: Icons.tune,
            style: widget.style,
            colors: _colors,
            onPressed: () => _showPanelSheet(_buildInspector()),
          ),
      ],
    );
  }

  Widget _buildCompact() {
    final body = switch (_compactPage) {
      _CompactPage.sources => _buildSourcesPane(),
      _CompactPage.write => _showPreview ? _buildPreview() : _buildEditor(),
      _CompactPage.review => _buildInspector(),
    };
    return Column(
      children: [
        Expanded(child: body),
        NavigationBar(
          height: widget.style.compactActionBarHeight,
          selectedIndex: _compactPage.index,
          onDestinationSelected: (index) {
            setState(() => _compactPage = _CompactPage.values[index]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              label: 'Sources',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              label: 'Write',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              label: 'Review',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourcesPane() {
    final used = _draft.usedSourceIds;
    return Focus(
      focusNode: _sourcesFocus,
      child: ColoredBox(
        color: _colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: widget.style.panelPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Sources', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text('${_draft.sources.length} attached'),
                ],
              ),
            ),
            Divider(
              height: widget.style.dividerThickness,
              thickness: widget.style.dividerThickness,
              color: _colors.divider,
            ),
            Expanded(
              child: widget.availableSources.isEmpty
                  ? _EmptyPanel(
                      icon: Icons.inbox_outlined,
                      title: 'No sources available',
                      message: 'The host has not supplied sources for this draft.',
                      style: widget.style,
                    )
                  : ListView.builder(
                      itemCount: widget.availableSources.length,
                      itemBuilder: (context, index) {
                        final source = widget.availableSources[index];
                        final attached = _draft.sources.any(
                          (candidate) => candidate.id == source.id,
                        );
                        final selected = source.id == _selectedSourceId;
                        final focusNode = _sourceFocusNodes.putIfAbsent(
                          source.id,
                          () => FocusNode(debugLabel: 'Source ${source.id}'),
                        );
                        final key = _sourceKeys.putIfAbsent(
                          source.id,
                          GlobalKey.new,
                        );
                        return _SourceRow(
                          key: key,
                          source: source,
                          selected: selected,
                          attached: attached,
                          used: used.contains(source.id),
                          focusNode: focusNode,
                          style: widget.style,
                          colors: _colors,
                          onSelected: () {
                            setState(() => _selectedSourceId = source.id);
                          },
                          onToggle: _toggleSelectedSource,
                          onInsert: _insertSelectedSource,
                          onOpen: widget.onOpenSource == null
                              ? null
                              : _openSelectedSource,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Focus(
      focusNode: _editorFocus,
      child: SingleChildScrollView(
        padding: widget.style.canvasPadding,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.style.emailCanvasWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _colors.surface,
                border: Border.all(
                  color: _colors.divider,
                  width: widget.style.dividerThickness,
                ),
                borderRadius: BorderRadius.circular(widget.style.panelRadius),
              ),
              child: Padding(
                padding: widget.style.canvasPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _subjectController,
                      focusNode: _subjectFocus,
                      enabled: widget.capabilities.canEdit,
                      textInputAction: TextInputAction.next,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'A clear reason to open this newsletter',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _replaceDraft(_draft.copyWith(subject: value));
                      },
                    ),
                    TextField(
                      controller: _preheaderController,
                      enabled: widget.capabilities.canEdit,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Preheader',
                        hintText: 'Inbox context that complements the subject',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _replaceDraft(_draft.copyWith(preheader: value));
                      },
                    ),
                    SizedBox(height: widget.style.largeGap),
                    if (_draft.blocks.isEmpty)
                      _EmptyPanel(
                        icon: Icons.edit_note_outlined,
                        title: 'Start with a block or source',
                        message: 'Add text below or insert a selected source from the source pane.',
                        style: widget.style,
                      )
                    else
                      for (var index = 0; index < _draft.blocks.length; index++)
                        Padding(
                          padding: EdgeInsets.only(bottom: widget.style.mediumGap),
                          child: _BlockCard(
                            block: _draft.blocks[index],
                            selected: _selectedBlockId == _draft.blocks[index].id,
                            canEdit: widget.capabilities.canEdit,
                            canMoveUp: index > 0,
                            canMoveDown: index < _draft.blocks.length - 1,
                            style: widget.style,
                            colors: _colors,
                            onSelected: () {
                              setState(() {
                                _selectedBlockId = _draft.blocks[index].id;
                                _inspectorTab = _InspectorTab.content;
                              });
                            },
                            onChanged: _updateBlock,
                            onMoveUp: () => _moveBlock(_draft.blocks[index], -1),
                            onMoveDown: () => _moveBlock(_draft.blocks[index], 1),
                            onDelete: () => _removeBlock(_draft.blocks[index]),
                            onOpenSource: widget.onOpenSource == null ||
                                    _draft.blocks[index].sourceId == null
                                ? null
                                : () async {
                                    await widget.onOpenSource!(
                                      _draft.blocks[index].sourceId!,
                                    );
                                  },
                          ),
                        ),
                    _AddBlockBar(
                      enabled: widget.capabilities.canEdit,
                      style: widget.style,
                      onAdd: _addBlock,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final preview = _preview ?? _localPreview(NewsletterPreviewViewport.desktop);
    return SingleChildScrollView(
      padding: widget.style.canvasPadding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.style.emailCanvasWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _colors.surface,
              border: Border.all(
                color: _colors.divider,
                width: widget.style.dividerThickness,
              ),
              borderRadius: BorderRadius.circular(widget.style.panelRadius),
            ),
            child: Padding(
              padding: widget.style.canvasPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined),
                      SizedBox(width: widget.style.smallGap),
                      const Expanded(child: Text('Preview')),
                      Chip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            widget.style.chipRadius,
                          ),
                        ),
                        label: Text(
                          preview.isApproximate
                              ? 'Approximate · revision ${preview.revision}'
                              : 'Rendered · revision ${preview.revision}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.style.extraLargeGap),
                  Text(preview.subject, style: Theme.of(context).textTheme.headlineSmall),
                  if (preview.preheader.isNotEmpty) ...[
                    SizedBox(height: widget.style.smallGap),
                    Text(
                      preview.preheader,
                      style: TextStyle(color: _colors.mutedForeground),
                    ),
                  ],
                  SizedBox(height: widget.style.extraLargeGap),
                  SelectableText(preview.plainText),
                  SizedBox(height: widget.style.extraLargeGap),
                  Text(
                    'This Flutter preview does not prove received-client rendering or deliverability.',
                    style: TextStyle(color: _colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspector() {
    return Focus(
      focusNode: _inspectorFocus,
      child: ColoredBox(
        color: _colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: widget.style.panelPadding,
              child: SegmentedButton<_InspectorTab>(
                segments: const [
                  ButtonSegment(value: _InspectorTab.content, label: Text('Content')),
                  ButtonSegment(value: _InspectorTab.design, label: Text('Design')),
                  ButtonSegment(value: _InspectorTab.audience, label: Text('Audience')),
                  ButtonSegment(value: _InspectorTab.send, label: Text('Send')),
                ],
                selected: {_inspectorTab},
                onSelectionChanged: (selection) {
                  setState(() => _inspectorTab = selection.first);
                },
                showSelectedIcon: false,
              ),
            ),
            Divider(
              height: widget.style.dividerThickness,
              thickness: widget.style.dividerThickness,
              color: _colors.divider,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: widget.style.panelPadding,
                child: switch (_inspectorTab) {
                  _InspectorTab.content => _ContentInspector(
                      block: _selectedBlock,
                      sourceCount: _draft.sources.length,
                      usedSourceCount: _draft.usedSourceIds.length,
                      style: widget.style,
                      colors: _colors,
                    ),
                  _InspectorTab.design => _DesignInspector(
                      design: widget.design,
                      style: widget.style,
                      colors: _colors,
                    ),
                  _InspectorTab.audience => _AudienceInspector(
                      audience: _audience,
                      canResolve: widget.onResolveAudience != null,
                      isBusy: _isBusy,
                      style: widget.style,
                      colors: _colors,
                      onResolve: _resolveAudience,
                    ),
                  _InspectorTab.send => _SendInspector(
                      sender: widget.sender,
                      schedule: widget.schedule,
                      testReceipt: _testReceipt,
                      deliveryStatus: _deliveryStatus,
                      analytics: _analytics,
                      currentRevision: _draft.revision,
                      canUnschedule: widget.schedule != null &&
                          widget.capabilities.canUnschedule &&
                          widget.onUnschedule != null,
                      canLoadAnalytics: widget.capabilities.canViewAnalytics &&
                          widget.onLoadAnalytics != null,
                      canLoadDeliveryStatus:
                          widget.capabilities.canViewDeliveryStatus &&
                          widget.onLoadDeliveryStatus != null,
                      isBusy: _isBusy,
                      style: widget.style,
                      colors: _colors,
                      onUnschedule: _unschedule,
                      onLoadAnalytics: _loadAnalytics,
                      onLoadDeliveryStatus: _loadDeliveryStatus,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPanelSheet(Widget child) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height *
              widget.style.panelSheetHeightFactor,
          child: child,
        ),
      ),
    );
    _restoreWorkspaceFocus();
  }
}

class _ZoomViewport extends StatelessWidget {
  const _ZoomViewport({
    required this.zoom,
    required this.onPointerSignal,
    required this.child,
  });

  final double zoom;
  final ValueChanged<PointerSignalEvent> onPointerSignal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: onPointerSignal,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
            return child;
          }
          return ClipRect(
            child: FittedBox(
              key: const ValueKey('newsletter-studio-zoom'),
              alignment: Alignment.topLeft,
              fit: BoxFit.fill,
              child: SizedBox(
                key: const ValueKey('newsletter-studio-zoom-content'),
                width: constraints.maxWidth / zoom,
                height: constraints.maxHeight / zoom,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.draft,
    required this.audience,
    required this.operation,
    required this.testReceipt,
    required this.compact,
    required this.showPreview,
    required this.capabilities,
    required this.style,
    required this.colors,
    required this.onBack,
    required this.onPreview,
    required this.onTest,
    required this.onReview,
    required this.actions,
  });

  final NewsletterDraft draft;
  final NewsletterAudienceSummary? audience;
  final NewsletterOperationKind operation;
  final NewsletterTestReceipt? testReceipt;
  final bool compact;
  final bool showPreview;
  final NewsletterStudioCapabilities capabilities;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback? onBack;
  final VoidCallback onPreview;
  final VoidCallback onTest;
  final VoidCallback onReview;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: style.topBarHeight,
      padding: EdgeInsets.symmetric(horizontal: style.largeGap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.divider,
            width: style.dividerThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back to newsletters',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _saveLabel(draft.saveState, operation),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (!compact && audience != null)
            Padding(
              padding: EdgeInsets.only(right: style.smallGap),
              child: Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(style.chipRadius),
                ),
                avatar: Icon(
                  Icons.group_outlined,
                  size: style.compactIconSize,
                ),
                label: Text('${audience!.eligibleCount} recipients'),
              ),
            ),
          IconButton(
            tooltip: showPreview ? 'Return to editor (Ctrl/Command+P)' : 'Preview (Ctrl/Command+P)',
            onPressed: capabilities.canPreview ? onPreview : null,
            icon: Icon(showPreview ? Icons.edit_outlined : Icons.visibility_outlined),
          ),
          if (!compact)
            TextButton.icon(
              onPressed: capabilities.canTest ? onTest : null,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                testReceipt?.draftRevision == draft.revision ? 'Tested' : 'Test',
              ),
            ),
          SizedBox(width: style.smallGap),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryActionSurface,
              foregroundColor: colors.primaryActionForeground,
            ),
            onPressed: onReview,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(compact ? 'Review' : 'Review and schedule'),
          ),
          ...actions,
        ],
      ),
    );
  }

  static String _saveLabel(
    NewsletterSaveState saveState,
    NewsletterOperationKind operation,
  ) {
    if (operation != NewsletterOperationKind.idle &&
        operation != NewsletterOperationKind.failed) {
      return switch (operation) {
        NewsletterOperationKind.validating => 'Validating…',
        NewsletterOperationKind.previewing => 'Rendering preview…',
        NewsletterOperationKind.testing => 'Sending test…',
        NewsletterOperationKind.scheduling => 'Scheduling…',
        NewsletterOperationKind.unscheduling => 'Removing schedule…',
        NewsletterOperationKind.sending => 'Sending…',
        NewsletterOperationKind.loadingStatus => 'Loading delivery status…',
        NewsletterOperationKind.loadingAnalytics => 'Loading analytics…',
        _ => 'Working…',
      };
    }
    return switch (saveState) {
      NewsletterSaveState.clean => 'No unsaved changes',
      NewsletterSaveState.dirty => 'Unsaved changes',
      NewsletterSaveState.saving => 'Saving…',
      NewsletterSaveState.saved => 'Saved',
      NewsletterSaveState.conflict => 'Save conflict',
      NewsletterSaveState.offline => 'Offline draft',
      NewsletterSaveState.failed => 'Save failed',
    };
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.selected,
    required this.attached,
    required this.used,
    required this.focusNode,
    required this.style,
    required this.colors,
    required this.onSelected,
    required this.onToggle,
    required this.onInsert,
    required this.onOpen,
    super.key,
  });

  final NewsletterSourceReference source;
  final bool selected;
  final bool attached;
  final bool used;
  final FocusNode focusNode;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onSelected;
  final VoidCallback onToggle;
  final VoidCallback onInsert;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      checked: attached,
      label: '${source.title}, ${attached ? 'attached' : 'not attached'}${used ? ', used' : ''}',
      child: Material(
        color: selected ? colors.selectedSurface : colors.surface,
        child: InkWell(
          focusNode: focusNode,
          onTap: onSelected,
          onDoubleTap: onInsert,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: style.largeGap,
              vertical: style.mediumGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: attached,
                  onChanged: (_) {
                    onSelected();
                    onToggle();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: style.smallGap / 2),
                      Text(
                        source.publisher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                      if (used)
                        Padding(
                          padding: EdgeInsets.only(top: style.smallGap),
                          child: const Text('Used in draft'),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Source actions',
                  onSelected: (value) {
                    onSelected();
                    if (value == 'insert') onInsert();
                    if (value == 'open') onOpen?.call();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'insert', child: Text('Insert excerpt')),
                    if (onOpen != null)
                      const PopupMenuItem(value: 'open', child: Text('Open source')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.selected,
    required this.canEdit,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.style,
    required this.colors,
    required this.onSelected,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onOpenSource,
  });

  final NewsletterBlock block;
  final bool selected;
  final bool canEdit;
  final bool canMoveUp;
  final bool canMoveDown;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onSelected;
  final ValueChanged<NewsletterBlock> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    if (block.type == NewsletterBlockType.divider) {
      return _frame(
        context,
        child: Row(
          children: [
            Expanded(
              child: Divider(
                thickness: style.dividerThickness,
                color: colors.divider,
              ),
            ),
            _actions(),
          ],
        ),
      );
    }
    return _frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_iconFor(block.type), size: style.compactIconSize),
              SizedBox(width: style.smallGap),
              Expanded(
                child: Text(
                  block.type.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (block.isProtected)
                Tooltip(
                  message: 'Protected block',
                  child: Icon(
                    Icons.lock_outline,
                    size: style.compactIconSize,
                  ),
                ),
              _actions(),
            ],
          ),
          SizedBox(height: style.smallGap),
          TextFormField(
            key: ValueKey('newsletter-block-${block.id}'),
            initialValue: block.text,
            enabled: canEdit && !block.isProtected,
            minLines: block.type == NewsletterBlockType.heading ? 1 : 2,
            maxLines: null,
            style: block.type == NewsletterBlockType.heading
                ? Theme.of(context).textTheme.titleLarge
                : null,
            decoration: InputDecoration(
              hintText: block.type == NewsletterBlockType.source
                  ? 'Source excerpt'
                  : 'Write content',
              border: InputBorder.none,
            ),
            onTap: onSelected,
            onChanged: (value) => onChanged(block.copyWith(text: value)),
          ),
          if (block.type == NewsletterBlockType.source && onOpenSource != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenSource,
                icon: Icon(
                  Icons.open_in_new,
                  size: style.compactIconSize,
                ),
                label: Text(block.label ?? 'Open source'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _frame(BuildContext context, {required Widget child}) {
    return Semantics(
      selected: selected,
      label: '${block.type.name} block${block.isProtected ? ', protected' : ''}',
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(style.blockRadius),
        child: AnimatedContainer(
          duration: style.controlTransitionDuration,
          padding: style.blockPadding,
          decoration: BoxDecoration(
            color: selected ? colors.selectedSurface : colors.subtleSurface,
            border: Border.all(
              color: selected ? colors.focus : colors.divider,
              width: selected ? style.focusWidth : style.dividerThickness,
            ),
            borderRadius: BorderRadius.circular(style.blockRadius),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Move block up',
          onPressed: canEdit && canMoveUp && !block.isProtected ? onMoveUp : null,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        IconButton(
          tooltip: 'Move block down',
          onPressed: canEdit && canMoveDown && !block.isProtected
              ? onMoveDown
              : null,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
        IconButton(
          tooltip: 'Delete block',
          onPressed: canEdit && !block.isProtected ? onDelete : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  static IconData _iconFor(NewsletterBlockType type) {
    return switch (type) {
      NewsletterBlockType.heading => Icons.title,
      NewsletterBlockType.text => Icons.notes,
      NewsletterBlockType.button => Icons.smart_button_outlined,
      NewsletterBlockType.divider => Icons.horizontal_rule,
      NewsletterBlockType.source => Icons.bookmark_outline,
    };
  }
}

class _AddBlockBar extends StatelessWidget {
  const _AddBlockBar({
    required this.enabled,
    required this.style,
    required this.onAdd,
  });

  final bool enabled;
  final NewsletterStudioStyle style;
  final ValueChanged<NewsletterBlockType> onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: style.smallGap,
      runSpacing: style.smallGap,
      children: [
        for (final type in const [
          NewsletterBlockType.heading,
          NewsletterBlockType.text,
          NewsletterBlockType.button,
          NewsletterBlockType.divider,
        ])
          ActionChip(
            avatar: Icon(
              _BlockCard._iconFor(type),
              size: style.compactIconSize,
            ),
            label: Text('Add ${type.name}'),
            onPressed: enabled ? () => onAdd(type) : null,
          ),
      ],
    );
  }
}

class _ContentInspector extends StatelessWidget {
  const _ContentInspector({
    required this.block,
    required this.sourceCount,
    required this.usedSourceCount,
    required this.style,
    required this.colors,
  });

  final NewsletterBlock? block;
  final int sourceCount;
  final int usedSourceCount;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Draft content', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: style.mediumGap),
        _SummaryRow(
          label: 'Attached sources',
          value: '$sourceCount',
          style: style,
        ),
        _SummaryRow(
          label: 'Used sources',
          value: '$usedSourceCount',
          style: style,
        ),
        SizedBox(height: style.extraLargeGap),
        Text('Selected block', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: style.smallGap),
        Text(
          block == null
              ? 'Select a block to inspect its role and provenance.'
              : '${block!.type.name}${block!.sourceId == null ? '' : ' · source-linked'}${block!.isProtected ? ' · protected' : ''}',
          style: TextStyle(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _DesignInspector extends StatelessWidget {
  const _DesignInspector({
    required this.design,
    required this.style,
    required this.colors,
  });

  final NewsletterDesignSummary? design;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;

  @override
  Widget build(BuildContext context) {
    final value = design;
    if (value == null) {
      return _EmptyPanel(
        icon: Icons.palette_outlined,
        title: 'Design supplied by the host',
        message: 'The host will provide the brand and email template summary.',
        style: style,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Email design', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: style.mediumGap),
        _SummaryRow(label: 'Template', value: value.templateName, style: style),
        _SummaryRow(label: 'Brand', value: value.brandName, style: style),
        _SummaryRow(label: 'Language', value: value.language, style: style),
        _SummaryRow(label: 'Direction', value: value.direction, style: style),
        _SummaryRow(
          label: 'Plain text',
          value: value.hasPlainTextAlternative ? 'Available' : 'Missing',
          style: style,
        ),
        SizedBox(height: style.largeGap),
        Text(
          'Final HTML, accessibility and client rendering remain server and delivery proof responsibilities.',
          style: TextStyle(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _AudienceInspector extends StatelessWidget {
  const _AudienceInspector({
    required this.audience,
    required this.canResolve,
    required this.isBusy,
    required this.style,
    required this.colors,
    required this.onResolve,
  });

  final NewsletterAudienceSummary? audience;
  final bool canResolve;
  final bool isBusy;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final value = audience;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Audience', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: style.mediumGap),
        if (value == null)
          Text(
            'No audience summary has been resolved.',
            style: TextStyle(color: colors.mutedForeground),
          )
        else ...[
          _SummaryRow(label: 'Segment', value: value.label, style: style),
          _SummaryRow(
            label: 'Eligible',
            value: '${value.eligibleCount}',
            style: style,
          ),
          _SummaryRow(
            label: 'Excluded',
            value: '${value.excludedCount}',
            style: style,
          ),
          _SummaryRow(
            label: 'State',
            value: value.isStale ? 'Stale' : value.isResolved ? 'Resolved' : 'Pending',
            style: style,
          ),
        ],
        SizedBox(height: style.largeGap),
        OutlinedButton.icon(
          onPressed: canResolve && !isBusy ? onResolve : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Resolve audience'),
        ),
        SizedBox(height: style.mediumGap),
        Text(
          'Recipient identities stay in the host and are not exposed by this public component.',
          style: TextStyle(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _SendInspector extends StatelessWidget {
  const _SendInspector({
    required this.sender,
    required this.schedule,
    required this.testReceipt,
    required this.deliveryStatus,
    required this.analytics,
    required this.currentRevision,
    required this.canUnschedule,
    required this.canLoadAnalytics,
    required this.canLoadDeliveryStatus,
    required this.isBusy,
    required this.style,
    required this.colors,
    required this.onUnschedule,
    required this.onLoadAnalytics,
    required this.onLoadDeliveryStatus,
  });

  final NewsletterSenderSummary? sender;
  final NewsletterSchedule? schedule;
  final NewsletterTestReceipt? testReceipt;
  final NewsletterDeliveryStatus? deliveryStatus;
  final Map<String, num>? analytics;
  final int currentRevision;
  final bool canUnschedule;
  final bool canLoadAnalytics;
  final bool canLoadDeliveryStatus;
  final bool isBusy;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onUnschedule;
  final VoidCallback onLoadAnalytics;
  final VoidCallback onLoadDeliveryStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: style.mediumGap),
        _SummaryRow(
          label: 'From',
          value: sender?.address ?? 'Not configured',
          style: style,
        ),
        _SummaryRow(
          label: 'Sender',
          value: sender?.isVerified == true ? 'Verified' : 'Not verified',
          style: style,
        ),
        _SummaryRow(
          label: 'Test',
          value: testReceipt == null
              ? 'Not sent'
              : testReceipt!.draftRevision == currentRevision
                  ? 'Current revision tested'
                  : 'Test is stale',
          style: style,
        ),
        _SummaryRow(
          label: 'Schedule',
          value: schedule == null
              ? 'Not selected'
              : '${schedule!.sendAt.toLocal()} · ${schedule!.timezoneLabel}',
          style: style,
        ),
        _SummaryRow(
          label: 'Delivery status',
          value: deliveryStatus?.state.name ?? 'Not loaded',
          style: style,
        ),
        if (deliveryStatus != null)
          Text(
            deliveryStatus!.message,
            style: TextStyle(color: colors.mutedForeground),
          ),
        if (canLoadDeliveryStatus)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isBusy ? null : onLoadDeliveryStatus,
              icon: const Icon(Icons.sync_outlined),
              label: Text(
                deliveryStatus == null
                    ? 'Load delivery status'
                    : 'Refresh delivery status',
              ),
            ),
          ),
        if (canUnschedule)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isBusy ? null : onUnschedule,
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Remove schedule'),
            ),
          ),
        if (analytics != null) ...[
          SizedBox(height: style.largeGap),
          Text('Analytics', style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: style.smallGap),
          for (final entry in analytics!.entries)
            _SummaryRow(
              label: entry.key,
              value: '${entry.value}',
              style: style,
            ),
        ],
        if (canLoadAnalytics)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isBusy ? null : onLoadAnalytics,
              icon: const Icon(Icons.query_stats_outlined),
              label: Text(analytics == null ? 'Load analytics' : 'Refresh analytics'),
            ),
          ),
        SizedBox(height: style.largeGap),
        Text(
          'The Review drawer is the only path to a schedule or send request.',
          style: TextStyle(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.draft,
    required this.audience,
    required this.sender,
    required this.schedule,
    required this.testReceipt,
    required this.issues,
    required this.capabilities,
    required this.style,
    required this.colors,
    required this.isBusy,
    required this.onResolveAudience,
    required this.onSendTest,
    required this.onSchedule,
    required this.onSend,
    required this.onClose,
  });

  final NewsletterDraft draft;
  final NewsletterAudienceSummary? audience;
  final NewsletterSenderSummary? sender;
  final NewsletterSchedule? schedule;
  final NewsletterTestReceipt? testReceipt;
  final List<NewsletterValidationIssue> issues;
  final NewsletterStudioCapabilities capabilities;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final bool isBusy;
  final VoidCallback? onResolveAudience;
  final VoidCallback? onSendTest;
  final VoidCallback? onSchedule;
  final VoidCallback? onSend;
  final VoidCallback onClose;

  bool get hasBlockers => issues.any(
        (issue) => issue.severity == NewsletterIssueSeverity.blocker,
      );

  @override
  Widget build(BuildContext context) {
    final blockers = issues
        .where((issue) => issue.severity == NewsletterIssueSeverity.blocker)
        .toList();
    final warnings = issues
        .where((issue) => issue.severity == NewsletterIssueSeverity.warning)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widgetPadding(style),
          child: Row(
            children: [
              Expanded(
                child: Text('Review', style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: 'Close review',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Divider(
          height: style.dividerThickness,
          thickness: style.dividerThickness,
          color: colors.divider,
        ),
        Expanded(
          child: ListView(
            padding: widgetPadding(style),
            children: [
              _ReviewSummaryCard(
                icon: Icons.subject,
                label: 'Subject',
                value: draft.subject.isEmpty ? 'Missing' : draft.subject,
                colors: colors,
              ),
              _ReviewSummaryCard(
                icon: Icons.group_outlined,
                label: 'Audience',
                value: audience == null
                    ? 'Unresolved'
                    : '${audience!.eligibleCount} eligible · ${audience!.excludedCount} excluded',
                colors: colors,
                action: onResolveAudience == null
                    ? null
                    : TextButton(onPressed: onResolveAudience, child: const Text('Refresh')),
              ),
              _ReviewSummaryCard(
                icon: Icons.alternate_email,
                label: 'Sender',
                value: sender == null
                    ? 'Not configured'
                    : '${sender!.name} · ${sender!.address}${sender!.isVerified ? '' : ' · unverified'}',
                colors: colors,
              ),
              _ReviewSummaryCard(
                icon: Icons.mark_email_read_outlined,
                label: 'Test',
                value: testReceipt == null
                    ? 'Not sent'
                    : testReceipt!.draftRevision == draft.revision
                        ? 'Current revision tested'
                        : 'Stale after draft changes',
                colors: colors,
                action: onSendTest == null
                    ? null
                    : TextButton(onPressed: onSendTest, child: const Text('Send test')),
              ),
              if (blockers.isNotEmpty) ...[
                SizedBox(height: style.largeGap),
                Text('Blocking issues', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: style.smallGap),
                for (final issue in blockers)
                  _IssueTile(issue: issue, colors: colors),
              ],
              if (warnings.isNotEmpty) ...[
                SizedBox(height: style.largeGap),
                Text('Warnings', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: style.smallGap),
                for (final issue in warnings)
                  _IssueTile(issue: issue, colors: colors),
              ],
            ],
          ),
        ),
        Divider(
          height: style.dividerThickness,
          thickness: style.dividerThickness,
          color: colors.divider,
        ),
        Padding(
          padding: widgetPadding(style),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasBlockers)
                Padding(
                  padding: EdgeInsets.only(bottom: style.smallGap),
                  child: Text(
                    'Resolve every blocking issue before delivery.',
                    style: TextStyle(color: colors.danger),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !hasBlockers &&
                              !isBusy &&
                              capabilities.canSchedule
                          ? onSchedule
                          : null,
                      child: Text(schedule == null ? 'Choose schedule' : 'Confirm schedule'),
                    ),
                  ),
                  SizedBox(width: style.smallGap),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primaryActionSurface,
                        foregroundColor: colors.primaryActionForeground,
                      ),
                      onPressed: !hasBlockers && !isBusy && capabilities.canSend
                          ? onSend
                          : null,
                      child: const Text('Send now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static EdgeInsetsGeometry widgetPadding(NewsletterStudioStyle style) {
    return style.panelPadding;
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final NewsletterStudioColors colors;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: action,
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue, required this.colors});

  final NewsletterValidationIssue issue;
  final NewsletterStudioColors colors;

  @override
  Widget build(BuildContext context) {
    final blocker = issue.severity == NewsletterIssueSeverity.blocker;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        blocker ? Icons.error_outline : Icons.warning_amber_outlined,
        color: blocker ? colors.danger : colors.warning,
      ),
      title: Text(issue.title),
      subtitle: Text(issue.message),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final String value;
  final NewsletterStudioStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: style.summaryRowVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          SizedBox(width: style.mediumGap),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.tooltip,
    required this.icon,
    required this.style,
    required this.colors,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.surface,
      child: SizedBox(
        width: style.railWidth,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: style.mediumGap),
            child: IconButton(
              tooltip: tooltip,
              onPressed: onPressed,
              icon: Icon(icon),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.style,
    required this.colors,
    required this.onDismiss,
  });

  final String message;
  final NewsletterStudioStyle style;
  final NewsletterStudioColors colors;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: colors.danger.withValues(
        alpha: style.errorSurfaceOpacity,
      ),
      leading: Icon(Icons.error_outline, color: colors.danger),
      content: Text(message),
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.style,
  });

  final IconData icon;
  final String title;
  final String message;
  final NewsletterStudioStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(style.extraLargeGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: style.emptyStateIconSize),
            SizedBox(height: style.mediumGap),
            Text(title, textAlign: TextAlign.center),
            SizedBox(height: style.smallGap),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

enum _InspectorTab { content, design, audience, send }

enum _CompactPage { sources, write, review }

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _ToggleSourceIntent extends Intent {
  const _ToggleSourceIntent();
}

class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _NextZoneIntent extends Intent {
  const _NextZoneIntent();
}

class _PreviousZoneIntent extends Intent {
  const _PreviousZoneIntent();
}

class _PreviewIntent extends Intent {
  const _PreviewIntent();
}

class _TestIntent extends Intent {
  const _TestIntent();
}

class _ReviewIntent extends Intent {
  const _ReviewIntent();
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

class _ResetZoomIntent extends Intent {
  const _ResetZoomIntent();
}

class _HelpIntent extends Intent {
  const _HelpIntent();
}

class _GuardedAction<T extends Intent> extends Action<T> {
  _GuardedAction({required this.canInvoke, required this.onInvoke});

  final bool Function() canInvoke;
  final Object? Function(T intent) onInvoke;

  @override
  bool isEnabled(T intent) => canInvoke();

  @override
  Object? invoke(T intent) => onInvoke(intent);
}
