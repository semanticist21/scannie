import 'package:flutter/material.dart';
import '../../models/context_menu_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Reusable bottom sheet context menu with consistent styling
class ContextMenuSheet extends StatelessWidget {
  final String title;
  final List<ContextMenuItem> items;

  const ContextMenuSheet({
    super.key,
    required this.title,
    required this.items,
  });

  /// Show the context menu as a modal bottom sheet
  static void show({
    required BuildContext context,
    required String title,
    required List<ContextMenuItem> items,
  }) {
    final colors = ThemedColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => ContextMenuSheet(
        title: title,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemedColors.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppFontWeight.semiBold,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(height: 1, color: colors.border),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: items.map((item) => _buildMenuItem(context, item)).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ContextMenuItem item) {
    final colors = ThemedColors.of(context);
    final itemColor = item.color ?? colors.textPrimary;
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: itemColor),
            const SizedBox(width: AppSpacing.md),
            Text(
              item.label,
              style: AppTextStyles.bodyMedium.copyWith(color: itemColor),
            ),
          ],
        ),
      ),
    );
  }
}
