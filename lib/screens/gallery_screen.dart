import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/scan_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        _showSnackBar('Failed to load documents: $e');
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80), // 시각적 중앙 보정
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileText,
              size: 100,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No scans yet',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the button below to start scanning',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
        return _buildGridCard(document);
      },
    );
  }

  Widget _buildGridCard(ScanDocument document) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Card.filled(
        child: InkWell(
          onTap: () => _openDocument(document),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail with subtle elevation
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: _buildGridThumbnail(document),
                  ),
                ),
              ),

              // Info section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.file,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${document.imagePaths.length} ${document.imagePaths.length == 1 ? 'page' : 'pages'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridThumbnail(ScanDocument document) {
    // If document has images, show the first image as thumbnail
    if (document.imagePaths.isNotEmpty) {
      final firstImagePath = document.imagePaths.first;
      final imageFile = File(firstImagePath);

      // Check if file exists
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              child: const Center(
                child: Icon(
                  LucideIcons.fileText,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          LucideIcons.fileText,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Create empty document with name input
  Future<void> _createEmptyDocument() async {
    final TextEditingController nameController = TextEditingController(
      text: 'Scan ${DateTime.now().toString().substring(0, 10)}',
    );

    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Create New Document'),
        description: const Text('Enter a name for the new document'),
        constraints: const BoxConstraints(maxWidth: 320),
        radius: const BorderRadius.all(Radius.circular(16)),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ShadButton(
            child: const Text('Create'),
            onPressed: () async {
              final documentName = nameController.text.trim();
              if (documentName.isEmpty) {
                _showSnackBar('Name cannot be empty');
                return;
              }

              Navigator.of(dialogContext).pop();

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: ShadInput(
            controller: nameController,
            placeholder: const Text('Document name'),
            autofocus: true,
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      // Launch cunning_document_scanner_plus with filters mode
      // This allows users to apply filters during scanning
      final scannedImages = await CunningDocumentScanner.getPictures(
        mode: ScannerMode.full, // Enable AI Enhance + Clean features
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
      _showSnackBar('Scan failed: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Scan failed: $e');
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
  }

  void _editDocumentName(ScanDocument document) async {
    final TextEditingController controller = TextEditingController(text: document.name);

    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Rename Scan'),
        description: const Text('Enter a new name for this document'),
        constraints: const BoxConstraints(maxWidth: 320),
        radius: const BorderRadius.all(Radius.circular(16)),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ShadButton(
            child: const Text('Save'),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                _showSnackBar('Name cannot be empty');
                return;
              }

              Navigator.of(dialogContext).pop();

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: ShadInput(
            controller: controller,
            placeholder: const Text('Document name'),
            autofocus: true,
          ),
        ),
      ),
    );
  }

  void _deleteDocument(ScanDocument document) async {
    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Delete Scan'),
        description: Text('Delete "${document.name}"?'),
        constraints: const BoxConstraints(maxWidth: 320),
        radius: const BorderRadius.all(Radius.circular(16)),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();

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
    );
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

      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a separate page
      for (final imagePath in document.imagePaths) {
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) continue;

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

      // Generate filename
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.pdf';

      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(path.join(tempDir.path, fileName));
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Share the PDF using the printing package
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );

      // No snackbar for share - dialog is self-explanatory
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      _showSnackBar('Failed to export PDF');
    }
  }

  /// Save PDF to Downloads folder using MediaStore (no permission required)
  Future<void> _savePdfLocally(ScanDocument document) async {
    try {
      _showSnackBar('Generating PDF...');

      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a separate page
      for (final imagePath in document.imagePaths) {
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) continue;

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

      // Generate filename
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      final fileName = '${document.name}_$timestamp.pdf';

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
      _showSnackBar('PDF saved to Downloads');

      // Open file manager to show the downloaded file
      await openFileManager();
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (!mounted) return;
      _showSnackBar('Failed to save PDF');
    }
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: DocumentSearchDelegate(_documents),
    );
  }

  void _showSnackBar(String message) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(message),
      ),
    );
  }
}

/// Search delegate for documents
class DocumentSearchDelegate extends SearchDelegate<ScanDocument?> {
  final List<ScanDocument> documents;

  DocumentSearchDelegate(this.documents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = documents.where((doc) {
      return doc.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results found',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final document = results[index];
        return ListTile(
          leading: const Icon(LucideIcons.fileText),
          title: Text(document.name),
          subtitle: Text('${document.imagePaths.length} pages'),
          onTap: () => close(context, document),
        );
      },
    );
  }
}
