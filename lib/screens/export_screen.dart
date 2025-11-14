import 'package:flutter/material.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';

/// PDF page size options
enum PageSize {
  a4,
  letter,
  legal,
}

/// PDF quality options
enum PdfQuality {
  low,
  medium,
  high,
}

/// Export screen for converting scans to PDF
class ExportScreen extends StatefulWidget {
  final ScanDocument document;

  const ExportScreen({
    super.key,
    required this.document,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late TextEditingController _fileNameController;
  PageSize _pageSize = PageSize.a4;
  PdfQuality _quality = PdfQuality.high;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: widget.document.name,
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Export to PDF',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Document preview
                  _buildDocumentPreview(),
                  const SizedBox(height: AppSpacing.lg),

                  // File name input
                  _buildFileNameInput(),
                  const SizedBox(height: AppSpacing.lg),

                  // Page size selection
                  _buildPageSizeSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Quality selection
                  _buildQualitySelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Export info
                  _buildExportInfo(),
                ],
              ),
            ),
          ),

          // Export button
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Preview',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Thumbnail
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${widget.document.imagePaths.length} pages',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Created: ${_formatDate(widget.document.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Name',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            hintText: 'Enter file name',
            suffixIcon: Icon(Icons.edit),
            suffixText: '.pdf',
          ),
        ),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Page Size',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: PageSize.values.map((size) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildOptionCard(
                  title: _getPageSizeName(size),
                  subtitle: _getPageSizeDimensions(size),
                  isSelected: _pageSize == size,
                  onTap: () => setState(() => _pageSize = size),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quality',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: PdfQuality.values.map((quality) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildOptionCard(
                  title: _getQualityName(quality),
                  subtitle: _getQualityDescription(quality),
                  isSelected: _quality == quality,
                  onTap: () => setState(() => _quality = quality),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportInfo() {
    final fileSize = _estimateFileSize();

    return Card(
      color: AppColors.primaryLight.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Information',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Estimated size: $fileSize',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Text(
                    'Format: PDF',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: _isExporting ? null : _exportToPdf,
          icon: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.file_download),
          label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  String _getPageSizeName(PageSize size) {
    switch (size) {
      case PageSize.a4:
        return 'A4';
      case PageSize.letter:
        return 'Letter';
      case PageSize.legal:
        return 'Legal';
    }
  }

  String _getPageSizeDimensions(PageSize size) {
    switch (size) {
      case PageSize.a4:
        return '210×297mm';
      case PageSize.letter:
        return '8.5×11in';
      case PageSize.legal:
        return '8.5×14in';
    }
  }

  String _getQualityName(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.low:
        return 'Low';
      case PdfQuality.medium:
        return 'Medium';
      case PdfQuality.high:
        return 'High';
    }
  }

  String _getQualityDescription(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.low:
        return 'Small file';
      case PdfQuality.medium:
        return 'Balanced';
      case PdfQuality.high:
        return 'Best quality';
    }
  }

  String _estimateFileSize() {
    final baseSize = widget.document.imagePaths.length * 0.5;
    final qualityMultiplier = _quality == PdfQuality.high
        ? 2.0
        : _quality == PdfQuality.medium
            ? 1.0
            : 0.5;
    final size = baseSize * qualityMultiplier;

    return '${size.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _exportToPdf() async {
    final fileName = _fileNameController.text.trim();

    if (fileName.isEmpty) {
      _showSnackBar('Please enter a file name', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    // Simulate export process
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isExporting = false);

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        title: const Text('Export Successful'),
        content: Text(
          'PDF saved as:\n${_fileNameController.text}.pdf',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Opening PDF...');
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
