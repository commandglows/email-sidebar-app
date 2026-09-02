import 'package:flutter/foundation.dart';

import 'source_sidebar_item.dart';

@immutable
class SourceAccount {
  const SourceAccount({required this.id, required this.label})
    : assert(id != ''),
      assert(label != '');

  final String id;
  final String label;
}

@immutable
class SourceProjectDestination {
  const SourceProjectDestination({required this.id, required this.label})
    : assert(id != ''),
      assert(label != '');

  final String id;
  final String label;
}

typedef SourceAccountCallback = Future<void> Function(SourceAccount account);
typedef SourceSummaryCallback = Future<void> Function(SourceSidebarItem item);
typedef SourceDistributionCallback =
    Future<void> Function(
      SourceSidebarItem item,
      List<SourceProjectDestination> destinations,
    );
typedef SourceActionErrorCallback = void Function(Object error);
