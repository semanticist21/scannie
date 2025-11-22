import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/scan_document.dart';

/// PDF cache service for managing PDF generation and caching
class PdfCacheService {
  static final PdfCacheService _instance = PdfCacheService._internal();
  factory PdfCacheService() => _instance;
  PdfCacheService._internal();

  final _cacheManager = DefaultCacheManager();

  /// Generate cache key from image paths and quality
  /// Same image paths + quality = same cache key
  String _generateCacheKey(List<String> imagePaths, PdfQuality quality) {
    final combined = '${imagePaths.join('|')}|${quality.name}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return 'pdf_${digest.toString()}';
  }

  /// Get or generate PDF file
  /// Returns cached PDF if available, otherwise generates new one
  Future<File> getOrGeneratePdf({
    required List<String> imagePaths,
    required String documentName,
    PdfQuality quality = PdfQuality.high,
  }) async {
    final cacheKey = _generateCacheKey(imagePaths, quality);

    // Check cache first
    final cachedFile = await _cacheManager.getFileFromCache(cacheKey);
    if (cachedFile != null && cachedFile.file.existsSync()) {
      return cachedFile.file;
    }

    // Generate new PDF
    final pdfFile = await _generatePdf(
      imagePaths: imagePaths,
      documentName: documentName,
      quality: quality,
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
    PdfQuality quality = PdfQuality.high,
  }) async {
    final pdf = pw.Document();

    // Add each image as a separate page
    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) continue;

      // Compress image based on quality setting
      final imageBytes = await _compressImage(imagePath, quality);
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

  /// Compress image based on quality setting
  Future<Uint8List> _compressImage(String imagePath, PdfQuality quality) async {
    // For original quality, return uncompressed
    if (quality == PdfQuality.original) {
      return await File(imagePath).readAsBytes();
    }

    final result = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: quality.maxDimension,
      minHeight: quality.maxDimension,
      quality: quality.jpegQuality,
      format: CompressFormat.jpeg,
    );

    // If compression fails, return original
    if (result == null) {
      return await File(imagePath).readAsBytes();
    }

    return result;
  }

  /// Clear all cached PDFs
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Remove specific PDF from cache for all quality levels
  Future<void> removePdfFromCache(List<String> imagePaths) async {
    // Remove cache for all quality levels
    for (final quality in PdfQuality.values) {
      final cacheKey = _generateCacheKey(imagePaths, quality);
      await _cacheManager.removeFile(cacheKey);
    }
  }
}
