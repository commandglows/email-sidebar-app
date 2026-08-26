import 'package:flutter/foundation.dart';

enum SourceProcessingState { idle, processing, processed, failed }

@immutable
class SourceSidebarItem {
  const SourceSidebarItem({
    required this.id,
    required this.title,
    required this.authorOrPublisher,
    required this.summary,
    required this.publishedAt,
    required this.sourceType,
    required this.content,
    this.tags = const <String>[],
    this.seen = false,
    this.location = 'new',
    this.processingState = SourceProcessingState.idle,
    this.canonicalExternalUrl,
  });

  final String id;
  final String title;
  final String authorOrPublisher;
  final String summary;
  final DateTime publishedAt;
  final String sourceType;
  final String content;
  final List<String> tags;
  final bool seen;
  final String location;
  final SourceProcessingState processingState;
  final Uri? canonicalExternalUrl;
}

typedef SourceItemCallback = Future<void> Function(SourceSidebarItem item);
typedef SourceItemsCallback =
    Future<void> Function(List<SourceSidebarItem> items);
