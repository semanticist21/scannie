import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as path;

/// Result of PDF import operation
class PdfImportResult {
  final List<String> imagePaths;
  final bool success;
  final String? error;
  final bool cancelled;

  const PdfImportResult._({
    required this.imagePaths,
    required this.success,
    this.error,
    this.cancelled = false,
  });

  factory PdfImportResult.success(List<String> paths) =>
      PdfImportResult._(imagePaths: paths, success: true);

  factory PdfImportResult.error(String message) =>
      PdfImportResult._(imagePaths: [], success: false, error: message);

  factory PdfImportResult.cancelled() =>
      PdfImportResult._(imagePaths: [], success: false, cancelled: true);
}

/// Service for importing PDF files and extracting pages as images
class PdfImportService {
  static final PdfImportService _instance = PdfImportService._internal();
  static PdfImportService get instance => _instance;

  PdfImportService._internal();

  /// Pick a PDF file and extract all pages as images
  /// Returns list of temporary image file paths
  ///
  /// [onProgress] callback receives (currentPage, totalPages)
  Future<PdfImportResult> importPdfAsImages({
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return PdfImportResult.cancelled();
      }

      final pdfPath = result.files.first.path;
      if (pdfPath == null) {
        return PdfImportResult.error('Could not access PDF file');
      }

      // Validate PDF file before processing
      final validationError = await _validatePdfFile(pdfPath);
      if (validationError != null) {
        return PdfImportResult.error(validationError);
      }

      // Extract pages as images
      return await extractPdfPagesAsImages(
        pdfPath: pdfPath,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('📄 PDF import error: $e');
      return PdfImportResult.error(e.toString());
    }
  }

  /// Validate PDF file before processing
  /// Returns error message if invalid, null if valid
  Future<String?> _validatePdfFile(String pdfPath) async {
    try {
      final file = File(pdfPath);

      // Check file exists
      if (!await file.exists()) {
        return 'PDF file not found';
      }

      // Check file size (max 100MB to prevent memory issues)
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) {
        return 'PDF file is too large (max 100MB)';
      }

      if (fileSize == 0) {
        return 'PDF file is empty';
      }

      // Check PDF magic bytes (%PDF-)
      final bytes = await file.openRead(0, 5).first;
      if (bytes.length < 5) {
        return 'Invalid PDF file';
      }

      final header = String.fromCharCodes(bytes);
      if (!header.startsWith('%PDF')) {
        return 'Invalid PDF file format';
      }

      return null; // Valid
    } catch (e) {
      debugPrint('📄 PDF validation error: $e');
      return 'Could not validate PDF file';
    }
  }

  /// Extract all pages from a PDF file as images
  /// [pdfPath] - path to the PDF file
  /// [dpi] - resolution for rendering (default 150 for good quality/size balance)
  /// [onProgress] callback receives (currentPage, totalPages)
  Future<PdfImportResult> extractPdfPagesAsImages({
    required String pdfPath,
    int dpi = 150,
    void Function(int current, int total)? onProgress,
  }) async {
    PdfDocument? document;

    try {
      // Open PDF document with timeout
      document = await PdfDocument.openFile(pdfPath)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('PDF loading timed out');
      });

      final pageCount = document.pagesCount;

      if (pageCount == 0) {
        return PdfImportResult.error('PDF has no pages');
      }

      debugPrint('📄 PDF opened: $pageCount pages');

      // Get temp directory for storing images
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfName = path.basenameWithoutExtension(pdfPath);

      final List<String> imagePaths = [];

      // Render each page
      for (int i = 1; i <= pageCount; i++) {
        onProgress?.call(i, pageCount);

        PdfPage? page;
        try {
          // Get page with timeout
          page = await document.getPage(i)
              .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Page $i loading timed out');
          });

          // Calculate render size based on DPI
          // PDF default is 72 DPI, so multiply by (target DPI / 72)
          final scale = dpi / 72.0;
          final renderWidth = (page.width * scale).round();
          final renderHeight = (page.height * scale).round();

          debugPrint('📄 Rendering page $i: ${renderWidth}x$renderHeight');

          // Render page to image with timeout
          final pageImage = await page.render(
            width: renderWidth.toDouble(),
            height: renderHeight.toDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            throw TimeoutException('Page $i rendering timed out');
          });

          if (pageImage == null) {
            debugPrint('📄 Failed to render page $i');
            continue;
          }

          // Get image bytes
          final imageBytes = pageImage.bytes;
          if (imageBytes.isEmpty) {
            debugPrint('📄 Empty image bytes for page $i');
            continue;
          }

          // Save to temp file
          final imagePath = path.join(
            tempDir.path,
            'pdf_import_${pdfName}_${timestamp}_page_${i.toString().padLeft(3, '0')}.png',
          );

          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(imageBytes);
          imagePaths.add(imagePath);

          debugPrint('📄 Saved page $i: $imagePath');
        } catch (e) {
          debugPrint('📄 Error processing page $i: $e');
          // Continue with other pages even if one fails
        } finally {
          // Always close the page
          await page?.close();
        }
      }

      if (imagePaths.isEmpty) {
        return PdfImportResult.error('Could not extract any pages from PDF');
      }

      return PdfImportResult.success(imagePaths);
    } on TimeoutException catch (e) {
      debugPrint('📄 PDF timeout: $e');
      return PdfImportResult.error('PDF processing timed out. Try a smaller file.');
    } catch (e) {
      debugPrint('📄 PDF extraction error: $e');
      return PdfImportResult.error('Failed to process PDF: ${e.toString()}');
    } finally {
      // Always close the document
      await document?.close();
    }
  }
}
