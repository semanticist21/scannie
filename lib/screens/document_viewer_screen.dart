import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ndialog/ndialog.dart';
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
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/pdf_generator.dart';
import '../services/document_storage.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/common/context_menu_sheet.dart';
import '../widgets/common/document_info_header.dart';
import '../utils/app_toast.dart';
import '../widgets/common/page_card.dart';
import '../widgets/common/quality_selector_sheet.dart';

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
  File? _cachedPdfFile;
  bool _isLoadingPdf = false;
  bool _showPdfPreview = false;
  late TabController _tabController;
  int _totalFileSize = 0;
  bool _isInitialLoading = true;
  int _currentPdfPage = 0;
  int _totalPdfPages = 0;

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

    // Defer operations to after screen transition completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // Run both operations in parallel
    await Future.wait([
      _calculateTotalSize(),
      _loadPdfPreviewInitial(),
    ]);

    // Mark initial loading as complete
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadPdfPreviewInitial() async {
    if (_imagePaths.isEmpty) {
      return;
    }

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    await _loadPdfPreview();
  }

  Future<void> _calculateTotalSize() async {
    int total = 0;
    for (final imagePath in _imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    if (mounted) {
      setState(() {
        _totalFileSize = total;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load PDF preview
  Future<void> _loadPdfPreview() async {
    // Skip if no images
    if (_imagePaths.isEmpty) return;

    setState(() => _isLoadingPdf = true);

    try {
      final pdfFile = await PdfGenerator.generatePdf(
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
            icon: const Icon(LucideIcons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _isInitialLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Document info card with gradient
                DocumentInfoHeader(
                  document: _document,
                  cachedPdfFile: _cachedPdfFile,
                ),

                // Tab bar for Pages/PDF toggle
                if (_imagePaths.isNotEmpty) _buildTabBar(),

                // Content area - Stack with fade animation (keeps PDF cached)
                Expanded(
                  child: _imagePaths.isEmpty
                      ? _buildEmptyState()
                      : Stack(
                          children: [
                            // Pages view - fades out when PDF is shown
                            AnimatedOpacity(
                              opacity: _showPdfPreview ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: _showPdfPreview,
                                child: _isGridView
                                    ? _buildGridView()
                                    : _buildListView(),
                              ),
                            ),
                            // PDF view - fades in when selected (stays in memory)
                            AnimatedOpacity(
                              opacity: _showPdfPreview ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_showPdfPreview,
                                child: _buildPdfPreview(),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Text(
        'Loading...',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
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
      // Show loading state (PDF loading starts from initState)
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
        child: Stack(
          children: [
            PDFView(
              filePath: _cachedPdfFile!.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) {
                setState(() {
                  _totalPdfPages = pages ?? 0;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPdfPage = page ?? 0;
                  if (total != null) _totalPdfPages = total;
                });
              },
            ),
            // Page indicator overlay
            if (_totalPdfPages > 0)
              Positioned(
                bottom: AppSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                    ),
                    child: Text(
                      '${_currentPdfPage + 1} / $_totalPdfPages',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 210 / 297, // A4 ratio
      ),
      itemCount: _imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = _imagePaths[index];
        final imageFile = File(imagePath);

        return PageCard(
          key: ValueKey(imagePath),
          index: index,
          imageFile: imageFile,
          onTap: () => _viewFullScreen(index),
          isListView: false,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = _imagePaths[index];
        final imageFile = File(imagePath);
        return Padding(
          key: ValueKey(imagePath),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PageCard(
            index: index,
            imageFile: imageFile,
            onTap: () => _viewFullScreen(index),
            isListView: true,
          ),
        );
      },
    );
  }

  void _viewFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _imagePaths,
          initialPage: index,
          showFilters: false,
        ),
      ),
    );
  }

  void _showExportOptions() {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: LucideIcons.download,
        label: 'Save PDF',
        onTap: () {
          Navigator.pop(context);
          _savePdfLocally();
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
    ];

    ContextMenuSheet.show(
      context: context,
      title: 'Export',
      items: items,
    );
  }

  void _showOptions() {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: LucideIcons.filePen,
        label: 'Edit Scan',
        onTap: () {
          Navigator.pop(context);
          _editScan();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.pencil,
        label: 'Rename',
        onTap: () {
          Navigator.pop(context);
          _renameDocument();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.settings2,
        label: 'PDF Quality (${_document.pdfQuality.displayName})',
        onTap: () {
          Navigator.pop(context);
          _showQualitySelector();
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

  /// Edit scan - navigate to EditScreen to add/delete/reorder images
  void _editScan() async {
    final navigator = Navigator.of(context);

    // Navigate to EditScreen with entire document
    final result = await navigator.pushNamed(
      '/edit',
      arguments: _document,
    );

    // If user saved changes, update the document
    if (result != null && result is ScanDocument && mounted) {
      setState(() {
        _document = result;
        _imagePaths = List.from(result.imagePaths);
        _cachedPdfFile = null; // Invalidate PDF cache
      });

      // Recalculate size and reload PDF
      _calculateTotalSize();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _imagePaths.isNotEmpty) {
          _loadPdfPreview();
        }
      });

      AppToast.show(context,'Scan updated successfully');
    }
  }

  /// Rename document
  void _renameDocument() {
    final TextEditingController controller =
        TextEditingController(text: _document.name);

    DialogBackground(
      blur: 6,
      dismissable: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      dialog: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rename Scan',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter a new name for this document',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ShadInput(
                  controller: controller,
                  placeholder: const Text('Document name'),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShadButton(
                      child: const Text('Save'),
                      onPressed: () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) {
                          AppToast.show(context,'Name cannot be empty', isError: true);
                          return;
                        }

                        Navigator.of(context).pop();

                        // Update local state
                        setState(() {
                          _document = _document.copyWith(name: newName);
                        });

                        // Save to storage
                        final documents = await DocumentStorage.loadDocuments();
                        final index = documents
                            .indexWhere((doc) => doc.id == _document.id);
                        if (index != -1) {
                          documents[index] = _document;
                          await DocumentStorage.saveDocuments(documents);
                        }

                        if (!mounted) return;
                        AppToast.show(context,'Document renamed');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);
  }

  void _showQualitySelector() {
    QualitySelectorSheet.show(
      context: context,
      currentQuality: _document.pdfQuality,
      totalFileSize: _totalFileSize,
      onQualitySelected: _updateQuality,
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
    DialogBackground(
      blur: 6,
      dismissable: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      dialog: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Document?',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This will permanently delete "${_document.name}" and all its pages. This action cannot be undone.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShadButton.destructive(
                      child: const Text('Delete'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _deleteDocument();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);
  }

  /// Delete the document and return to gallery
  Future<void> _deleteDocument() async {
    try {
      final storage = DocumentStorage();
      await storage.deleteDocument(_document.id);

      if (!mounted) return;

      AppToast.show(context,'Document deleted');

      // Return to gallery with delete flag
      final navigator = Navigator.of(context);
      navigator.pop({'deleted': true, 'documentId': _document.id});
    } catch (e) {
      debugPrint('Error deleting document: $e');
      AppToast.show(context,'Failed to delete document', isError: true);
    }
  }

  /// Export document to PDF and share
  Future<void> _exportToPdf() async {
    try {
      AppToast.info(context, 'Preparing PDF...');

      // Generate PDF with quality setting
      final pdfFile = await PdfGenerator.generatePdf(
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
      if (!mounted) return;
      AppToast.show(context,'Failed to export PDF', isError: true);
    }
  }

  /// Save PDF to Downloads folder using MediaStore
  Future<void> _savePdfLocally() async {
    if (!mounted) return;
    AppToast.info(context, 'Preparing PDF...');

    try {
      // Generate PDF with quality setting
      final pdfFile = await PdfGenerator.generatePdf(
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
      AppToast.show(context,'PDF saved to Downloads');

      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (!mounted) return;
      AppToast.show(context,'Failed to save PDF', isError: true);
    }
  }

}
