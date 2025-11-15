import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/image_filters.dart';
import '../widgets/common/custom_app_bar.dart';

/// Filter type enum
enum FilterType {
  original,
  blackAndWhite,
  color,
  grayscale,
  enhanced,
}

/// Edit screen for applying filters and adjustments
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with SingleTickerProviderStateMixin {
  FilterType _selectedFilter = FilterType.original;
  double _brightness = 0;
  double _contrast = 0;
  bool _showAdjustments = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Image processing state
  List<String> _imagePaths = []; // Support multiple images
  int _currentImageIndex = 0;
  img.Image? _originalImage;
  Uint8List? _displayImageBytes;
  bool _isProcessing = false;
  int _rotationAngle = 0; // 0, 90, 180, 270

  // Corner adjustment state (for re-cropping)
  bool _showCropMode = false;
  List<Offset> _corners = [];
  int? _selectedCornerIndex;
  Size _imageDisplaySize = Size.zero;

  // Batch processing state
  FilterType? _batchFilter;
  double? _batchBrightness;
  double? _batchContrast;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load image paths from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && _imagePaths.isEmpty) {
      if (arguments is String) {
        // Single image path
        _imagePaths = [arguments];
      } else if (arguments is List<String>) {
        // Multiple image paths
        _imagePaths = arguments;
      }

      if (_imagePaths.isNotEmpty) {
        _loadCurrentImage();
      }
    }
  }

  /// Load the currently selected image
  Future<void> _loadCurrentImage() async {
    if (_imagePaths.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = _imagePaths[_currentImageIndex];
      _originalImage = await ImageFilters.loadImage(imagePath);

      // Reset adjustments for new image
      _rotationAngle = 0;
      _brightness = _batchBrightness ?? 0;
      _contrast = _batchContrast ?? 0;
      _selectedFilter = _batchFilter ?? FilterType.original;

      // Initialize crop corners
      _initializeCorners();

      await _applyCurrentFilter();
    } catch (e) {
      debugPrint('Error loading image: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Apply the currently selected filter and adjustments
  Future<void> _applyCurrentFilter() async {
    if (_originalImage == null) return;

    // Don't show loading indicator for filter changes
    // Process in background and update when ready

    try {
      // Start with original image
      img.Image processed = _originalImage!.clone();

      // Apply rotation if any
      if (_rotationAngle != 0) {
        if (_rotationAngle == 90) {
          processed = ImageFilters.rotate90(processed);
        } else if (_rotationAngle == 180) {
          processed = ImageFilters.rotate180(processed);
        } else if (_rotationAngle == 270) {
          processed = ImageFilters.rotate270(processed);
        }
      }

      // Apply selected filter
      switch (_selectedFilter) {
        case FilterType.original:
          processed = ImageFilters.applyOriginal(processed);
          break;
        case FilterType.blackAndWhite:
          processed = ImageFilters.applyBlackAndWhite(processed);
          break;
        case FilterType.color:
          processed = ImageFilters.applyMagicColor(processed);
          break;
        case FilterType.grayscale:
          processed = ImageFilters.applyGrayscale(processed);
          break;
        case FilterType.enhanced:
          processed = ImageFilters.applyLighten(processed);
          break;
      }

      // Apply brightness and contrast adjustments
      if (_brightness != 0 || _contrast != 0) {
        processed = ImageFilters.applyBrightnessAndContrast(
          processed,
          _brightness,
          _contrast,
        );
      }

      // Encode for display
      final newImageBytes = ImageFilters.encodeImage(processed);

      // Update UI with new image
      setState(() {
        _displayImageBytes = newImageBytes;
      });
    } catch (e) {
      // Error processing image
    }
  }

  /// Initialize corner points to image bounds (10% margin)
  void _initializeCorners() {
    if (_originalImage == null) return;

    _corners = [
      const Offset(0.1, 0.1),     // Top-left
      const Offset(0.9, 0.1),     // Top-right
      const Offset(0.9, 0.9),     // Bottom-right
      const Offset(0.1, 0.9),     // Bottom-left
    ];
  }

  /// Apply perspective transform using image package's copyRectify
  Future<void> _applyCrop() async {
    if (_originalImage == null || _corners.length != 4) return;

    setState(() => _isProcessing = true);

    try {
      final imageWidth = _originalImage!.width;
      final imageHeight = _originalImage!.height;

      // Convert normalized corners (0-1) to actual pixel coordinates
      final topLeft = img.Point(
        (_corners[0].dx * imageWidth).toInt(),
        (_corners[0].dy * imageHeight).toInt(),
      );
      final topRight = img.Point(
        (_corners[1].dx * imageWidth).toInt(),
        (_corners[1].dy * imageHeight).toInt(),
      );
      final bottomRight = img.Point(
        (_corners[2].dx * imageWidth).toInt(),
        (_corners[2].dy * imageHeight).toInt(),
      );
      final bottomLeft = img.Point(
        (_corners[3].dx * imageWidth).toInt(),
        (_corners[3].dy * imageHeight).toInt(),
      );

      // Apply perspective correction using copyRectify
      final rectified = img.copyRectify(
        _originalImage!,
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      );

      _originalImage = rectified;

      // Re-apply current filter
      await _applyCurrentFilter();

      setState(() {
        _showCropMode = false;
        _selectedCornerIndex = null;
      });

      _showMessage('Crop applied');
    } catch (e) {
      debugPrint('Error applying crop: $e');
      _showMessage('Failed to apply crop: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = _imagePaths.length > 1;

    return Scaffold(
      appBar: CustomAppBar(
        title: hasMultipleImages
            ? 'Edit ${_currentImageIndex + 1}/${_imagePaths.length}'
            : 'Edit Scan',
        actions: [
          // Batch apply button (only for multiple images)
          if (hasMultipleImages)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Apply to all images',
              onPressed: _showBatchApplyDialog,
            ),
          // Save button
          TextButton(
            onPressed: _saveScan,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image navigation (only for multiple images)
          if (hasMultipleImages) _buildImageNavigation(),

          // Image preview
          Expanded(
            flex: 3,
            child: _buildImagePreview(),
          ),

          // Adjustments slider (conditional with animation)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showAdjustments ? _buildAdjustments() : const SizedBox.shrink(),
          ),

          // Filter options
          _buildFilterOptions(),

          // Bottom action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentImageIndex > 0
                ? () {
                    setState(() {
                      _currentImageIndex--;
                    });
                    _loadCurrentImage();
                  }
                : null,
          ),
          // Page indicator
          Text(
            '${_currentImageIndex + 1} / ${_imagePaths.length}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentImageIndex < _imagePaths.length - 1
                ? () {
                    setState(() {
                      _currentImageIndex++;
                    });
                    _loadCurrentImage();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: _getFilterColor(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 2,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 210 / 297, // A4 ratio
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md - 2),
                    child: _displayImageBytes != null
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: Image.memory(
                              _displayImageBytes!,
                              key: ValueKey(_displayImageBytes.hashCode),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Center(
                            child: _isProcessing
                                ? const CircularProgressIndicator()
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 80,
                                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        _getFilterName(_selectedFilter),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                  ),

                  // Corner handles for manual crop
                  if (_displayImageBytes != null) ..._buildCropHandles(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCropHandles() {
    if (!_showCropMode || _corners.length != 4) return [];

    return [
      // Quad overlay covering entire Stack area
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _imageDisplaySize = Size(constraints.maxWidth, constraints.maxHeight);

            return CustomPaint(
              size: _imageDisplaySize,
              painter: _CropQuadPainter(_corners, _imageDisplaySize),
            );
          },
        ),
      ),

      // Draggable corner handles
      ..._corners.asMap().entries.map((entry) {
        final index = entry.key;
        final corner = entry.value;

        return Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate actual position within the Stack bounds
              final position = Offset(
                corner.dx * constraints.maxWidth,
                corner.dy * constraints.maxHeight,
              );

              return Stack(
                children: [
                  Positioned(
                    left: position.dx - 12,
                    top: position.dy - 12,
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() => _selectedCornerIndex = index);
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          // Calculate new position relative to Stack bounds
                          final newX = (position.dx + details.delta.dx) / constraints.maxWidth;
                          final newY = (position.dy + details.delta.dy) / constraints.maxHeight;
                          _corners[index] = Offset(
                            newX.clamp(0.0, 1.0),
                            newY.clamp(0.0, 1.0),
                          );
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => _selectedCornerIndex = null);
                      },
                      child: _buildHandle(index),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    ];
  }

  Widget _buildHandle(int index) {
    final labels = ['TL', 'TR', 'BR', 'BL'];
    final isSelected = _selectedCornerIndex == index;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          labels[index],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustments() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        children: [
          // Brightness slider
          _buildSlider(
            label: 'Brightness',
            value: _brightness,
            icon: Icons.brightness_6,
            onChanged: (value) {
              setState(() => _brightness = value);
              _applyCurrentFilter();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          // Contrast slider
          _buildSlider(
            label: 'Contrast',
            value: _contrast,
            icon: Icons.contrast,
            onChanged: (value) {
              setState(() => _contrast = value);
              _applyCurrentFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        Expanded(
          child: Slider(
            value: value,
            min: -100,
            max: 100,
            divisions: 40,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toInt().toString(),
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<FilterType>(
              segments: FilterType.values.map((filter) {
                return ButtonSegment<FilterType>(
                  value: filter,
                  label: Text(_getFilterName(filter)),
                  icon: const Icon(Icons.image),
                );
              }).toList(),
              selected: {_selectedFilter},
              onSelectionChanged: (Set<FilterType> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
                _applyCurrentFilter();
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Crop mode toggle
          _buildActionButton(
            icon: _showCropMode ? Icons.crop : Icons.crop_free,
            label: 'Crop',
            tooltip: _showCropMode ? 'Adjust corners then apply' : 'Enable crop mode',
            onPressed: () {
              setState(() {
                _showCropMode = !_showCropMode;
                if (!_showCropMode) _selectedCornerIndex = null;
              });
            },
            isActive: _showCropMode,
          ),

          // Apply crop (only visible in crop mode)
          if (_showCropMode)
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'Apply',
              tooltip: 'Apply crop',
              onPressed: _applyCrop,
            ),

          // Rotate (hidden in crop mode)
          if (!_showCropMode)
            _buildActionButton(
              icon: Icons.rotate_right,
              label: 'Rotate',
              tooltip: 'Rotate 90 degrees clockwise',
              onPressed: () {
                setState(() {
                  _rotationAngle = (_rotationAngle + 90) % 360;
                });
                _applyCurrentFilter();
                _showMessage('Rotated 90°');
              },
            ),

          // Adjustments toggle
          _buildActionButton(
            icon: _showAdjustments ? Icons.tune : Icons.tune_outlined,
            label: 'Adjust',
            tooltip: _showAdjustments ? 'Hide adjustments' : 'Show brightness and contrast adjustments',
            onPressed: () => setState(() => _showAdjustments = !_showAdjustments),
            isActive: _showAdjustments,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isActive
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: 28,
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getFilterColor([FilterType? filter]) {
    filter ??= _selectedFilter;
    switch (filter) {
      case FilterType.original:
        return Colors.white;
      case FilterType.blackAndWhite:
        return Colors.grey.shade100;
      case FilterType.color:
        return AppColors.primaryLight;
      case FilterType.grayscale:
        return Colors.grey.shade200;
      case FilterType.enhanced:
        return Colors.blue.shade50;
    }
  }

  String _getFilterName(FilterType filter) {
    switch (filter) {
      case FilterType.original:
        return 'Original';
      case FilterType.blackAndWhite:
        return 'B&W';
      case FilterType.color:
        return 'Color';
      case FilterType.grayscale:
        return 'Grayscale';
      case FilterType.enhanced:
        return 'Enhanced';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show batch apply dialog
  void _showBatchApplyDialog() {
    final dialogContext = context;
    showDialog<void>(
      context: dialogContext,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Apply to All Images'),
          content: const Text(
            'Apply current filter, brightness, and contrast settings to all images?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _applyBatchSettings();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  /// Apply current settings to all images
  Future<void> _applyBatchSettings() async {
    final messenger = ScaffoldMessenger.of(context);

    // Save current settings
    _batchFilter = _selectedFilter;
    _batchBrightness = _brightness;
    _batchContrast = _contrast;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Text('Batch settings applied to ${_imagePaths.length} images'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveScan() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show saving progress
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text('Saving scans...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: Actually save processed images to file system
    // For now, just use the original image paths

    // Create a new scan document with all image paths
    final newDocument = ScanDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}',
      createdAt: DateTime.now(),
      imagePaths: _imagePaths, // All captured image paths
      isProcessed: true,
    );

    // Wait a bit to show progress
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Text('${_imagePaths.length} image(s) saved successfully'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    // Return the new document to the previous screen
    navigator.pop(newDocument);
  }
}

/// Custom painter for crop quad overlay
class _CropQuadPainter extends CustomPainter {
  final List<Offset> corners;
  final Size imageSize;

  _CropQuadPainter(this.corners, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Convert normalized coordinates to pixels
    final points = corners.map((corner) {
      return Offset(corner.dx * imageSize.width, corner.dy * imageSize.height);
    }).toList();

    // Draw quad
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CropQuadPainter oldDelegate) => corners != oldDelegate.corners;
}
