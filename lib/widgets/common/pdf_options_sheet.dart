import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/scan_document.dart';

/// Bottom sheet for editing PDF options of a specific document
class PdfOptionsSheet extends StatefulWidget {
  final PdfQuality quality;
  final PdfPageSize pageSize;
  final PdfOrientation orientation;
  final PdfImageFit imageFit;
  final Function(PdfQuality, PdfPageSize, PdfOrientation, PdfImageFit) onSave;

  const PdfOptionsSheet({
    super.key,
    required this.quality,
    required this.pageSize,
    required this.orientation,
    required this.imageFit,
    required this.onSave,
  });

  static void show({
    required BuildContext context,
    required PdfQuality quality,
    required PdfPageSize pageSize,
    required PdfOrientation orientation,
    required PdfImageFit imageFit,
    required Function(PdfQuality, PdfPageSize, PdfOrientation, PdfImageFit) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => PdfOptionsSheet(
        quality: quality,
        pageSize: pageSize,
        orientation: orientation,
        imageFit: imageFit,
        onSave: (q, ps, o, fit) {
          Navigator.pop(sheetContext);
          onSave(q, ps, o, fit);
        },
      ),
    );
  }

  @override
  State<PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends State<PdfOptionsSheet> {
  late PdfQuality _quality;
  late PdfPageSize _pageSize;
  late PdfOrientation _orientation;
  late PdfImageFit _imageFit;

  @override
  void initState() {
    super.initState();
    _quality = widget.quality;
    _pageSize = widget.pageSize;
    _orientation = widget.orientation;
    _imageFit = widget.imageFit;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),

            // Header
            Text(
              'viewer.pdfOptions'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quality
            _buildOptionRow(
              icon: LucideIcons.image,
              label: 'settings.pdfQuality'.tr(),
              child: SizedBox(
                width: 120,
                child: ShadSelect<PdfQuality>(
                  initialValue: _quality,
                  onChanged: (value) {
                    if (value != null) setState(() => _quality = value);
                  },
                  selectedOptionBuilder: (context, value) => Text(
                    value.displayName,
                    style: AppTextStyles.bodySmall,
                  ),
                  options: PdfQuality.values
                      .map((q) => ShadOption(
                            value: q,
                            child: Text(q.displayName),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Page Size
            _buildOptionRow(
              icon: LucideIcons.fileText,
              label: 'settings.pdfPageSize'.tr(),
              child: SizedBox(
                width: 120,
                child: ShadSelect<PdfPageSize>(
                  initialValue: _pageSize,
                  onChanged: (value) {
                    if (value != null) setState(() => _pageSize = value);
                  },
                  selectedOptionBuilder: (context, value) => Text(
                    value.displayName,
                    style: AppTextStyles.bodySmall,
                  ),
                  options: PdfPageSize.values
                      .map((s) => ShadOption(
                            value: s,
                            child: Text(s.displayName),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Orientation
            _buildOptionRow(
              icon: LucideIcons.smartphone,
              label: 'settings.pdfOrientation'.tr(),
              child: SizedBox(
                width: 120,
                child: ShadSelect<PdfOrientation>(
                  initialValue: _orientation,
                  onChanged: (value) {
                    if (value != null) setState(() => _orientation = value);
                  },
                  selectedOptionBuilder: (context, value) => Text(
                    value.displayName,
                    style: AppTextStyles.bodySmall,
                  ),
                  options: PdfOrientation.values
                      .map((o) => ShadOption(
                            value: o,
                            child: Text(o.displayName),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Image Fit
            _buildOptionRow(
              icon: LucideIcons.maximize,
              label: 'settings.pdfImageFit'.tr(),
              child: SizedBox(
                width: 120,
                child: ShadSelect<PdfImageFit>(
                  initialValue: _imageFit,
                  onChanged: (value) {
                    if (value != null) setState(() => _imageFit = value);
                  },
                  selectedOptionBuilder: (context, value) => Text(
                    value.displayName,
                    style: AppTextStyles.bodySmall,
                  ),
                  options: PdfImageFit.values
                      .map((f) => ShadOption(
                            value: f,
                            child: Text(f.displayName),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: () {
                  widget.onSave(_quality, _pageSize, _orientation, _imageFit);
                },
                child: Text('common.save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ),
        child,
      ],
    );
  }
}
