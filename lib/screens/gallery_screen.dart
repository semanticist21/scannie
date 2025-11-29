import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_settings_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gallery/scan_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/gallery/document_grid_card.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_toast.dart';
import '../widgets/common/pdf_options_sheet.dart';
import '../widgets/common/rename_dialog.dart';
import '../widgets/common/tag_dialog.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/text_input_dialog.dart';
import '../widgets/gallery/premium_dialog.dart';
import '../widgets/gallery/settings_sheet.dart';
import '../main.dart' show routeObserver;

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

  // PDF settings
  PdfSettingsService? _pdfSettings;
  PdfQuality _defaultPdfQuality = PdfQuality.medium;
  PdfPageSize _defaultPdfPageSize = PdfPageSize.a4;
  PdfOrientation _defaultPdfOrientation = PdfOrientation.portrait;
  PdfImageFit _defaultPdfImageFit = PdfImageFit.contain;
  PdfMargin _defaultPdfMargin = PdfMargin.none;

  // Filtered documents for search (searches name and tag)
  List<ScanDocument> get _filteredDocuments {
    if (_searchQuery.isEmpty) return _documents;
    final query = _searchQuery.toLowerCase();
    return _documents.where((doc) {
      // Search in document name
      if (doc.name.toLowerCase().contains(query)) return true;
      // Search in tag text
      if (doc.tagText != null && doc.tagText!.toLowerCase().contains(query)) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadDocuments();
    _loadPremiumStatus();
    _loadPdfSettings();
  }

  Future<void> _loadPdfSettings() async {
    _pdfSettings = await PdfSettingsService.getInstance();
    if (mounted) {
      setState(() {
        _defaultPdfQuality = _pdfSettings!.defaultQuality;
        _defaultPdfPageSize = _pdfSettings!.defaultPageSize;
        _defaultPdfOrientation = _pdfSettings!.defaultOrientation;
        _defaultPdfImageFit = _pdfSettings!.defaultImageFit;
        _defaultPdfMargin = _pdfSettings!.defaultMargin;
      });
    }
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
    // Reload documents and premium status to reflect any changes
    _loadDocuments();
    _loadPremiumStatus();
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

  /// Check if user can add more documents
  /// Note: Document limit removed - ads shown instead for non-premium users
  bool _canAddDocument() {
    return true; // No document limit - ads monetization instead
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
  void _deleteSelectedDocuments() {
    if (_selectedDocumentIds.isEmpty) return;

    final count = _selectedDocumentIds.length;
    ConfirmDialog.show(
      context: context,
      title: 'gallery.deleteScans'.tr(namedArgs: {'count': count.toString()}),
      message: 'gallery.actionCannotBeUndone'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.delete'.tr(),
      isDestructive: true,
      onConfirm: () async {
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
      },
    );
  }

  /// Show settings sheet
  void _showSettingsSheet() {
    // Map current locale to AppLanguage (default to English if not found)
    final currentLocale = context.locale;
    final currentLanguage = AppLanguage.fromCode(currentLocale.languageCode)
        ?? AppLanguage.all.firstWhere((lang) => lang.code == 'en');

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
        onPurchaseComplete: () => _savePremiumStatus(true),
      ),
      currentLanguage: currentLanguage,
      onLanguageChanged: (language) {
        // Change app locale using the language code
        context.setLocale(Locale(language.code));
      },
      // PDF settings
      pdfQuality: _defaultPdfQuality,
      onPdfQualityChanged: (quality) async {
        setState(() => _defaultPdfQuality = quality);
        await _pdfSettings?.setDefaultQuality(quality);
      },
      pdfPageSize: _defaultPdfPageSize,
      onPdfPageSizeChanged: (size) async {
        setState(() => _defaultPdfPageSize = size);
        await _pdfSettings?.setDefaultPageSize(size);
      },
      pdfOrientation: _defaultPdfOrientation,
      onPdfOrientationChanged: (orientation) async {
        setState(() => _defaultPdfOrientation = orientation);
        await _pdfSettings?.setDefaultOrientation(orientation);
      },
      pdfImageFit: _defaultPdfImageFit,
      onPdfImageFitChanged: (fit) async {
        setState(() => _defaultPdfImageFit = fit);
        await _pdfSettings?.setDefaultImageFit(fit);
      },
      pdfMargin: _defaultPdfMargin,
      onPdfMarginChanged: (margin) async {
        setState(() => _defaultPdfMargin = margin);
        await _pdfSettings?.setDefaultMargin(margin);
      },
    );
  }

  /// Load documents from persistent storage
  Future<void> _loadDocuments() async {
    debugPrint('📥 _loadDocuments called');
    setState(() => _isLoading = true);

    try {
      final documents = await DocumentStorage.loadDocuments();
      debugPrint('📥 Loaded ${documents.length} documents from storage');
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
    debugPrint('🔄 build() called, documents: ${_documents.length}, isLoading: $_isLoading');
    return PopScope(
      canPop: !_isSelectionMode && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedDocumentIds.clear();
          });
        } else if (_isSearching) {
          _toggleSearch();
        }
      },
      child: Scaffold(
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
                                  color: ThemedColors.of(context).surface,
                                  borderRadius: BorderRadius.circular(AppRadius.mdd),
                                  border: Border.all(
                                    color: ThemedColors.of(context).border,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(fontSize: AppFontSize.smd),
                                  decoration: InputDecoration(
                                    hintText: 'gallery.searchPlaceholder'.tr(),
                                    hintStyle: TextStyle(
                                      fontSize: AppFontSize.smd,
                                      color: ThemedColors.of(context).textHint,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.ms,
                                      vertical: AppSpacing.smd,
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
      backgroundColor: ThemedColors.of(context).background,
      body: SizedBox.expand(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? _buildEmptyState()
                : _isSearching && _filteredDocuments.isEmpty
                    ? _buildNoSearchResults()
                    : _buildDocumentList(),
      ),
      floatingActionButton: _isSearching || _isSelectionMode
          ? null
          : ShadButton(
              onPressed: _openCamera,
              leading: const Icon(LucideIcons.camera, size: 18),
              child: Text('common.scan'.tr()),
            ),
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
    debugPrint('📋 _buildDocumentList called, count: ${_documents.length}, isGrid: $_isGridView');

    return AnimatedSwitcher(
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
    );
  }

  Widget _buildListView() {
    final documents = _isSearching ? _filteredDocuments : _documents;

    return ListView.builder(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxl * 2,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ScanCard(
          key: ValueKey(document.id),
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
          onTag: () => _editDocumentTag(document),
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
      key: const ValueKey('grid_view'),
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
          key: ValueKey(document.id),
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
          onTag: () => _editDocumentTag(document),
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
      PremiumDialog.show(context, onPurchaseComplete: () => _savePremiumStatus(true));
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
        debugPrint('➕ Creating document: $documentName, current count: ${_documents.length}');
        final newDocument = ScanDocument(
          id: const Uuid().v7(),
          name: documentName,
          createdAt: DateTime.now(),
          imagePaths: [],
          isProcessed: true,
          pdfQuality: _defaultPdfQuality,
          pdfPageSize: _defaultPdfPageSize,
          pdfOrientation: _defaultPdfOrientation,
          pdfImageFit: _defaultPdfImageFit,
          pdfMargin: _defaultPdfMargin,
        );

        setState(() {
          _documents.insert(0, newDocument);
        });
        debugPrint('➕ After insert, count: ${_documents.length}');
        await _saveDocuments();
      },
    );
  }

  Future<void> _openCamera() async {
    // Check premium status
    if (!_canAddDocument()) {
      PremiumDialog.show(context, onPurchaseComplete: () => _savePremiumStatus(true));
      return;
    }

    // Check camera permission first
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
      // Request permission if not permanently denied
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isGranted) {
          // Permission granted, continue with scanning
        } else {
          if (!mounted) return;
          _showCameraPermissionDialog();
          return;
        }
      } else {
        // Permanently denied - show dialog to open settings
        if (!mounted) return;
        _showCameraPermissionDialog();
        return;
      }
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

  void _showCameraPermissionDialog() {
    ConfirmDialog.show(
      context: context,
      title: 'permission.cameraRequired'.tr(),
      message: 'permission.cameraRequiredMessage'.tr(),
      confirmText: 'permission.openSettings'.tr(),
      onConfirm: () async {
        await openAppSettings();
      },
    );
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

  void _editDocumentTag(ScanDocument document) {
    TagDialog.show(
      context: context,
      currentTagText: document.tagText,
      currentTagColor: document.tagColor,
      onSave: (tagText, tagColor) async {
        setState(() {
          final index = _documents.indexWhere((d) => d.id == document.id);
          if (index != -1) {
            if (tagText == null) {
              _documents[index] = document.copyWith(clearTag: true);
            } else {
              _documents[index] = document.copyWith(tagText: tagText, tagColor: tagColor);
            }
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
        debugPrint('🗑️ Deleting document: ${document.name}, current count: ${_documents.length}');
        setState(() {
          _documents.removeWhere((d) => d.id == document.id);
        });
        debugPrint('🗑️ After delete, count: ${_documents.length}');
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

  /// Show PDF options for document
  void _showQualitySelector(ScanDocument document) {
    PdfOptionsSheet.show(
      context: context,
      quality: document.pdfQuality,
      pageSize: document.pdfPageSize,
      orientation: document.pdfOrientation,
      imageFit: document.pdfImageFit,
      margin: document.pdfMargin,
      onSave: (quality, pageSize, orientation, imageFit, margin) async {
        // Check if any option changed
        if (quality == document.pdfQuality &&
            pageSize == document.pdfPageSize &&
            orientation == document.pdfOrientation &&
            imageFit == document.pdfImageFit &&
            margin == document.pdfMargin) {
          return;
        }

        // Update document with new options
        final updatedDoc = document.copyWith(
          pdfQuality: quality,
          pdfPageSize: pageSize,
          pdfOrientation: orientation,
          pdfImageFit: imageFit,
          pdfMargin: margin,
        );

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
    // Note: Toast is already shown by EditScreen, no need to show here
    if (result != null && result is ScanDocument && mounted) {
      setState(() {
        final index = _documents.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          // Replace with updated document (name and images)
          _documents[index] = result;
        }
      });
      await _saveDocuments();
    }
  }

  /// Share PDF via system share sheet
  Future<void> _exportToPdf(ScanDocument document) async {
    final notification = AppToast.info(context, 'gallery.generatingPdf'.tr());

    final result = await ExportService.instance.sharePdf(document);

    AppToast.dismiss(notification);
    if (!mounted) return;

    AppToast.showExportResult(context, result);
  }

  /// Save PDF using system file picker (user chooses location)
  Future<void> _savePdfLocally(ScanDocument document) async {
    final notification = AppToast.info(context, 'gallery.generatingPdf'.tr());

    final result = await ExportService.instance.savePdfWithPicker(document);

    AppToast.dismiss(notification);
    if (!mounted) return;

    AppToast.showExportResult(context, result);
  }

  /// Save ZIP using system file picker (user chooses location)
  Future<void> _saveZipDocument(ScanDocument document) async {
    if (!mounted) return;
    final notification = AppToast.info(context, 'gallery.preparingZip'.tr());

    final result = await ExportService.instance.saveZipWithPicker(document);

    AppToast.dismiss(notification);
    if (!mounted) return;

    AppToast.showExportResult(context, result);
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
        final result = await ExportService.instance
            .saveImagesToGallery(document.imagePaths);

        if (!mounted) return;
        AppToast.showExportResult(context, result);
      },
    );
  }
}
