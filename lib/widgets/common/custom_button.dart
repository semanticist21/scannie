import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Custom icon button with consistent styling
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

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
