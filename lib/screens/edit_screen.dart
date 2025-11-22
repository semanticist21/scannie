import 'dart:async';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ndialog/ndialog.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:elegant_notification/elegant_notification.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/common/image_tile.dart';
import '../widgets/common/edit_bottom_actions.dart';

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
        });
        // Success toast removed - visual feedback is the grid update itself
      }
    } catch (e) {
      debugPrint('Error adding scans: $e');
      _showMessage('Failed to add scans', isError: true);
    } finally {
      setState(() => _isLoading = false);
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
        });
        // Success toast removed - visual feedback is the grid update itself
      }
    } catch (e) {
      debugPrint('❌ Error adding photos: $e');
      _showMessage('Failed to add photos', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Delete image at index
  void _deleteImage(int index) {
    if (_imagePaths.isEmpty) {
      return;
    }

    setState(() {
      _imagePaths.removeAt(index);
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
      setState(() {});
      debugPrint('🔄 Image modified, refreshing grid');
    }
  }

  /// Reorder images
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _imagePaths.removeAt(oldIndex);
      _imagePaths.insert(newIndex, item);
    });
  }

  /// Save and return
  void _saveScan() async {
    // Check if there are any images
    if (_imagePaths.isEmpty) {
      _showMessage('Please add at least one image to save', isError: true);
      return;
    }

    final navigator = Navigator.of(context);
    final bool isEditingExisting = _existingDocumentId != null;

    // Determine default name based on context
    final String defaultName = isEditingExisting
        ? _existingDocumentName!
        : 'Scan ${DateTime.now().toString().substring(0, 10)}';

    final TextEditingController nameController =
        TextEditingController(text: defaultName);

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
                  'Save Scan',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter a name for this scan',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ShadInput(
                  controller: nameController,
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
                        final documentName = nameController.text.trim();
                        if (documentName.isEmpty) {
                          _showMessage('Name cannot be empty', isError: true);
                          return;
                        }

                        Navigator.of(context).pop();

                        if (isEditingExisting) {
                          // Update existing document
                          final updatedDocument = ScanDocument(
                            id: _existingDocumentId!,
                            name: documentName,
                            createdAt: DateTime.now(),
                            imagePaths: _imagePaths,
                            isProcessed: true,
                          );

                          if (!mounted) return;

                          // Update in storage
                          final documents =
                              await DocumentStorage.loadDocuments();
                          final index = documents
                              .indexWhere((d) => d.id == _existingDocumentId);
                          if (index != -1) {
                            documents[index] = updatedDocument;
                            await DocumentStorage.saveDocuments(documents);
                          }

                          navigator.pop(updatedDocument);
                        } else {
                          // Create new scan document
                          final newDocument = ScanDocument(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: documentName,
                            createdAt: DateTime.now(),
                            imagePaths: _imagePaths,
                            isProcessed: true,
                          );

                          if (!mounted) return;

                          // Save to storage and navigate to viewer
                          final documents =
                              await DocumentStorage.loadDocuments();
                          documents.insert(0, newDocument);
                          await DocumentStorage.saveDocuments(documents);

                          navigator.pushReplacementNamed(
                            '/viewer',
                            arguments: newDocument,
                          );
                        }
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

  /// Show confirmation dialog before discarding changes
  Future<bool> _confirmDiscard() async {
    debugPrint('🚨 _confirmDiscard called - showing dialog');

    final completer = Completer<bool>();
    final bool isNewScan = _existingDocumentId == null;

    DialogBackground(
      blur: 6,
      dismissable: false,
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
                  'Discard Changes?',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isNewScan
                      ? 'Are you sure you want to discard this scan? All images will be lost.'
                      : 'Are you sure you want to discard changes? Your changes will not be saved.',
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
                      onPressed: () {
                        debugPrint('🚨 User clicked Cancel');
                        Navigator.of(context).pop();
                        completer.complete(false);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShadButton.destructive(
                      child: const Text('Discard'),
                      onPressed: () {
                        debugPrint('🚨 User clicked Discard');
                        Navigator.of(context).pop();
                        completer.complete(true);
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

    final result = await completer.future;
    debugPrint('🚨 Dialog result: $result');
    return result;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      ElegantNotification.error(
        title: const Text('Error'),
        description: Text(message),
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: true,
      ).show(context);
    } else {
      ElegantNotification.success(
        title: const Text('Success'),
        description: Text(message),
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: true,
      ).show(context);
    }
  }

  /// Handle back button press with confirmation
  Future<void> _handleBackPress() async {
    debugPrint('🔙 _handleBackPress called');
    final navigator = Navigator.of(context);
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
          title: 'Edit Scan (${_imagePaths.length})',
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
              'No images added yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap "Add More" to start',
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
