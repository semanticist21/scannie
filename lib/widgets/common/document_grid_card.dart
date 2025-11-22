import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/context_menu_item.dart';
import 'context_menu_sheet.dart';

/// Grid card for displaying a document in grid view
class DocumentGridCard extends StatelessWidget {
  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onEditScan;
  final VoidCallback? onDelete;
  final VoidCallback? onSavePdf;
  final VoidCallback? onShare;
  final VoidCallback? onSaveZip;
  final VoidCallback? onSaveImages;
  final VoidCallback? onQualityChange;

  const DocumentGridCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onEdit,
    this.onEditScan,
    this.onDelete,
    this.onSavePdf,
    this.onShare,
    this.onSaveZip,
    this.onSaveImages,
    this.onQualityChange,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail with subtle elevation
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: AppColors.surface,
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: _buildThumbnail(),
                      ),
                    ),
                  ),

                  // Info section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                document.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // More button
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: const Icon(LucideIcons.ellipsisVertical),
                                onPressed: () => _showContextMenu(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.file,
                              size: 14,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${document.imagePaths.length} ${document.imagePaths.length == 1 ? 'page' : 'pages'}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Download button overlay
              if (document.imagePaths.isNotEmpty)
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.overlay,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(LucideIcons.download, color: AppColors.darkTextPrimary),
                      onPressed: () => _showExportOptions(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final items = <ContextMenuItem>[
      if (onSavePdf != null)
        ContextMenuItem(
          icon: LucideIcons.download,
          label: 'Download PDF',
          onTap: () {
            Navigator.pop(context);
            onSavePdf?.call();
          },
        ),
      if (onShare != null)
        ContextMenuItem(
          icon: LucideIcons.share2,
          label: 'Share PDF',
          onTap: () {
            Navigator.pop(context);
            onShare?.call();
          },
        ),
      if (onSaveZip != null)
        ContextMenuItem(
          icon: LucideIcons.folderArchive,
          label: 'Download as ZIP',
          onTap: () {
            Navigator.pop(context);
            onSaveZip?.call();
          },
        ),
      if (onSaveImages != null)
        ContextMenuItem(
          icon: LucideIcons.images,
          label: 'Download Images',
          onTap: () {
            Navigator.pop(context);
            onSaveImages?.call();
          },
        ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: 'Export',
      items: items,
    );
  }

  void _showContextMenu(BuildContext context) {
    final items = <ContextMenuItem>[
      if (onEditScan != null)
        ContextMenuItem(
          icon: LucideIcons.filePen,
          label: 'Edit Scan',
          onTap: () {
            Navigator.pop(context);
            onEditScan?.call();
          },
        ),
      if (onEdit != null)
        ContextMenuItem(
          icon: LucideIcons.pencil,
          label: 'Rename',
          onTap: () {
            Navigator.pop(context);
            onEdit?.call();
          },
        ),
      if (onQualityChange != null)
        ContextMenuItem(
          icon: LucideIcons.settings2,
          label: 'PDF Quality (${document.pdfQuality.displayName})',
          onTap: () {
            Navigator.pop(context);
            onQualityChange?.call();
          },
        ),
      if (onDelete != null)
        ContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'Delete',
          color: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            onDelete?.call();
          },
        ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: document.name,
      items: items,
    );
  }

  Widget _buildThumbnail() {
    // If document has images, show the first image as thumbnail
    if (document.imagePaths.isNotEmpty) {
      final firstImagePath = document.imagePaths.first;
      final imageFile = File(firstImagePath);

      // Check if file exists
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          cacheWidth: 450,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          LucideIcons.fileText,
          size: 40,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
