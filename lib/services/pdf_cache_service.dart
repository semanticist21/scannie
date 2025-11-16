import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// PDF cache service for managing PDF generation and caching
class PdfCacheService {
  static final PdfCacheService _instance = PdfCacheService._internal();
  factory PdfCacheService() => _instance;
  PdfCacheService._internal();

  final _cacheManager = DefaultCacheManager();

  /// Generate cache key from image paths
  /// Same image paths = same cache key
  String _generateCacheKey(List<String> imagePaths) {
    final combined = imagePaths.join('|');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return 'pdf_${digest.toString()}';
  }

  /// Get or generate PDF file
  /// Returns cached PDF if available, otherwise generates new one
  Future<File> getOrGeneratePdf({
    required List<String> imagePaths,
    required String documentName,
  }) async {
    final cacheKey = _generateCacheKey(imagePaths);

    // Check cache first
    final cachedFile = await _cacheManager.getFileFromCache(cacheKey);
    if (cachedFile != null && cachedFile.file.existsSync()) {
      return cachedFile.file;
    }

    // Generate new PDF
    final pdfFile = await _generatePdf(
      imagePaths: imagePaths,
      documentName: documentName,
    );

    // Cache the generated PDF
    await _cacheManager.putFile(
      cacheKey,
      await pdfFile.readAsBytes(),
      fileExtension: 'pdf',
    );

    return pdfFile;
  }

  /// Generate PDF from image paths
  Future<File> _generatePdf({
    required List<String> imagePaths,
    required String documentName,
  }) async {
    final pdf = pw.Document();

    // Add each image as a separate page
    for (final imagePath in imagePaths) {
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

    // Save to temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${documentName}_$timestamp.pdf';
    final file = File(path.join(tempDir.path, fileName));
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Clear all cached PDFs
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Remove specific PDF from cache
  Future<void> removePdfFromCache(List<String> imagePaths) async {
    final cacheKey = _generateCacheKey(imagePaths);
    await _cacheManager.removeFile(cacheKey);
  }
}
