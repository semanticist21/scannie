import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/app_toast.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/edit/image_tile.dart';
import '../widgets/edit/edit_bottom_actions.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/text_input_dialog.dart';
import '../widgets/common/empty_state.dart';
import 'package:uuid/uuid.dart';
import '../services/ad_service.dart';
import '../theme/app_colors.dart';

/// Edit screen for managing scanned images
/// Features: Reorder, Delete, Add more images
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  List<String> _imagePaths = [];
  final Set<String> _tempFilePaths = {}; // Track temp files for cleanup
  String? _existingDocumentId; // null = new scan, non-null = editing existing
  String? _existingDocumentName; // Preserve name when editing
  bool _isLoading = false;
  bool _hasInteracted = false; // Track if user made any changes
  bool _wasEmptyOnStart = false; // Track if document was empty when editing started (for ad logic)

  // For ReorderableBuilder
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load image paths from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && _imagePaths.isEmpty) {
      if (arguments is String) {
        // Single image path
        _imagePaths = [arguments];
      } else if (arguments is List<String>) {
        // List of image paths (new scan)
        _imagePaths = List<String>.from(arguments);
      } else if (arguments is ScanDocument) {
        // Editing existing scan
        _imagePaths = List<String>.from(arguments.imagePaths);
        _existingDocumentId = arguments.id;
        _existingDocumentName = arguments.name;
        // Track if document was empty (for showing ad when first images are added)
        _wasEmptyOnStart = arguments.imagePaths.isEmpty;
      }
      debugPrint('📸 EditScreen loaded ${_imagePaths.length} images');
      if (_existingDocumentId != null) {
        debugPrint('✏️ Editing existing scan: $_existingDocumentName');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Add more scans using document scanner
  Future<void> _addMoreScans() async {
    setState(() => _isLoading = true);

    try {
      final newImages = await CunningDocumentScanner.getPictures(
            mode: ScannerMode.full, // Enable AI Enhance + Clean features
            noOfPages:
                100, // Allow multiple pages (user taps Done when finished)
          ) ??
          [];

      if (newImages.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(newImages);
          _hasInteracted = true;
        });
        // Success toast removed - visual feedback is the grid update itself
      }
    } catch (e) {
      debugPrint('Error adding scans: $e');
      if (mounted) {
        AppToast.show(context, 'toast.failedToAddScans'.tr(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Add photos from gallery
  Future<void> _addFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      debugPrint('📷 Picked ${pickedFiles.length} photos from gallery');

      if (pickedFiles.isNotEmpty) {
        final newPaths = pickedFiles.map((file) => file.path).toList();
        debugPrint('📷 Photo paths: $newPaths');
        setState(() {
          _imagePaths.addAll(newPaths);
          _hasInteracted = true;
        });
        // Success toast removed - visual feedback is the grid update itself
      }
    } catch (e) {
      debugPrint('❌ Error adding photos: $e');
      if (mounted) {
        AppToast.show(context, 'toast.failedToAddPhotos'.tr(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Delete image at index
  void _deleteImage(int index) {
    if (_imagePaths.isEmpty) {
      return;
    }

    setState(() {
      _imagePaths.removeAt(index);
      _hasInteracted = true;
    });
    // No toast for successful deletion
  }

  /// View image in full screen
  Future<void> _viewImage(String imagePath, int index) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<String?>(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _imagePaths,
          initialPage: index,
          showFilters: true,
        ),
      ),
    );

    // If image was modified, result contains the new temp file path
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        // Track the temp file for cleanup on discard
        _tempFilePaths.add(result);
        // Update the image path to use the temp file
        _imagePaths[index] = result;
        _hasInteracted = true;
      });
      debugPrint('🔄 Image modified, using temp file: $result');
    }
  }

  /// Clean up all temp files created during editing
  Future<void> _cleanupTempFiles() async {
    for (final tempPath in _tempFilePaths) {
      try {
        final file = File(tempPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Cleaned up temp file: $tempPath');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete temp file: $tempPath - $e');
      }
    }
    _tempFilePaths.clear();
  }

  /// Check if ad should be shown on save
  /// Ad is shown when:
  /// Determines if ad should show on save:
  /// 1. NEW scan (from Scan button) → always show
  /// 2. Existing EMPTY document now has images → always show
  /// 3. Existing document with images being edited → 20% chance
  bool _shouldShowAdOnSave() {
    // New scan from Scan button - always show
    if (_existingDocumentId == null) {
      return true;
    }
    // Existing document that was empty and now has images - always show
    if (_wasEmptyOnStart && _imagePaths.isNotEmpty) {
      return true;
    }
    // Existing document being edited - 20% chance
    // (This won't conflict with above cases due to early returns)
    if (_existingDocumentId != null && !_wasEmptyOnStart) {
      return Random().nextDouble() < 0.2;
    }
    return false;
  }

  /// Save and return
  void _saveScan() async {
    // Check if there are any images
    if (_imagePaths.isEmpty) {
      AppToast.show(context, 'edit.addAtLeastOneImage'.tr(),
          isError: true);
      return;
    }

    // Capture navigator before async operations
    final navigator = Navigator.of(context);
    final bool isEditingExisting = _existingDocumentId != null;
    final bool shouldShowAd = _shouldShowAdOnSave();

    if (!mounted) return;

    // For existing documents, save directly without dialog
    if (isEditingExisting) {
      // Show ad for empty documents that now have images
      if (shouldShowAd) {
        await AdService.instance.showInterstitialAd();
      }
      if (!mounted) return;

      final updatedDocument = ScanDocument(
        id: _existingDocumentId!,
        name: _existingDocumentName!,
        createdAt: DateTime.now(),
        imagePaths: _imagePaths,
        isProcessed: true,
      );

      // Update in storage
      final documents = await DocumentStorage.loadDocuments();
      final index = documents.indexWhere((d) => d.id == _existingDocumentId);
      if (index != -1) {
        documents[index] = updatedDocument;
        await DocumentStorage.saveDocuments(documents);
      }

      if (mounted) {
        AppToast.show(context, 'edit.scanSaved'.tr());
      }

      navigator.pop(updatedDocument);
      return;
    }

    // For new scans, show name input dialog first
    final String defaultName =
        'Scan ${DateTime.now().toString().substring(0, 10)}';

    TextInputDialog.show(
      context: context,
      title: 'edit.saveScan'.tr(),
      description: 'edit.saveScanDesc'.tr(),
      initialValue: defaultName,
      placeholder: 'gallery.documentNamePlaceholder'.tr(),
      onSave: (documentName) async {
        // Show ad AFTER user confirms save with name
        if (shouldShowAd) {
          await AdService.instance.showInterstitialAd();
        }

        // Get default PDF settings
        final pdfSettings = await PdfSettingsService.getInstance();

        // Create new scan document with default PDF settings
        final newDocument = ScanDocument(
          id: const Uuid().v7(),
          name: documentName,
          createdAt: DateTime.now(),
          imagePaths: _imagePaths,
          isProcessed: true,
          pdfQuality: pdfSettings.defaultQuality,
          pdfPageSize: pdfSettings.defaultPageSize,
          pdfOrientation: pdfSettings.defaultOrientation,
          pdfImageFit: pdfSettings.defaultImageFit,
          pdfMargin: pdfSettings.defaultMargin,
        );

        // Save to storage
        final documents = await DocumentStorage.loadDocuments();
        documents.insert(0, newDocument);
        await DocumentStorage.saveDocuments(documents);

        // Navigate directly to viewer, removing EditScreen from stack
        // This ensures back button from viewer goes to GalleryScreen, not EditScreen
        navigator.pushNamedAndRemoveUntil(
          '/viewer',
          ModalRoute.withName('/'),
          arguments: newDocument,
        );
      },
    );
  }

  /// Show confirmation dialog before discarding changes
  Future<bool> _confirmDiscard() async {
    debugPrint('🚨 _confirmDiscard called - showing dialog');

    final bool isNewScan = _existingDocumentId == null;
    final message = isNewScan
        ? 'edit.discardNewScan'.tr()
        : 'edit.discardEditScan'.tr();

    final result = await ConfirmDialog.showAsync(
      context: context,
      title: 'edit.discardChangesTitle'.tr(),
      message: message,
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.discard'.tr(),
      isDestructive: true,
      dismissable: false,
    );

    debugPrint('🚨 Dialog result: $result');
    return result;
  }

  /// Handle back button press with confirmation
  Future<void> _handleBackPress() async {
    debugPrint('🔙 _handleBackPress called');
    final navigator = Navigator.of(context);

    // For existing documents with no changes, pop immediately
    if (_existingDocumentId != null && !_hasInteracted) {
      debugPrint('🔙 No changes detected, popping immediately');
      navigator.pop();
      return;
    }

    // Show confirmation dialog for new scans or modified existing documents
    final shouldPop = await _confirmDiscard();

    if (shouldPop && mounted) {
      debugPrint('🔙 User confirmed discard, cleaning up temp files');
      // Clean up all temp files before discarding
      await _cleanupTempFiles();
      navigator.pop();
    } else {
      debugPrint('🔙 User cancelled discard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        debugPrint('🔙 onPopInvoked: didPop=$didPop, result=$result');

        // If already popped, do nothing
        if (didPop) {
          debugPrint('🔙 Already popped, returning');
          return;
        }

        // System back button pressed
        debugPrint('🔙 System back button, asking user...');
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: ThemedColors.of(context).background,
        appBar: CustomAppBar(
          title: 'edit.title'.tr(namedArgs: {'count': _imagePaths.length.toString()}),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: _handleBackPress, // Custom back handler
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Image Grid (Reorderable)
                  Expanded(
                    child: _buildReorderableGrid(),
                  ),

                  // Bottom Actions
                  EditBottomActions(
                    onAddScan: _addMoreScans,
                    onAddPhoto: _addFromGallery,
                    onSave: _saveScan,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReorderableGrid() {
    // Show empty state if no images
    if (_imagePaths.isEmpty) {
      return EmptyState(
        icon: LucideIcons.sparkles,
        title: 'edit.noImagesTitle'.tr(),
        subtitle: 'edit.noImagesSubtitle'.tr(),
      );
    }

    final generatedChildren = _imagePaths.asMap().entries.map((entry) {
      final index = entry.key;
      final imagePath = entry.value;
      return ImageTile(
        key: ValueKey(imagePath),
        index: index,
        imagePath: imagePath,
        onTap: () => _viewImage(imagePath, index),
        onDelete: () => _deleteImage(index),
      );
    }).toList();

    return ReorderableBuilder(
      scrollController: _scrollController,
      onReorder: (ReorderedListFunction reorderedListFunction) {
        setState(() {
          _imagePaths = reorderedListFunction(_imagePaths) as List<String>;
          _hasInteracted = true;
        });
      },
      children: generatedChildren,
      builder: (children) {
        return GridView(
          key: _gridViewKey,
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 210 / 297, // A4 ratio
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: children,
        );
      },
    );
  }
}
