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

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isGridView = true;
  late List<String> _imagePaths;
  final _pdfCacheService = PdfCacheService();
  File? _cachedPdfFile;
  bool _isLoadingPdf = false;
  bool _showPdfPreview = false;

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.document.imagePaths);
    // Only load PDF preview if there are images
    if (_imagePaths.isNotEmpty) {
      _loadPdfPreview();
    }
  }

  /// Load PDF preview (cached or generate new)
  Future<void> _loadPdfPreview() async {
    // Skip if no images
    if (_imagePaths.isEmpty) return;

    setState(() => _isLoadingPdf = true);

    try {
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: _imagePaths,
        documentName: widget.document.name,
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
      appBar: CustomAppBar(
        title: widget.document.name,
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
          // Document info card
          _buildDocumentInfo(),

          // PDF Preview toggle (only show if there are images)
          if (_imagePaths.isNotEmpty) _buildPdfPreviewToggle(),

          // PDF Preview or Pages gallery
          Expanded(
            child: _imagePaths.isEmpty
                ? _buildEmptyState()
                : (_showPdfPreview
                    ? _buildPdfPreview()
                    : (_isGridView ? _buildGridView() : _buildListView())),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(
            LucideIcons.fileText,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_imagePaths.length} pages',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Created ${_formatDate(widget.document.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreviewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Pages'),
                  icon: Icon(LucideIcons.images),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('PDF Preview'),
                  icon: Icon(LucideIcons.fileText),
                ),
              ],
              selected: {_showPdfPreview},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _showPdfPreview = selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (_isLoadingPdf) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.lg),
            Text('Generating PDF preview...'),
          ],
        ),
      );
    }

    if (_cachedPdfFile == null || !_cachedPdfFile!.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PDF preview not available',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _loadPdfPreview,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      _cachedPdfFile!,
      enableDoubleTapZooming: true,
      enableTextSelection: false,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.imageOff,
            size: 120,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No pages in this document',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap Edit Scan to add images',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  Widget _buildCardContent(int index, File imageFile, {bool isListView = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            Expanded(
              child: imageFile.existsSync()
                  ? Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.background,
                          child: Center(
                            child: Icon(
                              LucideIcons.imageOff,
                              size: isListView ? 80 : 60,
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
                          size: isListView ? 80 : 60,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
            ),
            // Page number
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
              ),
              child: Text(
                'Page ${index + 1}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPdf();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.download),
              title: const Text('Download PDF'),
              onTap: () {
                Navigator.pop(context);
                _savePdfLocally();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: const Text(
                'Delete Document',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> _confirmDelete() async {
    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Delete Document?'),
        description: Text('This will permanently delete "${widget.document.name}" and all its pages. This action cannot be undone.'),
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
      await storage.deleteDocument(widget.document.id);

      // Clear cached PDF for this document
      await _pdfCacheService.removePdfFromCache(_imagePaths);

      if (!mounted) return;

      _showSnackBar('Document deleted');

      // Return to gallery with delete flag
      final navigator = Navigator.of(context);
      navigator.pop({'deleted': true, 'documentId': widget.document.id});
    } catch (e) {
      debugPrint('Error deleting document: $e');
      _showSnackBar('Failed to delete document');
    }
  }


  /// Export document to PDF and share (uses cached PDF)
  Future<void> _exportToPdf() async {
    try {
      _showSnackBar('Preparing PDF...');

      // Get or generate PDF (uses cache)
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: widget.document.imagePaths,
        documentName: widget.document.name,
      );

      if (!mounted) return;

      // Generate filename with timestamp
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${widget.document.name}_$timestamp.pdf';

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

      // Get or generate PDF (uses cache)
      final pdfFile = await _pdfCacheService.getOrGeneratePdf(
        imagePaths: widget.document.imagePaths,
        documentName: widget.document.name,
      );

      // Generate filename with timestamp
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${widget.document.name}_$timestamp.pdf';

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


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(String message) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
  }
}

/// Full screen image viewer with zoom
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
                      const SizedBox(width: 48), // Balance for close button
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
    );
  }
}
