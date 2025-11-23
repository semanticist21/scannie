import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/context_menu_item.dart';
import 'context_menu_sheet.dart';

/// Card widget for displaying a scanned document
class ScanCard extends StatefulWidget {
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const ScanCard({
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
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<ScanCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.document.imagePaths.length;
    final formattedDate = _formatDate(widget.document.createdAt);

    // Material 3 card design with subtle scale animation and swipe-to-delete
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
        key: ValueKey(widget.document.id),
        direction: DismissDirection.endToStart, // Swipe left only
        confirmDismiss: (direction) async {
          // Don't dismiss automatically, just show delete button
          return false;
        },
        background: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: GestureDetector(
            onTap: () {
              // Trigger delete callback
              widget.onDelete?.call();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.darkOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: AppColors.darkTextPrimary,
                size: 28,
              ),
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: InkWell(
            onTap: widget.isSelectionMode ? widget.onSelect : widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onLongPress: widget.isSelectionMode ? null : () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Selection checkbox with animation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: widget.isSelectionMode
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  widget.isSelected
                                      ? LucideIcons.circleCheck
                                      : LucideIcons.circle,
                                  key: ValueKey(widget.isSelected),
                                  size: 24,
                                  color: widget.isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Thumbnail
                  Container(
                    width: 56,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      color: AppColors.divider,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: _buildThumbnail(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Document info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.document.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$pageCount ${pageCount == 1 ? 'common.page'.tr() : 'common.pagesLower'.tr()} · $formattedDate',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.document.imagePaths.isNotEmpty)
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(LucideIcons.download, size: 20),
                            onPressed: () => _showExportOptions(context),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
                          onPressed: () => _showContextMenu(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final items = <ContextMenuItem>[
      if (widget.onSavePdf != null)
        ContextMenuItem(
          icon: LucideIcons.download,
          label: 'viewer.downloadPdf'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onSavePdf?.call();
          },
        ),
      if (widget.onShare != null)
        ContextMenuItem(
          icon: LucideIcons.share2,
          label: 'viewer.sharePdf'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onShare?.call();
          },
        ),
      if (widget.onSaveZip != null)
        ContextMenuItem(
          icon: LucideIcons.folderArchive,
          label: 'viewer.downloadAsZip'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onSaveZip?.call();
          },
        ),
      if (widget.onSaveImages != null)
        ContextMenuItem(
          icon: LucideIcons.images,
          label: 'viewer.downloadImages'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onSaveImages?.call();
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
      if (widget.onEditScan != null)
        ContextMenuItem(
          icon: LucideIcons.filePen,
          label: 'viewer.editScan'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onEditScan?.call();
          },
        ),
      if (widget.onEdit != null)
        ContextMenuItem(
          icon: LucideIcons.pencil,
          label: 'common.rename'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onEdit?.call();
          },
        ),
      if (widget.onQualityChange != null)
        ContextMenuItem(
          icon: LucideIcons.settings2,
          label: 'viewer.pdfOptions'.tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onQualityChange?.call();
          },
        ),
      if (widget.onDelete != null)
        ContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'common.delete'.tr(),
          color: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            widget.onDelete?.call();
          },
        ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: widget.document.name,
      items: items,
    );
  }

  Widget _buildThumbnail() {
    // If document has images, show the first image as thumbnail
    if (widget.document.imagePaths.isNotEmpty) {
      final firstImagePath = widget.document.imagePaths.first;
      final imageFile = File(firstImagePath);

      // Check if file exists
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          cacheWidth: 250,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.background,
              child: const Center(
                child: Icon(
                  LucideIcons.fileText,
                  color: AppColors.textHint,
                  size: 28,
                ),
              ),
            );
          },
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          LucideIcons.fileText,
          color: AppColors.textHint,
          size: 28,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }
}
