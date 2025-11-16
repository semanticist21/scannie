import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Card widget for displaying a scanned document
class ScanCard extends StatefulWidget {
  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onEditScan;
  final VoidCallback? onDelete;
  final VoidCallback? onSavePdf;
  final VoidCallback? onShare;

  const ScanCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onEdit,
    this.onEditScan,
    this.onDelete,
    this.onSavePdf,
    this.onShare,
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

    // Material 3 card design with subtle scale animation
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card.filled(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Thumbnail with subtle elevation
                Container(
                  width: 75,
                  height: 95,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$pageCount ${pageCount == 1 ? 'page' : 'pages'}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '•',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formattedDate,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showContextMenu(context),
                  color: AppColors.textSecondary,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                widget.document.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),

            // Actions
            if (widget.onEditScan != null)
              ListTile(
                leading: const Icon(Icons.edit_document, color: AppColors.primary),
                title: const Text('Edit Scan'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onEditScan?.call();
                },
              ),
            if (widget.onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onEdit?.call();
                },
              ),
            if (widget.onSavePdf != null)
              ListTile(
                leading: const Icon(Icons.download, color: AppColors.accent),
                title: const Text('Save PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onSavePdf?.call();
                },
              ),
            if (widget.onShare != null)
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.accent),
                title: const Text('Share PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onShare?.call();
                },
              ),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onDelete?.call();
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
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
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            );
          },
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      child: const Icon(
        Icons.description_outlined,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
