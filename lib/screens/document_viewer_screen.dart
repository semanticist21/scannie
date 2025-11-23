import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:archive/archive.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/pdf_generator.dart';
import '../services/document_storage.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../models/context_menu_item.dart';
import '../widgets/common/context_menu_sheet.dart';
import '../widgets/common/document_info_header.dart';
import '../utils/app_toast.dart';
import '../widgets/common/page_card.dart';
import '../widgets/common/quality_selector_sheet.dart';
import '../widgets/common/rename_dialog.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/empty_state.dart';

/// Creates ZIP archive from image paths in a separate isolate
Future<List<int>?> _createZipArchive(List<String> imagePaths) async {
  final archive = Archive();

  for (int i = 0; i < imagePaths.length; i++) {
    final imageFile = File(imagePaths[i]);
    if (!imageFile.existsSync()) continue;

    final bytes = imageFile.readAsBytesSync();
    final extension = imagePaths[i].split('.').last.toLowerCase();
    final fileName = 'page_${(i + 1).toString().padLeft(2, '0')}.$extension';

    archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
  }

  return ZipEncoder().encode(archive);
}

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
  PDFViewController? _pdfController;

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
    // Calculate size first (fast operation)
    await _calculateTotalSize();

    // Mark initial loading as complete immediately
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }

    // Load PDF in background (doesn't block UI)
    if (_imagePaths.isNotEmpty) {
      _loadPdfPreview();
    }
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
      backgroundColor: AppColors.neumorphicBase,
      appBar: CustomAppBar(
        title: '',
        actions: [
          if (_imagePaths.isNotEmpty)
            IconButton(
              icon: Icon(_isGridView ? LucideIcons.list : LucideIcons.layoutGrid),
              onPressed: () {
                setState(() => _isGridView = !_isGridView);
              },
              tooltip: _isGridView ? 'viewer.listView'.tr() : 'viewer.gridView'.tr(),
            ),
          if (_imagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.download),
              onPressed: _showExportOptions,
              tooltip: 'viewer.exportPdf'.tr(),
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
        'common.loading'.tr(),
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
                Text('common.pages'.tr()),
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
                Text('common.pdf'.tr()),
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
              'viewer.generatingPdfPreview'.tr(),
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
              'viewer.preparingPdf'.tr(),
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
              onViewCreated: (controller) {
                _pdfController = controller;
              },
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
            // Page navigation overlay
            if (_totalPdfPages > 1)
              Positioned(
                bottom: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.shadowDarker,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${_currentPdfPage + 1}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.darkTextPrimary,
                            inactiveTrackColor: AppColors.darkTextSecondary,
                            thumbColor: AppColors.darkTextPrimary,
                            overlayColor: AppColors.darkOverlay,
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _currentPdfPage.toDouble(),
                            min: 0,
                            max: (_totalPdfPages - 1).toDouble(),
                            onChanged: (value) {
                              final page = value.round();
                              _pdfController?.setPage(page);
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$_totalPdfPages',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildEmptyState() {
    return EmptyState(
      icon: LucideIcons.sparkles,
      title: 'viewer.noPagesTitle'.tr(),
      subtitle: 'viewer.noPagesSubtitle'.tr(),
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
        label: 'viewer.downloadPdf'.tr(),
        onTap: () {
          Navigator.pop(context);
          _savePdfLocally();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.share2,
        label: 'viewer.sharePdf'.tr(),
        onTap: () {
          Navigator.pop(context);
          _exportToPdf();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.folderArchive,
        label: 'viewer.downloadAsZip'.tr(),
        onTap: () {
          Navigator.pop(context);
          _saveAsZip();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.images,
        label: 'viewer.downloadImages'.tr(),
        onTap: () {
          Navigator.pop(context);
          _saveImages();
        },
      ),
    ];

    ContextMenuSheet.show(
      context: context,
      title: 'common.export'.tr(),
      items: items,
    );
  }

  void _showOptions() {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: LucideIcons.filePen,
        label: 'viewer.editScan'.tr(),
        onTap: () {
          Navigator.pop(context);
          _editScan();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.pencil,
        label: 'common.rename'.tr(),
        onTap: () {
          Navigator.pop(context);
          _renameDocument();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.settings2,
        label: 'viewer.pdfQuality'.tr(namedArgs: {'quality': 'pdfQuality.${_document.pdfQuality.name}'.tr()}),
        onTap: () {
          Navigator.pop(context);
          _showQualitySelector();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.trash2,
        label: 'common.delete'.tr(),
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
    }
  }

  /// Rename document
  void _renameDocument() {
    RenameDialog.show(
      context: context,
      currentName: _document.name,
      onSave: (newName) async {
        // Update local state
        setState(() {
          _document = _document.copyWith(name: newName);
        });

        // Save to storage
        final documents = await DocumentStorage.loadDocuments();
        final index = documents.indexWhere((doc) => doc.id == _document.id);
        if (index != -1) {
          documents[index] = _document;
          await DocumentStorage.saveDocuments(documents);
        }
      },
    );
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
  void _confirmDelete() {
    ConfirmDialog.show(
      context: context,
      title: 'dialogs.deleteScan'.tr(),
      message: 'dialogs.deleteScanMessage'.tr(namedArgs: {'name': _document.name}),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.delete'.tr(),
      isDestructive: true,
      onConfirm: () async {
        await _deleteDocument();
      },
    );
  }

  /// Delete the document and return to gallery
  Future<void> _deleteDocument() async {
    try {
      final storage = DocumentStorage();
      await storage.deleteDocument(_document.id);

      if (!mounted) return;

      AppToast.show(context, 'gallery.documentDeleted'.tr());

      // Return to gallery with delete flag
      final navigator = Navigator.of(context);
      navigator.pop({'deleted': true, 'documentId': _document.id});
    } catch (e) {
      debugPrint('Error deleting document: $e');
      AppToast.show(context, 'toast.failedToDeleteDocument'.tr(), isError: true);
    }
  }

  /// Export document to PDF and share
  Future<void> _exportToPdf() async {
    final notification = AppToast.info(context, 'viewer.preparingPdf'.tr());

    try {
      // Generate PDF with quality setting
      final pdfFile = await PdfGenerator.generatePdf(
        imagePaths: _document.imagePaths,
        documentName: _document.name,
        quality: _document.pdfQuality,
      );

      notification.dismiss();
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
      notification.dismiss();
      debugPrint('Error exporting PDF: $e');
      if (!mounted) return;
      AppToast.show(context, 'toast.failedToExportPdf'.tr(), isError: true);
    }
  }

  /// Save PDF to Downloads folder using MediaStore
  Future<void> _savePdfLocally() async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'viewer.preparingPdf'.tr());

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

      notification.dismiss();
      // Open file manager to show the downloaded file
      if (!mounted) return;
      await openFileManager();
    } catch (e) {
      notification.dismiss();
      debugPrint('Error saving PDF: $e');
      if (!mounted) return;
      AppToast.show(context, 'toast.failedToSavePdf'.tr(), isError: true);
    }
  }

  /// Save images as ZIP to Downloads folder
  Future<void> _saveAsZip() async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'gallery.preparingZip'.tr());

    try {
      // Create archive in separate isolate
      final zipData = await compute(_createZipArchive, _imagePaths);
      if (zipData == null) {
        notification.dismiss();
        if (!mounted) return;
        AppToast.show(context, 'toast.failedToCreateZip'.tr(), isError: true);
        return;
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${_document.name}_$timestamp.zip';

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(zipData);

      // Initialize MediaStore
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'Scannie';

      // Save to Downloads folder using MediaStore
      final mediaStore = MediaStore();
      final saveInfo = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: FilePath.root,
      );

      debugPrint('ZIP saved to MediaStore: ${saveInfo?.uri}');

      notification.dismiss();
      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      notification.dismiss();
      debugPrint('Error saving ZIP: $e');
      if (!mounted) return;
      AppToast.show(context, 'toast.failedToSaveZip'.tr(), isError: true);
    }
  }

  /// Save individual images to gallery
  void _saveImages() {
    final imageCount = _imagePaths.length;

    ConfirmDialog.show(
      context: context,
      title: 'viewer.downloadImagesTitle'.tr(),
      message: 'viewer.downloadImagesMessage'.tr(namedArgs: {'count': imageCount.toString()}),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.download'.tr(),
      onConfirm: () async {
        try {
          int savedCount = 0;

          for (int i = 0; i < _imagePaths.length; i++) {
            final imageFile = File(_imagePaths[i]);
            if (!await imageFile.exists()) continue;

            final result = await ImageGallerySaverPlus.saveFile(imageFile.path);
            if (result['isSuccess'] == true) {
              savedCount++;
            }
          }

          if (!mounted) return;
          if (savedCount == 0) {
            AppToast.show(context, 'toast.failedToSaveImages'.tr(), isError: true);
          }
        } catch (e) {
          debugPrint('Error saving images: $e');
          if (!mounted) return;
          AppToast.show(context, 'toast.failedToSaveImages'.tr(), isError: true);
        }
      },
    );
  }
}
