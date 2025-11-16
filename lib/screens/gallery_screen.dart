import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';
import '../models/scan_document.dart';
import '../services/document_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/scan_card.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:awesome_dialog/awesome_dialog.dart';

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
    _loadDocuments();
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
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
            tooltip: 'Search',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : _buildDocumentList(),
      floatingActionButton: FilledButton.icon(
        onPressed: _openCamera,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 120,
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
          onShare: () => _shareDocument(document),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
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
    return Card(
      child: InkWell(
        onTap: () => _openDocument(document),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                ),
                child: _buildGridThumbnail(document),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.image,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${document.imagePaths.length}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        );
      }
    }

    // Fallback to icon if no images or file doesn't exist
    return const Center(
      child: Icon(
        Icons.description_outlined,
        size: 64,
        color: AppColors.primary,
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
        _showSnackBar('Document saved successfully');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnackBar('Scan failed: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Scan failed: $e');
    }
  }

  void _openDocument(ScanDocument document) {
    // Navigate to document viewer
    Navigator.pushNamed(
      context,
      '/viewer',
      arguments: document,
    );
  }

  void _editDocumentName(ScanDocument document) async {
    final TextEditingController controller = TextEditingController(text: document.name);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      title: 'Rename Scan',
      desc: 'Enter a new name for this document',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Text(
              'Rename Scan',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Document name',
                hintText: 'Enter new name',
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
        final newName = controller.text.trim();
        if (newName.isEmpty) {
          _showSnackBar('Name cannot be empty');
          return;
        }

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
      btnOkText: 'Save',
      btnCancelText: 'Cancel',
      btnCancelColor: AppColors.textSecondary,
    ).show();
  }

  void _deleteDocument(ScanDocument document) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Scan',
      desc: 'Delete "${document.name}"?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() {
          _documents.removeWhere((d) => d.id == document.id);
        });
        await _saveDocuments();
        if (!mounted) return;
        _showSnackBar('Document deleted');
      },
      btnOkText: 'Delete',
      btnCancelText: 'Cancel',
      btnOkColor: AppColors.error,
      btnCancelColor: AppColors.textSecondary,
    ).show();
  }

  void _shareDocument(ScanDocument document) {
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

      _showSnackBar('PDF exported: $fileName');
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      _showSnackBar('Failed to export PDF');
    }
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: DocumentSearchDelegate(_documents),
    );
  }

  void _showSnackBar(String message) {
    FToast fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.black87,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, color: Colors.white),
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
}

/// Search delegate for documents
class DocumentSearchDelegate extends SearchDelegate<ScanDocument?> {
  final List<ScanDocument> documents;

  DocumentSearchDelegate(this.documents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
              Icons.search_off,
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
          leading: const Icon(Icons.description),
          title: Text(document.name),
          subtitle: Text('${document.imagePaths.length} pages'),
          onTap: () => close(context, document),
        );
      },
    );
  }
}
