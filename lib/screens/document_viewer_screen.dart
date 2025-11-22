import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_cache_service.dart';
import '../services/document_storage.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/common/context_menu_sheet.dart';

/// Document viewer screen showing all pages in a gallery
class DocumentViewerScreen extends StatefulWidget {
  final ScanDocument document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  late List<String> _imagePaths;
  late ScanDocument _document;
  final _pdfCacheService = PdfCacheService();
  File? _cachedPdfFile;
  bool _isLoadingPdf = false;
  bool _showPdfPreview = false;
  late TabController _tabController;
  int _totalFileSize = 0;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _imagePaths = List.from(_document.imagePaths);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _showPdfPreview = _tabController.index == 1;
        });
      }
    });

    // Defer size calculation to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTotalSize();
    });
  }

  void _calculateTotalSize() {
    int total = 0;
    for (final imagePath in _imagePaths) {
      final file = File(imagePath);
      if (file.existsSync()) {
        total += file.lengthSync();
      }
    }
    _totalFileSize = total;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load PDF preview (cached or generate new)
  Future<void> _loadPdfPreview() async {
    // Skip if no images
    if (_imagePaths.isEmpty) return;

    setState(() => _isLoadingPdf = true);

    try {
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: _imagePaths,
        documentName: _document.name,
        quality: _document.pdfQuality,
      );

      if (mounted) {
        setState(() {
          _cachedPdfFile = pdfFile;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading PDF preview: $e');
      if (mounted) {
        setState(() => _isLoadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: '',
        actions: [
          IconButton(
            icon: Icon(_isGridView ? LucideIcons.list : LucideIcons.layoutGrid),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Document info card with gradient
          _buildDocumentInfoHeader(),

          // Tab bar for Pages/PDF toggle
          if (_imagePaths.isNotEmpty) _buildTabBar(),

          // Content area - IndexedStack keeps PDF in memory
          Expanded(
            child: _imagePaths.isEmpty
                ? _buildEmptyState()
                : IndexedStack(
                    index: _showPdfPreview ? 1 : 0,
                    children: [
                      // Pages view
                      _isGridView ? _buildGridView() : _buildListView(),
                      // PDF view (kept in memory)
                      _buildPdfPreview(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Document icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                LucideIcons.fileText,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _document.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _buildInfoText(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInfoText() {
    final pageText =
        '${_imagePaths.length} ${_imagePaths.length == 1 ? 'page' : 'pages'}';
    final dateText = _formatDateShort(_document.createdAt);

    // Only show actual PDF size when available
    if (_cachedPdfFile != null && _cachedPdfFile!.existsSync()) {
      final sizeText = _formatFileSize(_cachedPdfFile!.lengthSync());
      return '$pageText · $dateText · $sizeText';
    }

    return '$pageText · $dateText';
  }

  String _formatDateShort(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ShadTabs<int>(
        value: _showPdfPreview ? 1 : 0,
        onChanged: (value) {
          setState(() {
            _showPdfPreview = value == 1;
            _tabController.animateTo(value);
          });
        },
        tabs: [
          ShadTab(
            value: 0,
            content: const SizedBox.shrink(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.images, size: 16),
                const SizedBox(width: 8),
                const Text('Pages'),
              ],
            ),
          ),
          ShadTab(
            value: 1,
            content: const SizedBox.shrink(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.fileText, size: 16),
                const SizedBox(width: 8),
                const Text('PDF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (_isLoadingPdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Generating PDF preview...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_cachedPdfFile == null || !_cachedPdfFile!.existsSync()) {
      // Trigger PDF loading on first view
      if (!_isLoadingPdf && _imagePaths.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadPdfPreview();
        });
      }
      // Show loading state while waiting
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Preparing PDF...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SfPdfViewer.file(
          _cachedPdfFile!,
          enableDoubleTapZooming: true,
          enableTextSelection: false,
          canShowScrollHead: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.imageOff,
                size: 60,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No pages in this document',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This document appears to be empty.\nTry editing to add new scans.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return ReorderableGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 210 / 297, // A4 ratio
      padding: const EdgeInsets.all(AppSpacing.md),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = _imagePaths.removeAt(oldIndex);
          _imagePaths.insert(newIndex, item);
        });
      },
      children: List.generate(
        _imagePaths.length,
        (index) {
          final imagePath = _imagePaths[index];
          final imageFile = File(imagePath);

          return GestureDetector(
            key: ValueKey(imagePath),
            onTap: () => _viewFullScreen(index),
            child: _buildCardContent(index, imageFile, isListView: false),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _imagePaths.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _imagePaths.removeAt(oldIndex);
          _imagePaths.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(_imagePaths[index]),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildPageCard(index, isListView: true),
        );
      },
    );
  }

  Widget _buildPageCard(int index, {bool isListView = false}) {
    final imagePath = _imagePaths[index];
    final imageFile = File(imagePath);

    return GestureDetector(
      onTap: () => _viewFullScreen(index),
      child: _buildCardContent(index, imageFile, isListView: isListView),
    );
  }

  Widget _buildCardContent(int index, File imageFile,
      {bool isListView = false}) {
    final imageWidget = imageFile.existsSync()
        ? Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.background,
                child: Center(
                  child: Icon(
                    LucideIcons.imageOff,
                    size: isListView ? 80 : 48,
                    color: AppColors.textHint,
                  ),
                ),
              );
            },
          )
        : Container(
            color: AppColors.background,
            child: Center(
              child: Icon(
                LucideIcons.image,
                size: isListView ? 80 : 48,
                color: AppColors.textHint,
              ),
            ),
          );

    return Container(
      height: isListView ? 280 : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm - 1),
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
    );
  }

  void _viewFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _imagePaths,
          initialPage: index,
        ),
      ),
    );
  }

  void _showOptions() {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: LucideIcons.settings2,
        label: 'PDF Quality (${_document.pdfQuality.displayName})',
        onTap: () {
          Navigator.pop(context);
          _showQualitySelector();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.share2,
        label: 'Share PDF',
        onTap: () {
          Navigator.pop(context);
          _exportToPdf();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.download,
        label: 'Save PDF',
        onTap: () {
          Navigator.pop(context);
          _savePdfLocally();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.trash2,
        label: 'Delete',
        color: AppColors.error,
        onTap: () {
          Navigator.pop(context);
          _confirmDelete();
        },
      ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: _document.name,
      items: items,
    );
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'PDF Quality',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Quality options
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: PdfQuality.values.map((quality) {
                  final isSelected = quality == _document.pdfQuality;
                  final estimatedSize =
                      (_totalFileSize * quality.compressionRatio).round();

                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _updateQuality(quality);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              quality.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            '~${_formatFileSize(estimatedSize)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _updateQuality(PdfQuality quality) async {
    if (quality == _document.pdfQuality) return;

    setState(() {
      _document = _document.copyWith(pdfQuality: quality);
    });

    // Save to storage
    final documents = await DocumentStorage.loadDocuments();
    final index = documents.indexWhere((doc) => doc.id == _document.id);
    if (index != -1) {
      documents[index] = _document;
      await DocumentStorage.saveDocuments(documents);
    }

    // Reload PDF with new quality
    _loadPdfPreview();
  }

  /// Show delete confirmation dialog
  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Document?',
          style: AppTextStyles.h3,
        ),
        content: Text(
          'This will permanently delete "${_document.name}" and all its pages. This action cannot be undone.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        backgroundColor: AppColors.surface,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deleteDocument();
            },
          ),
        ],
      ),
    );
  }

  /// Delete the document and return to gallery
  Future<void> _deleteDocument() async {
    try {
      final storage = DocumentStorage();
      await storage.deleteDocument(_document.id);

      // Clear cached PDF for this document
      await _pdfCacheService.removePdfFromCache(_imagePaths);

      if (!mounted) return;

      _showSnackBar('Document deleted');

      // Return to gallery with delete flag
      final navigator = Navigator.of(context);
      navigator.pop({'deleted': true, 'documentId': _document.id});
    } catch (e) {
      debugPrint('Error deleting document: $e');
      _showSnackBar('Failed to delete document');
    }
  }

  /// Export document to PDF and share (uses cached PDF)
  Future<void> _exportToPdf() async {
    try {
      _showSnackBar('Preparing PDF...');

      // Get or generate PDF with quality setting (uses cache)
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: _document.imagePaths,
        documentName: _document.name,
        quality: _document.pdfQuality,
      );

      if (!mounted) return;

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${_document.name}_$timestamp.pdf';

      // Share the PDF using the printing package
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: fileName,
      );

      // No snackbar for share - dialog is self-explanatory
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      _showSnackBar('Failed to export PDF');
    }
  }

  /// Save PDF to Downloads folder using MediaStore (uses cached PDF)
  Future<void> _savePdfLocally() async {
    try {
      _showSnackBar('Preparing PDF...');

      // Get or generate PDF with quality setting (uses cache)
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: _document.imagePaths,
        documentName: _document.name,
        quality: _document.pdfQuality,
      );

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${_document.name}_$timestamp.pdf';

      // Copy to new temp file with timestamp filename
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(await pdfFile.readAsBytes());

      // Initialize MediaStore
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'Scannie';

      // Save to Downloads folder using MediaStore (no permission required!)
      final mediaStore = MediaStore();
      final saveInfo = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: FilePath.root, // Save to root of Downloads folder
      );

      debugPrint('PDF saved to MediaStore: ${saveInfo?.uri}');

      if (!mounted) return;
      _showSnackBar('PDF saved to Downloads');

      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      _showSnackBar('Failed to save PDF');
    }
  }

  void _showSnackBar(String message) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
  }
}
