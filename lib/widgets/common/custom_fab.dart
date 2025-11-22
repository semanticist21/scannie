import 'package:flutter/material.dart';

/// Custom circular FAB-style button
class CustomFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isLarge;

  const CustomFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        child: Icon(icon, size: isLarge ? 32 : 24),
      ),
    );
  }
}
