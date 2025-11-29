import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/context_menu_item.dart';
import '../common/context_menu_sheet.dart';
import '../common/document_tag.dart';

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
  final VoidCallback? onTag;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

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
    this.onTag,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemedColors.of(context);

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
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          onTap: isSelectionMode ? onSelect : onTap,
          onLongPress: isSelectionMode ? null : () => _showContextMenu(context),
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
                        color: colors.surface,
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: _buildThumbnail(context),
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
                                  fontWeight: AppFontWeight.semiBold,
                                  letterSpacing: -0.2,
                                  color: colors.textPrimary,
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
                              color: colors.textSecondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${document.imagePaths.length} ${document.imagePaths.length == 1 ? 'common.page'.tr() : 'common.pagesLower'.tr()}',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (document.hasTag) ...[
                          const SizedBox(height: AppSpacing.xs),
                          DocumentTag(
                            text: document.tagText!,
                            color: document.tagColor ?? 0xFF6B7280,
                            size: DocumentTagSize.small,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Selection indicator with animation
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelectionMode ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelectionMode ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          isSelected
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          key: ValueKey(isSelected),
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
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
          label: 'viewer.downloadPdf'.tr(),
          onTap: () {
            Navigator.pop(context);
            onSavePdf?.call();
          },
        ),
      if (onShare != null)
        ContextMenuItem(
          icon: LucideIcons.share2,
          label: 'viewer.sharePdf'.tr(),
          onTap: () {
            Navigator.pop(context);
            onShare?.call();
          },
        ),
      if (onSaveZip != null)
        ContextMenuItem(
          icon: LucideIcons.folderArchive,
          label: 'viewer.downloadAsZip'.tr(),
          onTap: () {
            Navigator.pop(context);
            onSaveZip?.call();
          },
        ),
      if (onSaveImages != null)
        ContextMenuItem(
          icon: LucideIcons.images,
          label: 'viewer.downloadImages'.tr(),
          onTap: () {
            Navigator.pop(context);
            onSaveImages?.call();
          },
        ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: 'common.export'.tr(),
      items: items,
    );
  }

  void _showContextMenu(BuildContext context) {
    final items = <ContextMenuItem>[
      if (onEditScan != null)
        ContextMenuItem(
          icon: LucideIcons.filePen,
          label: 'viewer.editScan'.tr(),
          onTap: () {
            Navigator.pop(context);
            onEditScan?.call();
          },
        ),
      if (onEdit != null)
        ContextMenuItem(
          icon: LucideIcons.pencil,
          label: 'common.rename'.tr(),
          onTap: () {
            Navigator.pop(context);
            onEdit?.call();
          },
        ),
      if (onTag != null)
        ContextMenuItem(
          icon: LucideIcons.tag,
          label: document.hasTag
              ? 'dialogs.editTag'.tr()
              : 'dialogs.addTag'.tr(),
          onTap: () {
            Navigator.pop(context);
            onTag?.call();
          },
        ),
      if (onQualityChange != null)
        ContextMenuItem(
          icon: LucideIcons.settings2,
          label: 'viewer.pdfOptions'.tr(),
          onTap: () {
            Navigator.pop(context);
            onQualityChange?.call();
          },
        ),
      if (onDelete != null)
        ContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'common.delete'.tr(),
          color: ThemedColors.of(context).error,
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

  Widget _buildThumbnail(BuildContext context) {
    // If document has images, show the first image as thumbnail
    if (document.imagePaths.isNotEmpty) {
      final firstImagePath = document.imagePaths.first;
      final imageFile = File(firstImagePath);

      // Check if file exists
      if (imageFile.existsSync()) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pixelRatio = MediaQuery.devicePixelRatioOf(context);
            return Image.file(
              imageFile,
              fit: BoxFit.cover,
              cacheWidth: (constraints.maxWidth * pixelRatio).round(),
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(context);
              },
            );
          },
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colors = ThemedColors.of(context);

    return Container(
      color: colors.background,
      child: Center(
        child: Icon(
          LucideIcons.fileText,
          size: 40,
          color: colors.textHint,
        ),
      ),
    );
  }
}
