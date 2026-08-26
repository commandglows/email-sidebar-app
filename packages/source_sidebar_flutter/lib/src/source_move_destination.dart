import 'package:flutter/foundation.dart';

import 'source_sidebar_item.dart';

@immutable
class SourceMoveDestination {
  const SourceMoveDestination({required this.id, required this.label})
    : assert(id != ''),
      assert(label != '');

  final String id;
  final String label;
}

typedef SourceMoveCallback =
    Future<void> Function(
      SourceSidebarItem item,
      SourceMoveDestination destination,
    );
