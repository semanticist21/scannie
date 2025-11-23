import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_generator.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/common/scan_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/document_grid_card.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../utils/app_toast.dart';
import '../widgets/common/quality_selector_sheet.dart';
import '../widgets/common/rename_dialog.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/text_input_dialog.dart';
import '../widgets/common/premium_dialog.dart';
import '../widgets/common/settings_sheet.dart';
import '../main.dart' show routeObserver;

/// Creates ZIP archive from image paths in a separate isolate
Future<List<int>?> _createZipArchiveGallery(List<String> imagePaths) async {
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

/// Gallery screen displaying scanned documents
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with RouteAware {
  List<ScanDocument> _documents = [];
  bool _isGridView = false;
  bool _isLoading = true;
  bool _isPremium = false;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedDocumentIds = {};

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // Filtered documents for search
  List<ScanDocument> get _filteredDocuments {
    if (_searchQuery.isEmpty) return _documents;
    final query = _searchQuery.toLowerCase();
    return _documents
        .where((doc) => doc.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadDocuments();
    _loadPremiumStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen from another route
    // Reload documents to reflect any changes
    _loadDocuments();
  }

  /// Handle search input with debounce for performance
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
      }
    });
  }

  /// Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        // Focus after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchQuery = '';
        _debounceTimer?.cancel();
        _searchFocusNode.unfocus();
      }
    });
  }

  /// Load premium status from persistent storage
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool('isPremium') ?? false;
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      debugPrint('Failed to load premium status: $e');
    }
  }

  /// Save premium status to persistent storage
  Future<void> _savePremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', isPremium);
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      debugPrint('Failed to save premium status: $e');
    }
  }

  /// Check if user can add more documents (premium or no documents yet)
  bool _canAddDocument() {
    return _isPremium || _documents.isEmpty;
  }

  /// Load view mode preference from persistent storage
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGridView = prefs.getBool('isGridView') ?? false;
      if (mounted) {
        setState(() {
          _isGridView = isGridView;
        });
      }
    } catch (e) {
      debugPrint('Failed to load view mode: $e');
    }
  }

  /// Save view mode preference to persistent storage
  Future<void> _saveViewMode(bool isGridView) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGridView', isGridView);
    } catch (e) {
      debugPrint('Failed to save view mode: $e');
    }
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedDocumentIds.clear();
      }
    });
  }

  /// Toggle document selection
  void _toggleDocumentSelection(String documentId) {
    setState(() {
      if (_selectedDocumentIds.contains(documentId)) {
        _selectedDocumentIds.remove(documentId);
      } else {
        _selectedDocumentIds.add(documentId);
      }
    });
  }

  /// Delete selected documents
  Future<void> _deleteSelectedDocuments() async {
    if (_selectedDocumentIds.isEmpty) return;

    final count = _selectedDocumentIds.length;
    final confirmed = await ConfirmDialog.showAsync(
      context: context,
      title: 'gallery.deleteScans'.tr(namedArgs: {'count': count.toString()}),
      message: 'gallery.actionCannotBeUndone'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.delete'.tr(),
      isDestructive: true,
    );

    if (confirmed && mounted) {
      setState(() {
        _documents.removeWhere((doc) => _selectedDocumentIds.contains(doc.id));
        _selectedDocumentIds.clear();
        _isSelectionMode = false;
      });
      await _saveDocuments();
      if (mounted) {
        AppToast.show(context,
            'gallery.deletedScans'.tr(namedArgs: {'count': count.toString()}));
      }
    }
  }

  /// Show settings sheet
  void _showSettingsSheet() {
    // Map current locale to AppLanguage
    final currentLocale = context.locale;
    final currentLanguage = currentLocale.languageCode == 'ko'
        ? AppLanguage.korean
        : AppLanguage.english;

    SettingsSheet.show(
      context: context,
      isGridView: _isGridView,
      onViewModeChanged: (isGridView) {
        setState(() => _isGridView = isGridView);
        _saveViewMode(isGridView);
      },
      isPremium: _isPremium,
      onPremiumTap: () => PremiumDialog.show(
        context,
        isPremium: _isPremium,
        onPurchase: () => _savePremiumStatus(true),
      ),
      currentLanguage: currentLanguage,
      onLanguageChanged: (language) {
        // Change app locale
        final newLocale = language == AppLanguage.korean
            ? const Locale('ko')
            : const Locale('en');
        context.setLocale(newLocale);
      },
    );
  }

  /// Load documents from persistent storage
  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final documents = await DocumentStorage.loadDocuments();
      if (mounted) {
        setState(() {
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(
            context,
            'toast.failedToLoadDocuments'
                .tr(namedArgs: {'error': e.toString()}),
            isError: true);
      }
    }
  }

  /// Save documents to persistent storage
  Future<void> _saveDocuments() async {
    try {
      await DocumentStorage.saveDocuments(_documents);
    } catch (e) {
      debugPrint('Failed to save documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: _isSelectionMode
            ? Text(
                _selectedDocumentIds.isEmpty
                    ? 'gallery.selectItems'.tr()
                    : 'gallery.selectedCount'.tr(namedArgs: {
                        'count': _selectedDocumentIds.length.toString()
                      }),
              )
            : Text('gallery.title'.tr()),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'tooltips.cancel'.tr(),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: _selectedDocumentIds.isEmpty
                      ? null
                      : _deleteSelectedDocuments,
                  tooltip: 'tooltips.delete'.tr(),
                ),
              ]
            : _isSearching
                ? [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: UnconstrainedBox(
                              constrainedAxis: Axis.horizontal,
                              child: Container(
                                width: 200,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.neumorphicBase,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    // Inner shadow (top-left light)
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                    // Inner shadow (bottom-right dark)
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'gallery.searchPlaceholder'.tr(),
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textHint,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      key: const ValueKey('close_search'),
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: _toggleSearch,
                      tooltip: 'tooltips.close'.tr(),
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(LucideIcons.listChecks),
                      onPressed: _toggleSelectionMode,
                      tooltip: 'tooltips.select'.tr(),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.search),
                      onPressed: _toggleSearch,
                      tooltip: 'tooltips.search'.tr(),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plus),
                      onPressed: _createEmptyDocument,
                      tooltip: 'tooltips.createEmptyDocument'.tr(),
                    ),
                    IconButton(
                      key: const ValueKey('settings'),
                      icon: const Icon(LucideIcons.settings),
                      onPressed: _showSettingsSheet,
                      tooltip: 'tooltips.settings'.tr(),
                    ),
                  ],
      ),
      backgroundColor: AppColors.neumorphicBase,
      body: SizedBox.expand(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? _buildEmptyState()
                : _isSearching && _filteredDocuments.isEmpty
                    ? _buildNoSearchResults()
                    : _buildDocumentList(),
      ),
      floatingActionButton: _isSearching
          ? null
          : ShadButton(
              onPressed: _openCamera,
              leading: const Icon(LucideIcons.camera, size: 18),
              child: Text('common.scan'.tr()),
            ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: LucideIcons.sparkles,
      title: 'gallery.noScansTitle'.tr(),
      subtitle: 'gallery.noScansSubtitle'.tr(),
      verticalOffset: -40,
    );
  }

  Widget _buildNoSearchResults() {
    return EmptyState(
      icon: LucideIcons.searchX,
      title: 'gallery.noResultsTitle'.tr(),
      subtitle: 'gallery.noResultsSubtitle'.tr(),
      verticalOffset: -40,
    );
  }

  Widget _buildDocumentList() {
    if (_isGridView) {
      return _buildGridView();
    }

    final documents = _isSearching ? _filteredDocuments : _documents;

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxl * 2,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ScanCard(
          document: document,
          onTap: () => _openDocument(document),
          onEdit: () => _editDocumentName(document),
          onEditScan: () => _editScan(document),
          onDelete: () => _deleteDocument(document),
          onSavePdf: () => _savePdfDocument(document),
          onShare: () => _sharePdfDocument(document),
          onSaveZip: () => _saveZipDocument(document),
          onSaveImages: () => _saveImagesDocument(document),
          onQualityChange: () => _showQualitySelector(document),
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedDocumentIds.contains(document.id),
          onSelect: () => _toggleDocumentSelection(document.id),
        );
      },
    );
  }

  Widget _buildGridView() {
    final documents = _isSearching ? _filteredDocuments : _documents;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentGridCard(
          document: document,
          onTap: () => _openDocument(document),
          onEdit: () => _editDocumentName(document),
          onEditScan: () => _editScan(document),
          onDelete: () => _deleteDocument(document),
          onSavePdf: () => _savePdfDocument(document),
          onShare: () => _sharePdfDocument(document),
          onSaveZip: () => _saveZipDocument(document),
          onSaveImages: () => _saveImagesDocument(document),
          onQualityChange: () => _showQualitySelector(document),
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedDocumentIds.contains(document.id),
          onSelect: () => _toggleDocumentSelection(document.id),
        );
      },
    );
  }

  /// Create empty document with name input
  void _createEmptyDocument() {
    // Check premium status
    if (!_canAddDocument()) {
      PremiumDialog.show(context, onPurchase: () => _savePremiumStatus(true));
      return;
    }

    TextInputDialog.show(
      context: context,
      title: 'gallery.createNewDocument'.tr(),
      description: 'gallery.createNewDocumentDesc'.tr(),
      initialValue: 'Scan ${DateTime.now().toString().substring(0, 10)}',
      placeholder: 'gallery.documentNamePlaceholder'.tr(),
      confirmText: 'common.create'.tr(),
      onSave: (documentName) async {
        final newDocument = ScanDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: documentName,
          createdAt: DateTime.now(),
          imagePaths: [],
          isProcessed: true,
        );

        setState(() {
          _documents.insert(0, newDocument);
        });
        await _saveDocuments();

        if (!mounted) return;
        AppToast.show(context, 'gallery.emptyDocumentCreated'.tr());
      },
    );
  }

  Future<void> _openCamera() async {
    // Check premium status
    if (!_canAddDocument()) {
      PremiumDialog.show(context, onPurchase: () => _savePremiumStatus(true));
      return;
    }

    try {
      // Launch cunning_document_scanner_plus with filters mode
      // This allows users to apply filters during scanning
      final scannedImages = await CunningDocumentScanner.getPictures(
            mode: ScannerMode.full, // Enable AI Enhance + Clean features
            noOfPages:
                100, // Allow multiple pages (user taps Done when finished)
          ) ??
          [];

      if (!mounted) return;

      if (scannedImages.isEmpty) {
        // User cancelled or no documents scanned
        return;
      }

      // Convert to list of strings
      final List<String> imagePaths = scannedImages;

      // Debug: Print scanned image paths
      debugPrint('📸 Scanned ${imagePaths.length} images:');
      for (var path in imagePaths) {
        debugPrint('  - $path');
      }

      // Navigate to edit screen with scanned images
      final navigator = Navigator.of(context);
      final result = await navigator.pushNamed(
        '/edit',
        arguments: imagePaths,
      );

      // If a document was returned (e.g., editing existing), update the list
      // For new scans, EditScreen uses pushReplacementNamed to viewer,
      // so result will be null and documents are reloaded via didPopNext
      if (result != null && result is ScanDocument && mounted) {
        setState(() {
          _documents.insert(0, result);
        });
        await _saveDocuments();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      AppToast.show(
          context, 'toast.scanFailed'.tr(namedArgs: {'error': e.message ?? ''}),
          isError: true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
          context, 'toast.scanFailed'.tr(namedArgs: {'error': e.toString()}),
          isError: true);
    }
  }

  void _openDocument(ScanDocument document) async {
    // Navigate to document viewer
    final result = await Navigator.pushNamed(
      context,
      '/viewer',
      arguments: document,
    );

    // Handle delete result
    if (result is Map && result['deleted'] == true) {
      final deletedId = result['documentId'] as String;
      setState(() {
        _documents.removeWhere((doc) => doc.id == deletedId);
      });
    }
    // Reload documents to reflect any changes (e.g., quality updates)
    else {
      final updatedDocuments = await DocumentStorage.loadDocuments();
      setState(() {
        _documents = updatedDocuments;
      });
    }
  }

  void _editDocumentName(ScanDocument document) {
    RenameDialog.show(
      context: context,
      currentName: document.name,
      onSave: (newName) async {
        setState(() {
          final index = _documents.indexWhere((d) => d.id == document.id);
          if (index != -1) {
            _documents[index] = document.copyWith(name: newName);
          }
        });
        await _saveDocuments();
      },
    );
  }

  void _deleteDocument(ScanDocument document) {
    ConfirmDialog.show(
      context: context,
      title: 'dialogs.deleteScan'.tr(),
      message:
          'dialogs.deleteScanMessage'.tr(namedArgs: {'name': document.name}),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.delete'.tr(),
      isDestructive: true,
      onConfirm: () async {
        setState(() {
          _documents.removeWhere((d) => d.id == document.id);
        });
        await _saveDocuments();
        if (!mounted) return;
        AppToast.show(context, 'gallery.documentDeleted'.tr());
      },
    );
  }

  void _savePdfDocument(ScanDocument document) {
    _savePdfLocally(document);
  }

  void _sharePdfDocument(ScanDocument document) {
    _exportToPdf(document);
  }

  /// Show quality selector for document
  void _showQualitySelector(ScanDocument document) async {
    // Calculate total file size for the quality selector
    int totalSize = 0;
    for (final imagePath in document.imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    if (!mounted) return;

    QualitySelectorSheet.show(
      context: context,
      currentQuality: document.pdfQuality,
      totalFileSize: totalSize,
      onQualitySelected: (quality) async {
        if (quality == document.pdfQuality) return;

        // Update document with new quality
        final updatedDoc = document.copyWith(pdfQuality: quality);

        setState(() {
          final index = _documents.indexWhere((d) => d.id == document.id);
          if (index != -1) {
            _documents[index] = updatedDoc;
          }
        });

        await _saveDocuments();
      },
    );
  }

  /// Edit scan - navigate to EditScreen to add/delete/reorder images
  void _editScan(ScanDocument document) async {
    final navigator = Navigator.of(context);

    // Navigate to EditScreen with entire document (so name can be edited too)
    final result = await navigator.pushNamed(
      '/edit',
      arguments: document, // Pass entire ScanDocument
    );

    // If user saved changes, update the document
    if (result != null && result is ScanDocument && mounted) {
      setState(() {
        final index = _documents.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          // Replace with updated document (name and images)
          _documents[index] = result;
        }
      });
      await _saveDocuments();
      if (!mounted) return;
      AppToast.show(context, 'gallery.scanUpdated'.tr());
    }
  }

  /// Export document to PDF
  Future<void> _exportToPdf(ScanDocument document) async {
    final notification = AppToast.info(context, 'gallery.generatingPdf'.tr());

    try {
      // Generate PDF with quality setting
      final pdfFile = await PdfGenerator.generatePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
      );

      notification.dismiss();
      if (!mounted) return;

      // Generate filename for sharing
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.pdf';

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

  /// Save PDF to Downloads folder using MediaStore (no permission required)
  Future<void> _savePdfLocally(ScanDocument document) async {
    final notification = AppToast.info(context, 'gallery.generatingPdf'.tr());

    try {
      // Generate PDF with quality setting
      final pdfFile = await PdfGenerator.generatePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
      );

      // Generate filename
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.pdf';

      // Copy to new temp file with proper name
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));
      await pdfFile.copy(tempFile.path);

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
  Future<void> _saveZipDocument(ScanDocument document) async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'gallery.preparingZip'.tr());

    try {
      // Create archive in separate isolate
      final zipData =
          await compute(_createZipArchiveGallery, document.imagePaths);
      if (zipData == null) {
        notification.dismiss();
        if (!mounted) return;
        AppToast.show(context, 'toast.failedToCreateZip'.tr(), isError: true);
        return;
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.zip';

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
  void _saveImagesDocument(ScanDocument document) {
    final imageCount = document.imagePaths.length;

    ConfirmDialog.show(
      context: context,
      title: 'viewer.downloadImagesTitle'.tr(),
      message: 'viewer.downloadImagesMessage'
          .tr(namedArgs: {'count': imageCount.toString()}),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.download'.tr(),
      onConfirm: () async {
        try {
          int savedCount = 0;

          for (int i = 0; i < document.imagePaths.length; i++) {
            final imageFile = File(document.imagePaths[i]);
            if (!await imageFile.exists()) continue;

            final result = await ImageGallerySaverPlus.saveFile(imageFile.path);
            if (result['isSuccess'] == true) {
              savedCount++;
            }
          }

          if (!mounted) return;
          if (savedCount == 0) {
            AppToast.show(context, 'toast.failedToSaveImages'.tr(),
                isError: true);
          }
        } catch (e) {
          debugPrint('Error saving images: $e');
          if (!mounted) return;
          AppToast.show(context, 'toast.failedToSaveImages'.tr(),
              isError: true);
        }
      },
    );
  }
}
