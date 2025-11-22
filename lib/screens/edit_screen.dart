import 'dart:async';
import 'dart:io';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ndialog/ndialog.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/full_screen_image_viewer.dart';
import '../widgets/common/image_tile.dart';
import '../widgets/common/edit_bottom_actions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:media_store_plus/media_store_plus.dart';

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

  /// Add more images to current session
  Future<void> _addMoreImages() async {
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
        _showMessage('${newImages.length} image(s) added');
      }
    } catch (e) {
      debugPrint('Error adding images: $e');
      _showMessage('Failed to add images');
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
  void _viewImage(String imagePath, int index) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _imagePaths,
          initialPage: index,
        ),
      ),
    );
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
      _showMessage('Please add at least one image to save');
      return;
    }

    // Determine default name based on context
    final bool isEditingExisting = _existingDocumentId != null;
    final String defaultName = isEditingExisting
        ? _existingDocumentName! // Use existing name when editing
        : 'Scan ${DateTime.now().toString().substring(0, 10)}'; // New scan: use date

    // Show dialog to input document name
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
                  isEditingExisting ? 'Save Changes' : 'Save Scan',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isEditingExisting
                      ? 'Update the name for this scan'
                      : 'Enter a name for this scan',
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
                          _showMessage('Name cannot be empty');
                          return;
                        }

                        Navigator.of(context).pop();

                        final navigator = Navigator.of(context);

                        // Create a new scan document with user-provided name
                        // When editing, preserve the original ID and createdAt
                        final newDocument = ScanDocument(
                          id: _existingDocumentId ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: documentName,
                          createdAt: DateTime.now(), // Always update timestamp
                          imagePaths: _imagePaths,
                          isProcessed: true,
                        );

                        // Return to GalleryScreen
                        if (!mounted) return;
                        navigator.pop(newDocument);
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
                  'Are you sure you want to discard this scan? All images will be lost.',
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

  /// Save PDF to Downloads folder and open file manager
  /// Save PDF to Downloads folder using MediaStore (no permission required)
  Future<void> _savePdfLocally() async {
    setState(() => _isLoading = true);

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a separate page
      for (final imagePath in _imagePaths) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = 'Scan_$timestamp.pdf';

      // Get PDF bytes
      final pdfBytes = await pdf.save();

      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(pdfBytes);

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
      setState(() => _isLoading = false);

      _showToast(
        'PDF saved to Downloads',
        AppColors.success,
        LucideIcons.circleCheck,
      );

      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast(
        'Failed to save PDF',
        AppColors.error,
        LucideIcons.circleAlert,
      );
    }
  }

  /// Export images to PDF (Share)
  Future<void> _exportToPdf() async {
    setState(() => _isLoading = true);

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a separate page
      for (final imagePath in _imagePaths) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = 'Scan_$timestamp.pdf';

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File(path.join(output.path, fileName));
      await file.writeAsBytes(await pdf.save());

      // Share the PDF using the printing package
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );

      // No toast - share dialog is self-explanatory
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (!mounted) return;
      _showToast(
        'Failed to export PDF',
        AppColors.error,
        LucideIcons.circleAlert,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
  }

  void _showToast(String message, Color backgroundColor, IconData icon) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
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
                    onAddMore: _addMoreImages,
                    onSavePdf: _savePdfLocally,
                    onShare: _exportToPdf,
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
