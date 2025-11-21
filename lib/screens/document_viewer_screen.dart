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
  final _pdfCacheService = PdfCacheService();
  File? _cachedPdfFile;
  bool _isLoadingPdf = false;
  bool _showPdfPreview = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.document.imagePaths);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _showPdfPreview = _tabController.index == 1;
        });
      }
    });
    // Only load PDF preview if there are images
    if (_imagePaths.isNotEmpty) {
      _loadPdfPreview();
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
      backgroundColor: AppColors.background,
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
          // Document info card with gradient
          _buildDocumentInfoHeader(),

          // Tab bar for Pages/PDF toggle
          if (_imagePaths.isNotEmpty) _buildTabBar(),

          // Content area
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

  Widget _buildDocumentInfoHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ShadCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document name with icon
            Row(
              children: [
                const Icon(
                  LucideIcons.fileText,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.document.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Info badges (square-ish)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.images, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_imagePaths.length} ${_imagePaths.length == 1 ? 'page' : 'pages'}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateExact(widget.document.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.circleAlert,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PDF preview not available',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'There was an error generating the preview',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ShadButton.outline(
              onPressed: _loadPdfPreview,
              leading: const Icon(LucideIcons.refreshCw, size: 16),
              child: const Text('Retry'),
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
          canShowScrollStatus: true,
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

    return ShadCard(
      padding: EdgeInsets.zero,
      height: isListView ? 280 : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            // Image fills the card
            Positioned.fill(child: imageWidget),
            // Page number badge at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page ${index + 1}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      LucideIcons.expand,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Document Options',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Options
              _buildOptionTile(
                icon: LucideIcons.share2,
                title: 'Share PDF',
                subtitle: 'Share document via other apps',
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf();
                },
              ),
              _buildOptionTile(
                icon: LucideIcons.download,
                title: 'Download PDF',
                subtitle: 'Save to Downloads folder',
                onTap: () {
                  Navigator.pop(context);
                  _savePdfLocally();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Divider(
                  color: AppColors.border,
                  height: 1,
                ),
              ),
              _buildOptionTile(
                icon: LucideIcons.trash2,
                title: 'Delete Document',
                subtitle: 'Permanently remove this document',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconBgColor = isDestructive
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
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
          'This will permanently delete "${widget.document.name}" and all its pages. This action cannot be undone.',
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
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
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
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
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

  String _formatDateExact(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  void _showSnackBar(String message) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
  }
}
