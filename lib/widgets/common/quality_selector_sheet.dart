import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Bottom sheet for selecting PDF quality
class QualitySelectorSheet extends StatelessWidget {
  final PdfQuality currentQuality;
  final int totalFileSize;
  final ValueChanged<PdfQuality> onQualitySelected;

  const QualitySelectorSheet({
    super.key,
    required this.currentQuality,
    required this.totalFileSize,
    required this.onQualitySelected,
  });

  /// Show the quality selector bottom sheet
  static void show({
    required BuildContext context,
    required PdfQuality currentQuality,
    required int totalFileSize,
    required ValueChanged<PdfQuality> onQualitySelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => QualitySelectorSheet(
        currentQuality: currentQuality,
        totalFileSize: totalFileSize,
        onQualitySelected: (quality) {
          Navigator.pop(sheetContext);
          onQualitySelected(quality);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.border,
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
              'PDF Quality',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Quality options
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: PdfQuality.values.map((quality) {
                final isSelected = quality == currentQuality;
                final estimatedSize =
                    (totalFileSize * quality.compressionRatio).round();

                return InkWell(
                  onTap: () => onQualitySelected(quality),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            quality.displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '~${_formatFileSize(estimatedSize)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
