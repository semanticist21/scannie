import 'dart:async';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/app_toast.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/common/image_tile.dart';
import '../widgets/common/edit_bottom_actions.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/text_input_dialog.dart';

/// Edit screen for managing scanned images
/// Features: Reorder, Delete, Add more images
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  List<String> _imagePaths = [];
  String? _existingDocumentId; // null = new scan, non-null = editing existing
  String? _existingDocumentName; // Preserve name when editing
  bool _isLoading = false;
  bool _hasInteracted = false; // Track if user made any changes

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
      }
      debugPrint('📸 EditScreen loaded ${_imagePaths.length} images');
      if (_existingDocumentId != null) {
        debugPrint('✏️ Editing existing scan: $_existingDocumentName');
      }
    }
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
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _imagePaths,
          initialPage: index,
          showFilters: true,
        ),
      ),
    );

    // If image was modified, rebuild to show updated image
    if (result == true && mounted) {
      setState(() {
        _hasInteracted = true;
      });
      debugPrint('🔄 Image modified, refreshing grid');
    }
  }

  /// Reorder images
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _imagePaths.removeAt(oldIndex);
      _imagePaths.insert(newIndex, item);
      _hasInteracted = true;
    });
  }

  /// Save and return
  void _saveScan() async {
    // Check if there are any images
    if (_imagePaths.isEmpty) {
      AppToast.show(context, 'edit.addAtLeastOneImage'.tr(),
          isError: true);
      return;
    }

    final navigator = Navigator.of(context);
    final bool isEditingExisting = _existingDocumentId != null;

    // For existing documents, save directly without dialog
    if (isEditingExisting) {
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

    // For new scans, show name input dialog
    final String defaultName =
        'Scan ${DateTime.now().toString().substring(0, 10)}';

    TextInputDialog.show(
      context: context,
      title: 'edit.saveScan'.tr(),
      description: 'edit.saveScanDesc'.tr(),
      initialValue: defaultName,
      placeholder: 'gallery.documentNamePlaceholder'.tr(),
      onSave: (documentName) async {
        // Get default PDF settings
        final pdfSettings = await PdfSettingsService.getInstance();

        // Create new scan document with default PDF settings
        final newDocument = ScanDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      debugPrint('🔙 User confirmed discard, popping');
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.imageOff,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'edit.noImagesTitle'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'edit.noImagesSubtitle'.tr(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 210 / 297, // A4 ratio
      padding: const EdgeInsets.all(AppSpacing.md),
      onReorder: _onReorder,
      children: _imagePaths.asMap().entries.map((entry) {
        final index = entry.key;
        final imagePath = entry.value;
        return ImageTile(
          key: ValueKey(imagePath),
          index: index,
          imagePath: imagePath,
          onTap: () => _viewImage(imagePath, index),
          onDelete: () => _deleteImage(index),
        );
      }).toList(),
    );
  }
}
