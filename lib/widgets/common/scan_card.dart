import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Card widget for displaying a scanned document
class ScanCard extends StatelessWidget {
  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onEditScan;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const ScanCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onEdit,
    this.onEditScan,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final pageCount = document.imagePaths.length;
    final formattedDate = _formatDate(document.createdAt);

    // Wrap card with Dismissible for swipe-to-delete
    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.textHint.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Modern Thumbnail with shadow
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildThumbnail(),
              ),
              const SizedBox(width: AppSpacing.md),

              // Document info with better typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
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
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
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

              // Single action button (more menu)
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
    );

    // Add Dismissible for swipe-to-delete
    if (onDelete != null) {
      return Dismissible(
        key: Key(document.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete Document'),
              content: Text('Are you sure you want to delete "${document.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => onDelete?.call(),
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
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
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
                document.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),

            // Actions
            if (onEditScan != null)
              ListTile(
                leading: const Icon(Icons.edit_document, color: AppColors.primary),
                title: const Text('Edit Scan'),
                subtitle: const Text('Add, delete, or reorder pages'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEditScan?.call();
                },
              ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit?.call();
                },
              ),
            if (onShare != null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
                title: const Text('Download PDF'),
                subtitle: const Text('Export and share as PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onShare?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete?.call();
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
    if (document.imagePaths.isNotEmpty) {
      final firstImagePath = document.imagePaths.first;
      final imageFile = File(firstImagePath);

      // Check if file exists
      if (imageFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 32,
              );
            },
          ),
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return const Icon(
      Icons.description_outlined,
      color: AppColors.primary,
      size: 32,
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
