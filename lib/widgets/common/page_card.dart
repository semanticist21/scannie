import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Page card widget for displaying a document page
class PageCard extends StatelessWidget {
  final int index;
  final File imageFile;
  final bool isListView;
  final VoidCallback onTap;

  const PageCard({
    super.key,
    required this.index,
    required this.imageFile,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    final imageWidget = imageFile.existsSync()
        ? Image.file(
            imageFile,
            fit: BoxFit.cover,
            cacheWidth: isListView ? 600 : 900,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFE0E5EC),
                child: Center(
                  child: Icon(
                    LucideIcons.imageOff,
                    size: isListView ? 80 : 48,
                    color: const Color(0xFF8E9AAF),
                  ),
                ),
              );
            },
          )
        : Container(
            color: const Color(0xFFE0E5EC),
            child: Center(
              child: Icon(
                LucideIcons.image,
                size: isListView ? 80 : 48,
                color: const Color(0xFF8E9AAF),
              ),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: isListView ? 280 : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            children: [
              // Image fills the card
              Positioned.fill(child: imageWidget),
              // Page number badge at top left
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
