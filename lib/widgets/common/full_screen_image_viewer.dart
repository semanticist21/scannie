import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:elegant_notification/elegant_notification.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Filter type for document enhancement
enum ImageFilterType {
  original,
  grayscale,
  highContrast,
  brighten,
  document,
}

/// Full screen image viewer with zoom, filters, download and share
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
  ImageFilterType _currentFilter = ImageFilterType.original;

  void _showToast(String message, {bool isError = false}) {
    if (isError) {
      ElegantNotification.error(
        title: Text(
          'Error',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        description: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        width: 280,
        height: 60,
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: false,
        displayCloseButton: false,
        borderRadius: BorderRadius.circular(AppRadius.md),
        background: AppColors.surface,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ).show(context);
    } else {
      ElegantNotification.success(
        title: Text(
          'Saved',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        description: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        width: 280,
        height: 60,
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: false,
        displayCloseButton: false,
        borderRadius: BorderRadius.circular(AppRadius.md),
        background: AppColors.surface,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ).show(context);
    }
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

  /// Get color matrix for filter
  ColorFilter? _getColorFilter() {
    switch (_currentFilter) {
      case ImageFilterType.original:
        return null;
      case ImageFilterType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.highContrast:
        return const ColorFilter.matrix(<double>[
          1.5, 0, 0, 0, -40,
          0, 1.5, 0, 0, -40,
          0, 0, 1.5, 0, -40,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.brighten:
        return const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 30,
          0, 1, 0, 0, 30,
          0, 0, 1, 0, 30,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.document:
        // High contrast + slight brightness for document scanning
        return const ColorFilter.matrix(<double>[
          1.8, 0, 0, 0, -60,
          0, 1.8, 0, 0, -60,
          0, 0, 1.8, 0, -60,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  /// Save filtered image
  Future<void> _saveFilteredImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];

      if (_currentFilter == ImageFilterType.original) {
        // Save original directly
        final result = await ImageGallerySaverPlus.saveFile(
          imagePath,
          name: 'Scannie_${DateTime.now().millisecondsSinceEpoch}',
        );
        final success = result['isSuccess'] == true;
        _showToast(success ? 'Image saved to Photos' : 'Failed to save image', isError: !success);
      } else {
        // Apply filter and save
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(imageBytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // Create filtered image
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint();

        final colorFilter = _getColorFilter();
        if (colorFilter != null) {
          paint.colorFilter = colorFilter;
        }

        canvas.drawImage(image, Offset.zero, paint);
        final picture = recorder.endRecording();
        final filteredImage = await picture.toImage(image.width, image.height);

        // Convert to bytes
        final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          _showToast('Failed to process image');
          return;
        }

        final pngBytes = byteData.buffer.asUint8List();

        // Save to temp file first
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(pngBytes);

        // Save to gallery
        final result = await ImageGallerySaverPlus.saveFile(
          tempFile.path,
          name: 'Scannie_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Clean up temp file
        await tempFile.delete();

        final success = result['isSuccess'] == true;
        _showToast(success ? 'Filtered image saved to Photos' : 'Failed to save image');
      }
    } catch (e) {
      debugPrint('Error saving filtered image: $e');
      _showToast('Failed to save image: $e');
    }
  }

  /// Download current image to device
  Future<void> _downloadCurrentImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        _showToast('Image file not found');
        return;
      }

      // Save to gallery using image_gallery_saver (works on iOS & Android)
      final result = await ImageGallerySaverPlus.saveFile(
        imagePath,
        name: 'Scannie_${DateTime.now().millisecondsSinceEpoch}',
      );

      final success = result['isSuccess'] == true;
      _showToast(success ? 'Image saved to Photos' : 'Failed to save image');

      debugPrint('Image saved to gallery: $result');
    } catch (e) {
      debugPrint('Error saving image: $e');
      _showToast('Failed to save image: $e');
    }
  }

  /// Share current image
  Future<void> _shareCurrentImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        _showToast('Image file not found');
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
      _showToast('Failed to share image: $e');
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

    Widget imageWidget = Image.file(
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
    );

    // Apply color filter if not original
    final colorFilter = _getColorFilter();
    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter,
        child: imageWidget,
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
        child: imageWidget,
      ),
    );
  }

  Widget _buildFilterButton(ImageFilterType filter, String label, IconData icon) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              // Bottom bar with filters and save
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Filter options
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFilterButton(
                              ImageFilterType.original,
                              'Original',
                              LucideIcons.image,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildFilterButton(
                              ImageFilterType.grayscale,
                              'B&W',
                              LucideIcons.contrast,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildFilterButton(
                              ImageFilterType.highContrast,
                              'Contrast',
                              LucideIcons.sunDim,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildFilterButton(
                              ImageFilterType.brighten,
                              'Brighten',
                              LucideIcons.sun,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildFilterButton(
                              ImageFilterType.document,
                              'Document',
                              LucideIcons.fileText,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          onPressed: _saveFilteredImage,
                          leading: const Icon(LucideIcons.save, size: 18, color: Colors.black),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          child: const Text('Save with Filter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
