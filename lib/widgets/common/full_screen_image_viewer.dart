import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/image_filter_type.dart';
import '../../services/export_service.dart';
import '../../utils/app_toast.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

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
  String? _tempRotatedImagePath; // Temporary rotated image (not yet saved)
  bool _isSaving = false;

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

  /// Open image cropper for rotation and cropping
  Future<void> _cropAndRotateImage() async {
    // Use temp image if exists, otherwise use original
    final sourcePath = _tempRotatedImagePath ?? widget.imagePaths[_currentPage];

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'imageViewer.rotateImage'.tr(),
          toolbarColor: AppColors.darkBackground,
          toolbarWidgetColor: AppColors.white,
          statusBarLight: false,
          backgroundColor: AppColors.darkBackground,
          dimmedLayerColor: AppColors.barrierDark,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          cropFrameStrokeWidth: 2,
        ),
        IOSUiSettings(
          title: 'imageViewer.rotateImage'.tr(),
          doneButtonTitle: 'common.save'.tr(),
          cancelButtonTitle: 'common.cancel'.tr(),
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
          aspectRatioPickerButtonHidden: true,
          hidesNavigationBar: false,
          showCancelConfirmationDialog: false,
          aspectRatioLockDimensionSwapEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      // Delete previous temp file if exists
      if (_tempRotatedImagePath != null) {
        try {
          await File(_tempRotatedImagePath!).delete();
        } catch (_) {}
      }

      // Save to temp location (not original yet)
      _tempRotatedImagePath = croppedFile.path;

      // Clear image cache to show updated temp image
      imageCache.clear();
      imageCache.clearLiveImages();

      // Refresh the view
      if (mounted) {
        setState(() {});
      }

      debugPrint('✅ Image cropped/rotated to temp: $_tempRotatedImagePath');
    }
  }

  /// Clean up temp file
  Future<void> _cleanupTempFile() async {
    if (_tempRotatedImagePath != null) {
      try {
        await File(_tempRotatedImagePath!).delete();
      } catch (_) {}
      _tempRotatedImagePath = null;
    }
  }

  /// Get color matrix for filter
  ColorFilter? _getColorFilter() {
    switch (_currentFilter) {
      case ImageFilterType.original:
        return null;
      case ImageFilterType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.highContrast:
        return const ColorFilter.matrix(<double>[
          1.5,
          0,
          0,
          0,
          -40,
          0,
          1.5,
          0,
          0,
          -40,
          0,
          0,
          1.5,
          0,
          -40,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.brighten:
        return const ColorFilter.matrix(<double>[
          1,
          0,
          0,
          0,
          30,
          0,
          1,
          0,
          0,
          30,
          0,
          0,
          1,
          0,
          30,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.document:
        // High contrast + slight brightness for document scanning
        return const ColorFilter.matrix(<double>[
          1.8,
          0,
          0,
          0,
          -60,
          0,
          1.8,
          0,
          0,
          -60,
          0,
          0,
          1.8,
          0,
          -60,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.sepia:
        // Warm brownish vintage tone
        return const ColorFilter.matrix(<double>[
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.invert:
        // Negative/inverted colors
        return const ColorFilter.matrix(<double>[
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.warm:
        // Warm tone (increase red/yellow)
        return const ColorFilter.matrix(<double>[
          1.2,
          0,
          0,
          0,
          10,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          0.8,
          0,
          -10,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterType.cool:
        // Cool tone (increase blue)
        return const ColorFilter.matrix(<double>[
          0.9,
          0,
          0,
          0,
          -10,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          1.2,
          0,
          20,
          0,
          0,
          0,
          1,
          0,
        ]);
    }
  }

  /// Save filtered/rotated image to temp file and return path
  /// Does NOT modify original - EditScreen will handle final save
  Future<void> _saveFilteredImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);

    try {
      final originalPath = widget.imagePaths[_currentPage];
      final hasRotation = _tempRotatedImagePath != null;
      final hasFilter = _currentFilter != ImageFilterType.original;

      if (!hasRotation && !hasFilter) {
        // No modifications, just pop back
        await _cleanupTempFile();
        navigator.pop();
        return;
      }

      // Start with rotated image if exists, otherwise original
      final sourceFile =
          File(hasRotation ? _tempRotatedImagePath! : originalPath);
      var imageBytes = await sourceFile.readAsBytes();

      // Apply filter if needed
      if (hasFilter) {
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
        final byteData =
            await filteredImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          if (mounted) {
            AppToast.show(context, 'toast.failedToProcessImage'.tr(),
                isError: true);
          }
          return;
        }

        imageBytes = byteData.buffer.asUint8List();
      }

      // Save to temp file instead of overwriting original
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(originalPath);
      final tempFilePath =
          path.join(tempDir.path, 'edited_$timestamp$extension');
      await File(tempFilePath).writeAsBytes(imageBytes);

      // Clean up intermediate temp file (from cropper)
      await _cleanupTempFile();

      // Clear image cache so the updated image shows in EditScreen
      imageCache.clear();
      imageCache.clearLiveImages();

      debugPrint('✅ Image saved to temp file: $tempFilePath');
      // Return the temp file path so EditScreen can track it
      navigator.pop(tempFilePath);
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        AppToast.show(context,
            'toast.failedToSaveImage'.tr(namedArgs: {'error': e.toString()}),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Download current image to device
  Future<void> _downloadCurrentImage() async {
    final imagePath = widget.imagePaths[_currentPage];
    final result =
        await ExportService.instance.saveImagesToGallery([imagePath]);

    if (!mounted) return;

    // Show appropriate feedback based on result
    if (result.isSuccess) {
      AppToast.show(context, 'toast.imageSavedToPhotos'.tr());
    } else {
      AppToast.showExportResult(context, result);
    }
  }

  /// Share current image
  Future<void> _shareCurrentImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        AppToast.show(context, 'toast.imageNotFound'.tr(), isError: true);
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        AppToast.show(context,
            'toast.failedToShareImage'.tr(namedArgs: {'error': e.toString()}),
            isError: true);
      }
    }
  }

  Widget _buildFullScreenImage(int index) {
    // Use temp image if exists and it's the current page, otherwise use original
    final imagePath = (index == _currentPage && _tempRotatedImagePath != null)
        ? _tempRotatedImagePath!
        : widget.imagePaths[index];
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      return Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.imageOff,
                size: 100,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'imageViewer.imageNotFound'.tr(),
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
                color: AppColors.darkTextTertiary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'imageViewer.failedToLoadImage'.tr(),
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.darkTextTertiary,
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
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: imageWidget,
      ),
    );
  }

  Widget _buildFilterButton(
      ImageFilterType filter, String label, IconData icon) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.ms,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkOverlay : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color:
                isSelected ? AppColors.darkOverlayLight : AppColors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.darkTextPrimary
                  : AppColors.darkTextSecondary,
              size: 24,
            ),
            AppGap.vXs,
            Text(
              label,
              style: AppTextStyles.labelCompact.copyWith(
                color: isSelected
                    ? AppColors.darkTextPrimary
                    : AppColors.darkTextSecondary,
                fontWeight:
                    isSelected ? AppFontWeight.semiBold : AppFontWeight.medium,
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
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Page viewer with zoom (using photo_view for better gesture handling)
            Padding(
              padding: EdgeInsets.only(
                top: 56, // Space for top control bar
                bottom: widget.showFilters ? 80 : 0, // Filters only
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _showControls = !_showControls);
                },
                child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  pageController: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: widget.imagePaths.length,
                  backgroundDecoration: const BoxDecoration(
                    color: AppColors.darkBackground,
                  ),
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: _buildFullScreenImage(index),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4.0,
                      initialScale: PhotoViewComputedScale.contained,
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
                        AppColors.shadowDarker,
                        AppColors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: AppColors.darkTextPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'viewer.pageOf'.tr(namedArgs: {
                            'current': (_currentPage + 1).toString(),
                            'total': widget.imagePaths.length.toString()
                          }),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: AppFontWeight.semiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (widget.showFilters) ...[
                        IconButton(
                          icon: const Icon(LucideIcons.crop,
                              color: AppColors.darkTextPrimary),
                          onPressed: _cropAndRotateImage,
                          tooltip: 'imageViewer.rotateImage'.tr(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Save button (circle)
                        GestureDetector(
                          onTap: _isSaving ? null : _saveFilteredImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isSaving
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                      // Hide download/share in edit mode (showFilters = true)
                      if (!widget.showFilters) ...[
                        IconButton(
                          icon: const Icon(LucideIcons.download,
                              color: AppColors.darkTextPrimary),
                          onPressed: _downloadCurrentImage,
                          tooltip: 'imageViewer.saveToPhotos'.tr(),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.share2,
                              color: AppColors.darkTextPrimary),
                          onPressed: _shareCurrentImage,
                          tooltip: 'imageViewer.shareImage'.tr(),
                        ),
                      ],
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.shadowDarkest,
                          AppColors.shadowDarkest.withValues(alpha: 0.9),
                          AppColors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter options
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFilterButton(
                                ImageFilterType.original,
                                'filters.original'.tr(),
                                LucideIcons.image,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.grayscale,
                                'filters.bw'.tr(),
                                LucideIcons.contrast,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.highContrast,
                                'filters.contrast'.tr(),
                                LucideIcons.sunDim,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.brighten,
                                'filters.brighten'.tr(),
                                LucideIcons.sun,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.document,
                                'filters.document'.tr(),
                                LucideIcons.fileText,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.sepia,
                                'filters.sepia'.tr(),
                                LucideIcons.palette,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.invert,
                                'filters.invert'.tr(),
                                LucideIcons.flipVertical,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.warm,
                                'filters.warm'.tr(),
                                LucideIcons.flame,
                              ),
                              const SizedBox(width: AppSpacing.ms),
                              _buildFilterButton(
                                ImageFilterType.cool,
                                'filters.cool'.tr(),
                                LucideIcons.snowflake,
                              ),
                            ],
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
