import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Document info header widget
class DocumentInfoHeader extends StatelessWidget {
  final ScanDocument document;
  final File? cachedPdfFile;

  const DocumentInfoHeader({
    super.key,
    required this.document,
    this.cachedPdfFile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemedColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Document icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.smd),
              decoration: BoxDecoration(
                color: colors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                LucideIcons.fileText,
                color: colors.textHint,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document name
                  Text(
                    document.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Tag badge (below title)
                  if (document.hasTag) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: Color(document.tagColor!).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          document.tagText!,
                          style: AppTextStyles.caption.copyWith(
                            color: Color(document.tagColor!),
                            fontWeight: AppFontWeight.medium,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _buildInfoText(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInfoText() {
    final pageText =
        '${document.imagePaths.length} ${document.imagePaths.length == 1 ? 'page' : 'pages'}';
    final dateText = _formatDateShort(document.createdAt);

    // Only show actual PDF size when available
    if (cachedPdfFile != null && cachedPdfFile!.existsSync()) {
      final sizeText = _formatFileSize(cachedPdfFile!.lengthSync());
      return '$pageText · $dateText · $sizeText';
    }

    return '$pageText · $dateText';
  }

  String _formatDateShort(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
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
