import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Size variants for DocumentTag
enum DocumentTagSize {
  small, // For grid cards
  medium, // For list cards and viewer
}

/// Common tag widget for displaying document tags consistently
/// Used in gallery cards and document viewer
class DocumentTag extends StatelessWidget {
  final String text;
  final int color;
  final DocumentTagSize size;

  const DocumentTag({
    super.key,
    required this.text,
    required this.color,
    this.size = DocumentTagSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(color);
    final textColor = _getContrastColor(backgroundColor);

    final fontSize =
        size == DocumentTagSize.small ? AppFontSize.xxs : AppFontSize.xs;

    final verticalPadding = size == DocumentTagSize.small ? 2.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Transform.translate(
        offset: Offset(0, Platform.isAndroid ? -1 : 0),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: AppFontWeight.medium,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  /// Get contrasting text color (black or white) based on background luminance
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? AppColors.black : AppColors.white;
  }
}
