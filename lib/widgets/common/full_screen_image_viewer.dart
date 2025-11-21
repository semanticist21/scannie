import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Full screen image viewer with zoom, download and share
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialPage;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    required this.initialPage,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _showControls = true;
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showSnackBar(String message) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Download current image to device
  Future<void> _downloadCurrentImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        _showSnackBar('Image file not found');
        return;
      }

      // Save to gallery using image_gallery_saver (works on iOS & Android)
      final result = await ImageGallerySaverPlus.saveFile(
        imagePath,
        name: 'Scannie_${DateTime.now().millisecondsSinceEpoch}',
      );

      final success = result['isSuccess'] == true;
      _showSnackBar(success ? 'Image saved to Photos' : 'Failed to save image');

      debugPrint('Image saved to gallery: $result');
    } catch (e) {
      debugPrint('Error saving image: $e');
      _showSnackBar('Failed to save image: $e');
    }
  }

  /// Share current image
  Future<void> _shareCurrentImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        _showSnackBar('Image file not found');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
          text: 'Scanned image from Scannie',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      _showSnackBar('Failed to share image: $e');
    }
  }

  Widget _buildFullScreenImage(int index) {
    final imagePath = widget.imagePaths[index];
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      return Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.imageOff,
                size: 120,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Image not found',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.circleAlert,
                    size: 120,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Failed to load image',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: Stack(
          children: [
            // Page viewer with zoom
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: widget.imagePaths.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildFullScreenImage(index),
                    ),
                  );
                },
              ),
            ),

            // Controls overlay
            if (_showControls) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Page ${_currentPage + 1} of ${widget.imagePaths.length}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.download, color: Colors.white),
                        onPressed: _downloadCurrentImage,
                        tooltip: 'Save to Photos',
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.share2, color: Colors.white),
                        onPressed: _shareCurrentImage,
                        tooltip: 'Share Image',
                      ),
                    ],
                  ),
                ),
              ),

              // Page indicator
              Positioned(
                bottom: AppSpacing.xl,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        Text(
                          '${_currentPage + 1} / ${widget.imagePaths.length}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
                          onPressed: _currentPage < widget.imagePaths.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
