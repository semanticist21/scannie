import 'dart:io';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/pdf_generator.dart';
import '../services/document_storage.dart';
import '../services/export_service.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../models/context_menu_item.dart';
import '../widgets/common/context_menu_sheet.dart';
import '../widgets/viewer/document_info_header.dart';
import '../utils/app_toast.dart';
import '../widgets/viewer/page_card.dart';
import '../widgets/common/pdf_options_sheet.dart';
import '../widgets/common/rename_dialog.dart';
import '../widgets/common/tag_dialog.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/empty_state.dart';
import '../utils/app_modal.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

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
        pageSize: _document.pdfPageSize,
        orientation: _document.pdfOrientation,
        imageFit: _document.pdfImageFit,
        margin: _document.pdfMargin,
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
      backgroundColor: ThemedColors.of(context).background,
      appBar: CustomAppBar(
        title: '',
        actions: [
          if (_imagePaths.isNotEmpty)
            IconButton(
              icon:
                  Icon(_isGridView ? LucideIcons.list : LucideIcons.layoutGrid),
              onPressed: () {
                setState(() => _isGridView = !_isGridView);
              },
              tooltip:
                  _isGridView ? 'viewer.listView'.tr() : 'viewer.gridView'.tr(),
            ),
          if (_imagePaths.isNotEmpty)
            IconButton(
              icon: Icon(
                LucideIcons.download,
                color: ShadTheme.of(context).colorScheme.primary,
              ),
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
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _isGridView
                                      ? _buildGridView()
                                      : _buildListView(),
                                ),
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
          color: ThemedColors.of(context).textSecondary,
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
                AppGap.hSm,
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
                AppGap.hSm,
                Text('common.pdf'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    final colors = ThemedColors.of(context);

    if (_isLoadingPdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'viewer.generatingPdfPreview'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
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
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'viewer.preparingPdf'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate aspect ratio based on page size and orientation
    final pageSize = _document.pdfPageSize;
    final isLandscape = _document.pdfOrientation == PdfOrientation.landscape;

    double aspectRatio;
    switch (pageSize) {
      case PdfPageSize.a4:
        aspectRatio = isLandscape ? 297 / 210 : 210 / 297;
        break;
      case PdfPageSize.letter:
        aspectRatio = isLandscape ? 11 / 8.5 : 8.5 / 11;
        break;
      case PdfPageSize.legal:
        aspectRatio = isLandscape ? 14 / 8.5 : 8.5 / 14;
        break;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: ThemedColors.of(context).border,
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
                  autoSpacing: false,
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
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
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
                                fontWeight: AppFontWeight.semiBold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.darkTextPrimary,
                                  inactiveTrackColor: AppColors.darkTextSecondary,
                                  thumbColor: AppColors.darkTextPrimary,
                                  overlayColor: AppColors.darkOverlay,
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
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
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$_totalPdfPages',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.darkTextPrimary,
                                fontWeight: AppFontWeight.semiBold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: LucideIcons.sparkles,
      title: 'viewer.noPagesTitle'.tr(),
      subtitle: 'viewer.noPagesSubtitle'.tr(),
      actionText: 'viewer.noPagesAction'.tr(),
      onActionTap: _editScan,
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      key: const ValueKey('grid_view'),
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
      key: const ValueKey('list_view'),
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
        icon: LucideIcons.tag,
        label: _document.hasTag
            ? 'dialogs.editTag'.tr()
            : 'dialogs.addTag'.tr(),
        onTap: () {
          Navigator.pop(context);
          _editTag();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.settings2,
        label: 'viewer.pdfOptions'.tr(),
        onTap: () {
          Navigator.pop(context);
          _showPdfOptions();
        },
      ),
      ContextMenuItem(
        icon: LucideIcons.trash2,
        label: 'common.delete'.tr(),
        color: ThemedColors.of(context).error,
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

      // Reload PDF
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

  /// Edit tag
  void _editTag() {
    TagDialog.show(
      context: context,
      currentTagText: _document.tagText,
      currentTagColor: _document.tagColor,
      onSave: (tagText, tagColor) async {
        // Update local state
        setState(() {
          if (tagText == null) {
            _document = _document.copyWith(clearTag: true);
          } else {
            _document = _document.copyWith(tagText: tagText, tagColor: tagColor);
          }
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

  void _showPdfOptions() {
    PdfOptionsSheet.show(
      context: context,
      quality: _document.pdfQuality,
      pageSize: _document.pdfPageSize,
      orientation: _document.pdfOrientation,
      imageFit: _document.pdfImageFit,
      margin: _document.pdfMargin,
      onSave: _updatePdfOptions,
    );
  }

  void _updatePdfOptions(
    PdfQuality quality,
    PdfPageSize pageSize,
    PdfOrientation orientation,
    PdfImageFit imageFit,
    PdfMargin margin,
  ) async {
    debugPrint('📥 _updatePdfOptions received:');
    debugPrint('  - quality: $quality (${quality.name})');
    debugPrint('  - pageSize: $pageSize (${pageSize.name})');
    debugPrint('  - orientation: $orientation (${orientation.name})');
    debugPrint('  - imageFit: $imageFit (${imageFit.name})');
    debugPrint('  - margin: $margin (${margin.name})');
    debugPrint('📄 Current _document values:');
    debugPrint(
        '  - quality: ${_document.pdfQuality} (${_document.pdfQuality.name})');
    debugPrint(
        '  - pageSize: ${_document.pdfPageSize} (${_document.pdfPageSize.name})');
    debugPrint(
        '  - orientation: ${_document.pdfOrientation} (${_document.pdfOrientation.name})');
    debugPrint(
        '  - imageFit: ${_document.pdfImageFit} (${_document.pdfImageFit.name})');
    debugPrint(
        '  - margin: ${_document.pdfMargin} (${_document.pdfMargin.name})');

    // Check if any option changed
    if (quality == _document.pdfQuality &&
        pageSize == _document.pdfPageSize &&
        orientation == _document.pdfOrientation &&
        imageFit == _document.pdfImageFit &&
        margin == _document.pdfMargin) {
      debugPrint('  → No changes, returning');
      return;
    }

    debugPrint('  → Saving changes...');

    setState(() {
      _document = _document.copyWith(
        pdfQuality: quality,
        pdfPageSize: pageSize,
        pdfOrientation: orientation,
        pdfImageFit: imageFit,
        pdfMargin: margin,
      );
    });

    // Save to storage
    final documents = await DocumentStorage.loadDocuments();
    final index = documents.indexWhere((doc) => doc.id == _document.id);
    if (index != -1) {
      documents[index] = _document;
      await DocumentStorage.saveDocuments(documents);
    }

    // Reload PDF with new options
    _loadPdfPreview();
  }

  /// Show delete confirmation dialog
  void _confirmDelete() {
    ConfirmDialog.show(
      context: context,
      title: 'dialogs.deleteScan'.tr(),
      message:
          'dialogs.deleteScanMessage'.tr(namedArgs: {'name': _document.name}),
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
      AppToast.show(context, 'toast.failedToDeleteDocument'.tr(),
          isError: true);
    }
  }

  /// Export document to PDF and share
  Future<void> _exportToPdf() async {
    final notification = AppToast.info(context, 'viewer.preparingPdf'.tr());
    final result = await ExportService.instance.sharePdf(_document);
    AppToast.dismiss(notification);
    if (!mounted) return;

    if (result.isError) {
      AppToast.show(context, 'toast.failedToExportPdf'.tr(), isError: true);
    }
    // No toast for success - share dialog is self-explanatory
  }

  /// Save PDF using system file picker
  Future<void> _savePdfLocally() async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'viewer.preparingPdf'.tr());
    final result = await ExportService.instance.savePdfWithPicker(_document);
    AppToast.dismiss(notification);
    if (!mounted) return;
    AppToast.showExportResult(context, result);
  }

  /// Save images as ZIP using system file picker
  Future<void> _saveAsZip() async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'gallery.preparingZip'.tr());
    final result = await ExportService.instance.saveZipWithPicker(_document);
    AppToast.dismiss(notification);
    if (!mounted) return;
    AppToast.showExportResult(context, result);
  }

  /// Save individual images to gallery
  void _saveImages() async {
    final imageCount = _imagePaths.length;

    final confirmed = await ConfirmDialog.showAsync(
      context: context,
      title: 'viewer.downloadImagesTitle'.tr(),
      message: 'viewer.downloadImagesMessage'
          .tr(namedArgs: {'count': imageCount.toString()}),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.download'.tr(),
    );

    if (!confirmed || !mounted) return;

    // Create cancellation token
    final cancelToken = ValueNotifier<bool>(false);
    ExportResult? result;

    // Show loading dialog with cancel button
    AppModal.showDialog(
      context: context,
      barrierDismissible: false,
      pageListBuilder: (modalContext) {
        final colors = ThemedColors.of(modalContext);
        return [
          WoltModalSheetPage(
            backgroundColor: colors.surface,
            hasSabGradient: false,
            hasTopBarLayer: false,
            isTopBarLayerAlwaysVisible: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'viewer.downloadingImages'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ShadButton.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.x, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text('common.cancel'.tr()),
                      ],
                    ),
                    onPressed: () {
                      cancelToken.value = true;
                      Navigator.of(modalContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );

    // Run save operation
    result = await ExportService.instance.saveImagesToGalleryCancellable(
      _imagePaths,
      cancelToken,
    );

    // Close loading dialog if still open and not cancelled
    if (mounted && !cancelToken.value) {
      Navigator.of(context).pop();
    }

    // Show result toast
    if (mounted) {
      AppToast.showExportResult(context, result);
    }
  }
}
