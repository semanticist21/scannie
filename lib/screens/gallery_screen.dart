import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ndialog/ndialog.dart';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/scan_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/document_grid_card.dart';
import '../widgets/common/document_search_delegate.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elegant_notification/elegant_notification.dart';

/// Gallery screen displaying scanned documents
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<ScanDocument> _documents = [];
  bool _isGridView = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadDocuments();
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
        _showSnackBar('Failed to load documents: $e', isError: true);
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
        title: const Text('My Scans'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _createEmptyDocument,
            tooltip: 'Create Empty Document',
          ),
          IconButton(
            icon: Icon(_isGridView ? LucideIcons.list : LucideIcons.layoutGrid),
            onPressed: () {
              final newViewMode = !_isGridView;
              setState(() => _isGridView = newViewMode);
              _saveViewMode(newViewMode);
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: _showSearch,
            tooltip: 'Search',
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.primaryLight.withValues(alpha: 0.1),
                AppColors.background,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? _buildEmptyState()
                  : _buildDocumentList(),
        ),
      ),
      floatingActionButton: ShadButton(
        onPressed: _openCamera,
        leading: const Icon(LucideIcons.camera, size: 18),
        child: const Text('Scan'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: LucideIcons.fileText,
      title: 'No scans yet',
      subtitle: 'Tap the button below to start scanning',
    );
  }

  Widget _buildDocumentList() {
    if (_isGridView) {
      return _buildGridView();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxl * 2,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return ScanCard(
          document: document,
          onTap: () => _openDocument(document),
          onEdit: () => _editDocumentName(document),
          onEditScan: () => _editScan(document),
          onDelete: () => _deleteDocument(document),
          onSavePdf: () => _savePdfDocument(document),
          onShare: () => _sharePdfDocument(document),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return DocumentGridCard(
          document: document,
          onTap: () => _openDocument(document),
        );
      },
    );
  }

  /// Create empty document with name input
  Future<void> _createEmptyDocument() async {
    final TextEditingController nameController = TextEditingController(
      text: 'Scan ${DateTime.now().toString().substring(0, 10)}',
    );

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
                  'Create New Document',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter a name for the new document',
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
                      child: const Text('Create'),
                      onPressed: () async {
                        final documentName = nameController.text.trim();
                        if (documentName.isEmpty) {
                          _showSnackBar('Name cannot be empty', isError: true);
                          return;
                        }

                        Navigator.of(context).pop();

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
                        _showSnackBar('Empty document created');
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

  Future<void> _openCamera() async {
    try {
      // Launch cunning_document_scanner_plus with filters mode
      // This allows users to apply filters during scanning
      final scannedImages = await CunningDocumentScanner.getPictures(
        mode: ScannerMode.full, // Enable AI Enhance + Clean features
        noOfPages: 100, // Allow multiple pages (user taps Done when finished)
      ) ?? [];

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

      // If a new document was created, add it to the list and save
      if (result != null && result is ScanDocument && mounted) {
        setState(() {
          _documents.insert(0, result);
        });
        await _saveDocuments();
        // No toast for successful save - user clicked Save button intentionally
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnackBar('Scan failed: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Scan failed: $e', isError: true);
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

  void _editDocumentName(ScanDocument document) async {
    final TextEditingController controller = TextEditingController(text: document.name);

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
                  'Rename Scan',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter a new name for this document',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ShadInput(
                  controller: controller,
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
                        final newName = controller.text.trim();
                        if (newName.isEmpty) {
                          _showSnackBar('Name cannot be empty', isError: true);
                          return;
                        }

                        Navigator.of(context).pop();

                        setState(() {
                          final index = _documents.indexWhere((d) => d.id == document.id);
                          if (index != -1) {
                            _documents[index] = document.copyWith(name: newName);
                          }
                        });

                        await _saveDocuments();
                        if (!mounted) return;
                        _showSnackBar('Document renamed');
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

  void _deleteDocument(ScanDocument document) async {
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
                  'Delete Scan',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Delete "${document.name}"?',
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShadButton.destructive(
                      child: const Text('Delete'),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        setState(() {
                          _documents.removeWhere((d) => d.id == document.id);
                        });
                        await _saveDocuments();
                        if (!mounted) return;
                        _showSnackBar('Document deleted');
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

  void _savePdfDocument(ScanDocument document) {
    _savePdfLocally(document);
  }

  void _sharePdfDocument(ScanDocument document) {
    _exportToPdf(document);
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
      _showSnackBar('Scan updated successfully');
    }
  }

  /// Export document to PDF
  Future<void> _exportToPdf(ScanDocument document) async {
    try {
      _showSnackBar('Generating PDF...');

      // Generate PDF with quality setting
      final pdfFile = await PdfCacheService().getOrGeneratePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
      );

      if (!mounted) return;

      // Generate filename for sharing
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.pdf';

      // Share the PDF using the printing package
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: fileName,
      );

      // No snackbar for share - dialog is self-explanatory
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      _showSnackBar('Failed to export PDF', isError: true);
    }
  }

  /// Save PDF to Downloads folder using MediaStore (no permission required)
  Future<void> _savePdfLocally(ScanDocument document) async {
    try {
      _showSnackBar('Generating PDF...');

      // Generate PDF with quality setting
      final pdfFile = await PdfCacheService().getOrGeneratePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
      );

      // Generate filename
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
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

      if (!mounted) return;
      _showSnackBar('PDF saved to Downloads');

      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (!mounted) return;
      _showSnackBar('Failed to save PDF', isError: true);
    }
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: DocumentSearchDelegate(_documents),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      ElegantNotification.error(
        title: const Text('Error'),
        description: Text(message),
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: false,
      ).show(context);
    } else {
      ElegantNotification.success(
        title: const Text('Success'),
        description: Text(message),
        toastDuration: const Duration(seconds: 3),
        showProgressIndicator: false,
      ).show(context);
    }
  }
}
