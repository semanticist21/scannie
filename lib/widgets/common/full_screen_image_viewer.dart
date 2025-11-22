import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
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
  sepia,
  invert,
  warm,
  cool,
}

/// Full screen image viewer with zoom, filters, download and share
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialPage;
  final bool showFilters;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    required this.initialPage,
    this.showFilters = true,
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
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
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
      case ImageFilterType.sepia:
        // Warm brownish vintage tone
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.invert:
        // Negative/inverted colors
        return const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.warm:
        // Warm tone (increase red/yellow)
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 10,
          0, 1.0, 0, 0, 0,
          0, 0, 0.8, 0, -10,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterType.cool:
        // Cool tone (increase blue)
        return const ColorFilter.matrix(<double>[
          0.9, 0, 0, 0, -10,
          0, 1.0, 0, 0, 0,
          0, 0, 1.2, 0, 20,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  /// Save filtered image back to original file
  Future<void> _saveFilteredImage() async {
    final navigator = Navigator.of(context);

    try {
      final imagePath = widget.imagePaths[_currentPage];

      if (_currentFilter == ImageFilterType.original) {
        // No filter applied, just pop back
        navigator.pop();
        return;
      }

      // Apply filter and save back to original file
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
        _showToast('Failed to process image', isError: true);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Save back to original file path (overwrite)
      await imageFile.writeAsBytes(pngBytes);

      // Clear image cache so the updated image shows in EditScreen
      imageCache.clear();
      imageCache.clearLiveImages();

      debugPrint('✅ Filter saved to original file: $imagePath');
      navigator.pop(true); // Return true to indicate image was modified
    } catch (e) {
      debugPrint('Error saving filtered image: $e');
      _showToast('Failed to save image: $e', isError: true);
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
            Padding(
              padding: EdgeInsets.only(
                bottom: widget.showFilters ? 160 : 0,
              ),
              child: GestureDetector(
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

              // Bottom bar with filters and save (only if showFilters is true)
              if (widget.showFilters)
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
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFilterButton(
                                ImageFilterType.original,
                                'Original',
                                LucideIcons.image,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.grayscale,
                                'B&W',
                                LucideIcons.contrast,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.highContrast,
                                'Contrast',
                                LucideIcons.sunDim,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.brighten,
                                'Brighten',
                                LucideIcons.sun,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.document,
                                'Document',
                                LucideIcons.fileText,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.sepia,
                                'Sepia',
                                LucideIcons.palette,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.invert,
                                'Invert',
                                LucideIcons.flipVertical,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.warm,
                                'Warm',
                                LucideIcons.flame,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(
                                ImageFilterType.cool,
                                'Cool',
                                LucideIcons.snowflake,
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
                            height: 48,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            hoverBackgroundColor: Colors.grey.shade200,
                            pressedBackgroundColor: Colors.grey.shade300,
                            leading: const Icon(LucideIcons.check, size: 18),
                            child: const Text('Save'),
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
