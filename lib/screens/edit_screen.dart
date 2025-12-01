import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart' as path;
import '../utils/app_toast.dart';
import '../utils/path_helper.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_settings_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/edit/image_tile.dart';
import '../widgets/edit/edit_bottom_actions.dart';
import '../widgets/common/confirm_dialog.dart';
import '../widgets/common/text_input_dialog.dart';
import '../widgets/common/empty_state.dart';
import 'package:uuid/uuid.dart';
import '../services/ad_service.dart';
import '../services/pdf_import_service.dart';
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
  List<String> _imageIds = []; // Unique ID for each image (prevents duplicate key errors)
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
      // Generate unique IDs for each image
      _imageIds = List.generate(_imagePaths.length, (_) => const Uuid().v4());
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
    // Check camera permission first
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (!mounted) return;
          _showCameraPermissionDialog();
          return;
        }
      } else {
        if (!mounted) return;
        _showCameraPermissionDialog();
        return;
      }
    }

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
          _imageIds.addAll(List.generate(newImages.length, (_) => const Uuid().v4()));
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
          _imageIds.addAll(List.generate(newPaths.length, (_) => const Uuid().v4()));
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

  /// Add pages from PDF file
  Future<void> _addFromPdf() async {
    setState(() => _isLoading = true);

    try {
      final result = await PdfImportService.instance.importPdfAsImages(
        onProgress: (current, total) {
          debugPrint('📄 PDF import progress: $current/$total');
        },
      );

      if (result.cancelled) {
        debugPrint('📄 PDF import cancelled');
        return;
      }

      if (!result.success) {
        if (mounted) {
          AppToast.show(
            context,
            'toast.failedToImportPdf'.tr(),
            isError: true,
          );
        }
        debugPrint('❌ PDF import error: ${result.error}');
        return;
      }

      if (result.imagePaths.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(result.imagePaths);
          _imageIds.addAll(
            List.generate(result.imagePaths.length, (_) => const Uuid().v4()),
          );
          // Track temp files for cleanup on discard
          _tempFilePaths.addAll(result.imagePaths);
          _hasInteracted = true;
        });
        debugPrint('📄 Added ${result.imagePaths.length} pages from PDF');
      }
    } catch (e) {
      debugPrint('❌ Error importing PDF: $e');
      if (mounted) {
        AppToast.show(context, 'toast.failedToImportPdf'.tr(), isError: true);
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
      _imageIds.removeAt(index);
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

  /// Copy images to permanent storage (Documents/Scannie/{documentId}/)
  /// Returns list of new permanent paths
  /// This prevents data loss when app updates change sandbox UUID on iOS
  Future<List<String>> _copyImagesToPermanentStorage(String documentId) async {
    // Use PathHelper for consistent path handling
    final scannieDir = await PathHelper.ensureDocumentDir(documentId);
    final scannieDirPath = scannieDir.path;

    final List<String> permanentPaths = [];

    for (int i = 0; i < _imagePaths.length; i++) {
      final originalPath = _imagePaths[i];
      final originalFile = File(originalPath);

      // Check if already in permanent storage for this document
      // Use PathHelper to handle both old and new path formats
      if (PathHelper.isInScannieDir(originalPath) && originalPath.contains(documentId)) {
        // Already in permanent storage for this document, keep as-is
        permanentPaths.add(originalPath);
        debugPrint('📁 Already permanent: $originalPath');
        continue;
      }

      if (!await originalFile.exists()) {
        debugPrint('⚠️ Source file not found: $originalPath');
        continue;
      }

      // Generate new filename: page_001.jpg, page_002.jpg, etc.
      final extension = path.extension(originalPath).toLowerCase();
      final newFileName = 'page_${(i + 1).toString().padLeft(3, '0')}$extension';
      final newPath = path.join(scannieDirPath, newFileName);

      try {
        // Copy file to permanent location
        await originalFile.copy(newPath);
        permanentPaths.add(newPath);
        debugPrint('📁 Copied: $originalPath → $newPath');
      } catch (e) {
        debugPrint('❌ Failed to copy $originalPath: $e');
        // If copy fails, keep original path as fallback
        permanentPaths.add(originalPath);
      }
    }

    return permanentPaths;
  }

  /// Delete old images from permanent storage when document is updated
  /// Only deletes images that are no longer used (not in currentPaths)
  Future<void> _cleanupOldPermanentImages(String documentId, List<String> oldPaths, List<String> currentPaths) async {
    // Create a set of current paths for fast lookup (normalize to compare correctly)
    final currentPathsSet = currentPaths.map((p) => path.basename(p)).toSet();

    for (final oldPath in oldPaths) {
      // Skip if this file is still being used (compare by filename)
      final oldBasename = path.basename(oldPath);
      if (currentPathsSet.contains(oldBasename)) {
        debugPrint('📁 Keeping current file: $oldPath');
        continue;
      }

      // Only delete files in our Scannie directory
      if (PathHelper.isInScannieDir(oldPath)) {
        try {
          final file = File(oldPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Deleted old permanent file: $oldPath');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to delete old file: $oldPath - $e');
        }
      }
    }
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

      // Update in storage - use copyWith to preserve tags and PDF settings
      final documents = await DocumentStorage.loadDocuments();
      final index = documents.indexWhere((d) => d.id == _existingDocumentId);
      if (index != -1) {
        final existingDoc = documents[index];

        // Copy images to permanent storage first (prevents iOS sandbox path change issues)
        final permanentPaths = await _copyImagesToPermanentStorage(_existingDocumentId!);

        // Clean up old images that are no longer used (not in new permanentPaths)
        await _cleanupOldPermanentImages(_existingDocumentId!, existingDoc.imagePaths, permanentPaths);

        final updatedDocument = existingDoc.copyWith(
          imagePaths: permanentPaths,
          createdAt: DateTime.now(),
          isProcessed: true,
        );
        documents[index] = updatedDocument;
        await DocumentStorage.saveDocuments(documents);

        // Clean up temp files after successful save
        await _cleanupTempFiles();

        if (mounted) {
          AppToast.show(context, 'edit.scanSaved'.tr());
        }

        navigator.pop(updatedDocument);
      }
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

        // Generate document ID first for permanent storage path
        final documentId = const Uuid().v7();

        // Copy images to permanent storage (prevents iOS sandbox path change issues)
        final permanentPaths = await _copyImagesToPermanentStorage(documentId);

        // Create new scan document with default PDF settings
        final newDocument = ScanDocument(
          id: documentId,
          name: documentName,
          createdAt: DateTime.now(),
          imagePaths: permanentPaths,
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

        // Clean up temp files after successful save
        await _cleanupTempFiles();

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
      canPop: _existingDocumentId != null && !_hasInteracted,
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
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.check),
              onPressed: _saveScan,
              tooltip: 'common.save'.tr(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Tap hint banner
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'edit.tapImageHint'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Image Grid (Reorderable)
                  Expanded(
                    child: _buildReorderableGrid(),
                  ),

                  // Bottom Actions
                  EditBottomActions(
                    onAddScan: _addMoreScans,
                    onAddPhoto: _addFromGallery,
                    onAddPdf: _addFromPdf,
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
        key: ValueKey(_imageIds[index]),
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
          _imageIds = reorderedListFunction(_imageIds) as List<String>;
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
