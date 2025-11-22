import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/scan_document.dart';

/// Simple PDF generator without caching
class PdfGenerator {
  /// Generate PDF from image paths
  static Future<File> generatePdf({
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
