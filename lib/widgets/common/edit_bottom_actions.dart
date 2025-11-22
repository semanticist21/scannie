import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Bottom action bar for EditScreen
class EditBottomActions extends StatelessWidget {
  final VoidCallback onAddMore;
  final VoidCallback onSavePdf;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const EditBottomActions({
    super.key,
    required this.onAddMore,
    required this.onSavePdf,
    required this.onShare,
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
        top: AppSpacing.lg,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Icon buttons for quick actions
          Row(
            children: [
              // Add More Images
              Expanded(
                child: _IconActionButton(
                  icon: LucideIcons.imagePlus,
                  label: 'Add More',
                  onPressed: onAddMore,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Save PDF
              Expanded(
                child: _IconActionButton(
                  icon: LucideIcons.fileText,
                  label: 'Save PDF',
                  onPressed: onSavePdf,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Share PDF
              Expanded(
                child: _IconActionButton(
                  icon: LucideIcons.share2,
                  label: 'Share',
                  onPressed: onShare,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 2: Primary action - Save to Gallery
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: onSave,
              leading: const Icon(LucideIcons.save, size: 18),
              child: const Text('Save to Gallery'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon button for footer actions
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      onPressed: onPressed,
      height: 64,
      width: double.infinity, // Constrain width to parent
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
