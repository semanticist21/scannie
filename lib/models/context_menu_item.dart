import 'package:flutter/material.dart';

/// Menu item configuration for ContextMenuSheet
class ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
