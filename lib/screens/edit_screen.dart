import 'package:flutter/material.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Scan',
        actions: [
          TextButton(
            onPressed: _saveScan,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
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

  Widget _buildImagePreview() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Image placeholder with filter effect
              AnimatedContainer(
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
                  child: Center(
                    child: Column(
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
              ),

              // Corner handles for manual crop
              ..._buildCropHandles(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCropHandles() {
    return [
      // Top-left
      Positioned(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        child: _buildHandle(),
      ),
      // Top-right
      Positioned(
        top: AppSpacing.lg,
        right: AppSpacing.lg,
        child: _buildHandle(),
      ),
      // Bottom-left
      Positioned(
        bottom: AppSpacing.lg,
        left: AppSpacing.lg,
        child: _buildHandle(),
      ),
      // Bottom-right
      Positioned(
        bottom: AppSpacing.lg,
        right: AppSpacing.lg,
        child: _buildHandle(),
      ),
    ];
  }

  Widget _buildHandle() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
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
            onChanged: (value) => setState(() => _brightness = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Contrast slider
          _buildSlider(
            label: 'Contrast',
            value: _contrast,
            icon: Icons.contrast,
            onChanged: (value) => setState(() => _contrast = value),
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
      height: 120,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: FilterType.values.map((filter) {
          return _buildFilterOption(filter);
        }).toList(),
      ),
    );
  }

  Widget _buildFilterOption(FilterType filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getFilterColor(filter),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.image,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              child: Text(_getFilterName(filter)),
            ),
          ],
        ),
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
          // Auto crop
          _buildActionButton(
            icon: Icons.crop_free,
            label: 'Auto Crop',
            tooltip: 'Automatically crop document edges',
            onPressed: () => _showMessage('Auto crop applied'),
          ),

          // Rotate
          _buildActionButton(
            icon: Icons.rotate_right,
            label: 'Rotate',
            tooltip: 'Rotate 90 degrees clockwise',
            onPressed: () => _showMessage('Rotated 90°'),
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

  void _saveScan() {
    // Create a new scan document
    final newDocument = ScanDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}',
      createdAt: DateTime.now(),
      imagePaths: ['scanned_image.jpg'], // Mock image path
      isProcessed: true,
    );

    _showMessage('Scan saved successfully');

    // Return the new document to the previous screen
    Navigator.of(context).pop(newDocument);
  }
}
