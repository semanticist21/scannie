import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Bottom action bar for EditScreen
class EditBottomActions extends StatelessWidget {
  final VoidCallback onAddScan;
  final VoidCallback onAddPhoto;
  final VoidCallback onSave;

  const EditBottomActions({
    super.key,
    required this.onAddScan,
    required this.onAddPhoto,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    // Get safe area bottom padding for iOS/Android home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + bottomPadding, // Add safe area padding
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Add Scan button (outline)
          Expanded(
            child: ShadButton.outline(
              onPressed: onAddScan,
              height: 48,
              leading: const Icon(LucideIcons.scan, size: 18),
              child: Text('common.scan'.tr()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Add Photo button (outline)
          Expanded(
            child: ShadButton.outline(
              onPressed: onAddPhoto,
              height: 48,
              leading: const Icon(LucideIcons.image, size: 18),
              child: Text('common.photo'.tr()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Save button (primary)
          Expanded(
            child: ShadButton(
              onPressed: onSave,
              height: 48,
              leading: const Icon(LucideIcons.check, size: 18),
              child: Text('common.save'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
