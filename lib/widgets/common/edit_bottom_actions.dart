import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Bottom action bar for EditScreen
class EditBottomActions extends StatelessWidget {
  final VoidCallback onAddMore;
  final VoidCallback onSave;

  const EditBottomActions({
    super.key,
    required this.onAddMore,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add More button (outline)
          Expanded(
            child: ShadButton.outline(
              onPressed: onAddMore,
              height: 48,
              leading: const Icon(LucideIcons.imagePlus, size: 18),
              child: const Text('Add More'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Save button (primary)
          Expanded(
            child: ShadButton(
              onPressed: onSave,
              height: 48,
              leading: const Icon(LucideIcons.check, size: 18),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
