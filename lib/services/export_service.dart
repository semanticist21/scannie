import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:archive/archive.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/scan_document.dart';
import 'pdf_generator.dart';

/// Result type for export operations
enum ExportResultType {
  success,
  cancelled,
  errorGeneratingPdf,
  errorCreatingZip,
  errorSavingFile,
  errorSavingImages,
  errorNoImages,
  permissionDenied,
}

/// Result of an export operation
class ExportResult {
  final ExportResultType type;
  final String? filePath;
  final int? savedCount;
  final int? totalCount;
  final String? errorDetails;

  const ExportResult({
    required this.type,
    this.filePath,
    this.savedCount,
    this.totalCount,
    this.errorDetails,
  });

  bool get isSuccess => type == ExportResultType.success;
  bool get isCancelled => type == ExportResultType.cancelled;
  bool get isError =>
      type != ExportResultType.success && type != ExportResultType.cancelled;
}

/// Centralized service for exporting documents as PDF, ZIP, or images
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Generate a timestamped filename (without extension)
  String _generateFileName(String baseName) {
    final timestamp =
        DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
    return '${baseName}_$timestamp';
  }

  /// Save PDF using system file picker (user chooses location)
  /// Works on both Android and iOS
  Future<ExportResult> savePdfWithPicker(ScanDocument document) async {
    if (document.imagePaths.isEmpty) {
      return const ExportResult(type: ExportResultType.errorNoImages);
    }

    try {
      // Generate PDF
      final pdfFile = await PdfGenerator.generatePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
        pageSize: document.pdfPageSize,
        orientation: document.pdfOrientation,
        imageFit: document.pdfImageFit,
        margin: document.pdfMargin,
      );

      final fileName = _generateFileName(document.name);
      final pdfBytes = await pdfFile.readAsBytes();

      // Use saveAs to let user choose location
      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (savedPath == null) {
        return const ExportResult(type: ExportResultType.cancelled);
      }

      return ExportResult(
        type: ExportResultType.success,
        filePath: savedPath,
      );
    } catch (e) {
      debugPrint('Error saving PDF: $e');

      // Check if user cancelled
      if (e.toString().contains('cancel') || e.toString().contains('Cancel')) {
        return const ExportResult(type: ExportResultType.cancelled);
      }

      return ExportResult(
        type: ExportResultType.errorSavingFile,
        errorDetails: e.toString(),
      );
    }
  }

  /// Save ZIP using system file picker (user chooses location)
  /// Works on both Android and iOS
  Future<ExportResult> saveZipWithPicker(ScanDocument document) async {
    if (document.imagePaths.isEmpty) {
      return const ExportResult(type: ExportResultType.errorNoImages);
    }

    try {
      // Create ZIP archive
      final zipData = await compute(_createZipArchive, document.imagePaths);
      if (zipData == null) {
        return const ExportResult(type: ExportResultType.errorCreatingZip);
      }

      final fileName = _generateFileName(document.name);

      // Use saveAs to let user choose location
      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: Uint8List.fromList(zipData),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );

      if (savedPath == null) {
        return const ExportResult(type: ExportResultType.cancelled);
      }

      return ExportResult(
        type: ExportResultType.success,
        filePath: savedPath,
      );
    } catch (e) {
      debugPrint('Error saving ZIP: $e');

      // Check if user cancelled
      if (e.toString().contains('cancel') || e.toString().contains('Cancel')) {
        return const ExportResult(type: ExportResultType.cancelled);
      }

      return ExportResult(
        type: ExportResultType.errorSavingFile,
        errorDetails: e.toString(),
      );
    }
  }

  /// Check and request photo library permission
  /// Returns true if permission granted, false otherwise
  Future<bool> _checkPhotoPermission() async {
    if (Platform.isIOS) {
      // Try photosAddOnly first (write-only, less intrusive)
      var status = await Permission.photosAddOnly.status;

      if (status.isDenied) {
        status = await Permission.photosAddOnly.request();
      }

      // If photosAddOnly works, we're done
      if (status.isGranted || status.isLimited) {
        return true;
      }

      // Fallback: Some iOS versions return permanentlyDenied for photosAddOnly
      // without showing dialog. Try full photos permission as fallback.
      // See: https://github.com/Baseflow/flutter-permission-handler/issues/1325
      if (status.isPermanentlyDenied) {
        var photosStatus = await Permission.photos.status;
        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }
        return photosStatus.isGranted || photosStatus.isLimited;
      }

      return false;
    } else {
      // Android
      var status = await Permission.photos.status;

      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      return status.isGranted || status.isLimited;
    }
  }

  /// Save images to photo gallery
  Future<ExportResult> saveImagesToGallery(List<String> imagePaths) async {
    return saveImagesToGalleryCancellable(imagePaths, null);
  }

  /// Save images to photo gallery with cancellation support.
  /// Pass a `ValueNotifier<bool>` as cancelToken - set value to true to cancel.
  Future<ExportResult> saveImagesToGalleryCancellable(
    List<String> imagePaths,
    ValueNotifier<bool>? cancelToken,
  ) async {
    if (imagePaths.isEmpty) {
      return const ExportResult(type: ExportResultType.errorNoImages);
    }

    // Check permission first
    final hasPermission = await _checkPhotoPermission();
    if (!hasPermission) {
      return const ExportResult(type: ExportResultType.permissionDenied);
    }

    try {
      int savedCount = 0;

      for (final imagePath in imagePaths) {
        // Check cancellation before each save
        if (cancelToken?.value == true) {
          return ExportResult(
            type: ExportResultType.cancelled,
            savedCount: savedCount,
            totalCount: imagePaths.length,
          );
        }

        final imageFile = File(imagePath);
        if (!await imageFile.exists()) continue;

        final result = await ImageGallerySaverPlus.saveFile(imageFile.path);
        if (result['isSuccess'] == true) {
          savedCount++;
        }
      }

      if (savedCount == 0) {
        return ExportResult(
          type: ExportResultType.errorSavingImages,
          savedCount: 0,
          totalCount: imagePaths.length,
        );
      }

      return ExportResult(
        type: ExportResultType.success,
        savedCount: savedCount,
        totalCount: imagePaths.length,
      );
    } catch (e) {
      debugPrint('Error saving images: $e');
      return ExportResult(
        type: ExportResultType.errorSavingImages,
        errorDetails: e.toString(),
      );
    }
  }

  /// Share PDF via system share sheet (existing behavior)
  Future<ExportResult> sharePdf(ScanDocument document) async {
    if (document.imagePaths.isEmpty) {
      return const ExportResult(type: ExportResultType.errorNoImages);
    }

    try {
      final pdfFile = await PdfGenerator.generatePdf(
        imagePaths: document.imagePaths,
        documentName: document.name,
        quality: document.pdfQuality,
        pageSize: document.pdfPageSize,
        orientation: document.pdfOrientation,
        imageFit: document.pdfImageFit,
        margin: document.pdfMargin,
      );

      final fileName = '${_generateFileName(document.name)}.pdf';

      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: fileName,
      );

      return ExportResult(
        type: ExportResultType.success,
        filePath: pdfFile.path,
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      return ExportResult(
        type: ExportResultType.errorGeneratingPdf,
        errorDetails: e.toString(),
      );
    }
  }
}

/// Creates ZIP archive from image paths (runs in isolate)
List<int>? _createZipArchive(List<String> imagePaths) {
  final archive = Archive();

  for (int i = 0; i < imagePaths.length; i++) {
    final imageFile = File(imagePaths[i]);
    if (!imageFile.existsSync()) continue;

    final bytes = imageFile.readAsBytesSync();
    final extension = imagePaths[i].split('.').last.toLowerCase();
    final fileName = 'page_${(i + 1).toString().padLeft(2, '0')}.$extension';

    archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
  }

  return ZipEncoder().encode(archive);
}
