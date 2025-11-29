import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Image tile widget for displaying a page in edit screen grid
class ImageTile extends StatelessWidget {
  final int index;
  final String imagePath;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ImageTile({
    super.key,
    required this.index,
    required this.imagePath,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemedColors.of(context);

    return Container(
      key: ValueKey(imagePath),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // Image (tappable)
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pixelRatio = MediaQuery.devicePixelRatioOf(context);
                  return Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: (constraints.maxWidth * pixelRatio).round(),
                  );
                },
              ),
            ),
          ),

          // Page number badge
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.shadowDark,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${index + 1}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.darkTextPrimary,
                  fontWeight: AppFontWeight.medium,
                ),
              ),
            ),
          ),

          // Delete button
          Positioned(
            top: -10,
            right: -10,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Icon(
                  LucideIcons.x,
                  color: colors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
