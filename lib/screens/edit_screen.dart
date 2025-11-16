import 'dart:io';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
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
      ) ?? [];

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
        builder: (context) => _ImageViewerScreen(
          imagePath: imagePath,
          pageNumber: index + 1,
          totalPages: _imagePaths.length,
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
    final TextEditingController nameController = TextEditingController(text: defaultName);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      title: isEditingExisting ? 'Save Changes' : 'Save Scan',
      desc: isEditingExisting
          ? 'Update the name for this scan'
          : 'Enter a name for this scan',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              isEditingExisting ? 'Save Changes' : 'Save Scan',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Document name',
                hintText: 'Enter name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                counterText: '', // Hide character counter
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final documentName = nameController.text.trim();
        if (documentName.isEmpty) {
          _showMessage('Name cannot be empty');
          return;
        }

        final navigator = Navigator.of(context);

        // Create a new scan document with user-provided name
        // When editing, preserve the original ID and createdAt
        final newDocument = ScanDocument(
          id: _existingDocumentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: documentName,
          createdAt: DateTime.now(), // Always update timestamp
          imagePaths: _imagePaths,
          isProcessed: true,
        );

        // No toast for successful save - user clicked Save button intentionally
        // Only show toast for errors

        // Return to GalleryScreen
        if (!mounted) return;
        navigator.pop(newDocument);
      },
      btnOkText: 'Save',
      btnCancelText: 'Cancel',
      btnCancelColor: AppColors.textSecondary,
    ).show();
  }

  /// Show confirmation dialog before discarding changes
  Future<bool> _confirmDiscard() async {
    debugPrint('🚨 _confirmDiscard called - showing dialog');

    bool? result;

    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Discard Changes?',
      desc: 'Are you sure you want to discard this scan? All images will be lost.',
      btnCancelOnPress: () {
        debugPrint('🚨 User clicked Cancel');
        result = false;
      },
      btnOkOnPress: () {
        debugPrint('🚨 User clicked Discard');
        result = true;
      },
      btnOkText: 'Discard',
      btnCancelText: 'Cancel',
      btnOkColor: AppColors.error,
      btnCancelColor: AppColors.textSecondary,
    ).show();

    debugPrint('🚨 Dialog result: $result');
    return result ?? false;
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
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
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
        Icons.check_circle,
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
        Icons.error,
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
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
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
        Icons.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    _showToast(message, Colors.black87, Icons.info);
  }

  void _showToast(String message, Color backgroundColor, IconData icon) {
    FToast fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 3),
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
            icon: const Icon(Icons.arrow_back),
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
                  _buildBottomActions(),
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
            const Icon(
              Icons.image_not_supported_outlined,
              size: 120,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No images added yet',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap "Add More" below to add images',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
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
        return _buildImageTile(index, imagePath);
      }).toList(),
    );
  }

  Widget _buildImageTile(int index, String imagePath) {
    return Card(
      key: ValueKey(imagePath),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow like CSS overflow: visible
        fit: StackFit.expand,
        children: [
          // Image (tappable)
          GestureDetector(
            onTap: () => _viewImage(imagePath, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Page number
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${index + 1}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Delete button (overlapping corner like CSS absolute + z-index)
          Positioned(
            top: -8, // Negative offset to overlap outside card
            right: -8, // Negative offset to overlap outside card
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _deleteImage(index),
                borderRadius: BorderRadius.circular(AppRadius.round),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    // Get safe area bottom padding for iOS/Android home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: AppSpacing.md + bottomPadding, // Add safe area padding
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Icon buttons for quick actions
          Row(
            children: [
              // Add More Images
              Expanded(
                child: _buildIconButton(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Add More',
                  onPressed: _addMoreImages,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Save PDF
              Expanded(
                child: _buildIconButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Save PDF',
                  onPressed: _savePdfLocally,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Share PDF
              Expanded(
                child: _buildIconButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: _exportToPdf,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 2: Primary action - Save to Gallery
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveScan,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text(
                'Save to Gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md + 4,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build icon button for footer actions
  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 4,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen image viewer with zoom and pan
class _ImageViewerScreen extends StatefulWidget {
  final String imagePath;
  final int pageNumber;
  final int totalPages;

  const _ImageViewerScreen({
    required this.imagePath,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Page ${widget.pageNumber} / ${widget.totalPages}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
