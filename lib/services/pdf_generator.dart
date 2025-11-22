import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/scan_document.dart';

/// Data class for passing to isolate
class _PdfGenerationData {
  final List<Uint8List> imageBytesList;
  final String documentName;
  final String tempDirPath;

  _PdfGenerationData({
    required this.imageBytesList,
    required this.documentName,
    required this.tempDirPath,
  });
}

/// Top-level function for isolate execution
Future<String> _generatePdfInIsolate(_PdfGenerationData data) async {
  final pdf = pw.Document();

  // Add each image as a separate page
  for (final imageBytes in data.imageBytesList) {
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
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = '${data.documentName}_$timestamp.pdf';
  final filePath = path.join(data.tempDirPath, fileName);
  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  return filePath;
}

/// Simple PDF generator without caching
class PdfGenerator {
  /// Generate PDF from image paths
  static Future<File> generatePdf({
    required List<String> imagePaths,
    required String documentName,
    PdfQuality quality = PdfQuality.high,
  }) async {
    // Compress images on main thread (platform channel)
    final imageBytesList = <Uint8List>[];
    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) continue;

      final imageBytes = await _compressImage(imagePath, quality);
      imageBytesList.add(imageBytes);
    }

    // Get temp directory on main thread (platform channel)
    final tempDir = await getTemporaryDirectory();

    // Generate PDF in separate isolate
    final data = _PdfGenerationData(
      imageBytesList: imageBytesList,
      documentName: documentName,
      tempDirPath: tempDir.path,
    );

    final filePath = await compute(_generatePdfInIsolate, data);
    return File(filePath);
  }

  /// Compress image based on quality setting
  static Future<Uint8List> _compressImage(String imagePath, PdfQuality quality) async {
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
}
