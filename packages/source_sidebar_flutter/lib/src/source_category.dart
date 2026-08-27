import 'package:flutter/material.dart';

/// Host-owned visual definition for a category referenced by
/// `SourceSidebarItem.tags`.
///
/// The sidebar keeps accepting tag identifiers on source items for backwards
/// compatibility. Matching identifiers are presented with this category's
/// name, color, and icon.
@immutable
class SourceCategory {
  const SourceCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  }) : assert(id != ''),
       assert(name != '');

  final String id;
  final String name;
  final Color color;
  final IconData icon;
}
