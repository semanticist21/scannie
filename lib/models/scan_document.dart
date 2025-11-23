import 'dart:convert';

/// PDF quality settings for export
enum PdfQuality {
  low,      // ~5-10% of original
  medium,   // ~15-20% of original
  high,     // ~30-40% of original
  original, // 100% original quality
}

/// PDF page size options
enum PdfPageSize {
  a4,
  letter,
  legal,
}

/// Extension for PdfPageSize display names
extension PdfPageSizeExtension on PdfPageSize {
  String get displayName {
    switch (this) {
      case PdfPageSize.a4:
        return 'A4';
      case PdfPageSize.letter:
        return 'Letter';
      case PdfPageSize.legal:
        return 'Legal';
    }
  }
}

/// PDF orientation options
enum PdfOrientation {
  portrait,
  landscape,
}

/// Extension for PdfOrientation display names
extension PdfOrientationExtension on PdfOrientation {
  String get displayName {
    switch (this) {
      case PdfOrientation.portrait:
        return 'Portrait';
      case PdfOrientation.landscape:
        return 'Landscape';
    }
  }
}

/// PDF image fit options
enum PdfImageFit {
  contain,  // Show full image with margins
  cover,    // Fill page, may crop
  fill,     // Stretch to fill (may distort)
}

/// Extension for PdfImageFit display names
extension PdfImageFitExtension on PdfImageFit {
  String get displayName {
    switch (this) {
      case PdfImageFit.contain:
        return 'Fit';
      case PdfImageFit.cover:
        return 'Fill';
      case PdfImageFit.fill:
        return 'Stretch';
    }
  }

  String get description {
    switch (this) {
      case PdfImageFit.contain:
        return 'Show full image';
      case PdfImageFit.cover:
        return 'Fill page, may crop';
      case PdfImageFit.fill:
        return 'Stretch to fill';
    }
  }
}

/// Extension for PdfQuality display and compression values
extension PdfQualityExtension on PdfQuality {
  String get displayName {
    switch (this) {
      case PdfQuality.low:
        return 'Low';
      case PdfQuality.medium:
        return 'Medium';
      case PdfQuality.high:
        return 'High';
      case PdfQuality.original:
        return 'Original';
    }
  }

  /// JPEG quality (0-100)
  int get jpegQuality {
    switch (this) {
      case PdfQuality.low:
        return 60;
      case PdfQuality.medium:
        return 75;
      case PdfQuality.high:
        return 85;
      case PdfQuality.original:
        return 100;
    }
  }

  /// Max dimension in pixels (width or height)
  int get maxDimension {
    switch (this) {
      case PdfQuality.low:
        return 1024;
      case PdfQuality.medium:
        return 1536;
      case PdfQuality.high:
        return 2048;
      case PdfQuality.original:
        return 0; // No resize
    }
  }

  /// Estimated compression ratio for size calculation
  double get compressionRatio {
    switch (this) {
      case PdfQuality.low:
        return 0.20;
      case PdfQuality.medium:
        return 0.50;
      case PdfQuality.high:
        return 0.95;
      case PdfQuality.original:
        return 1.0;
    }
  }
}

/// Model representing a scanned document
class ScanDocument {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> imagePaths;
  final bool isProcessed;
  final PdfQuality pdfQuality;
  final PdfPageSize pdfPageSize;
  final PdfOrientation pdfOrientation;
  final PdfImageFit pdfImageFit;

  const ScanDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.imagePaths,
    this.isProcessed = false,
    this.pdfQuality = PdfQuality.medium,
    this.pdfPageSize = PdfPageSize.a4,
    this.pdfOrientation = PdfOrientation.portrait,
    this.pdfImageFit = PdfImageFit.contain,
  });

  ScanDocument copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? imagePaths,
    bool? isProcessed,
    PdfQuality? pdfQuality,
    PdfPageSize? pdfPageSize,
    PdfOrientation? pdfOrientation,
    PdfImageFit? pdfImageFit,
  }) {
    return ScanDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      isProcessed: isProcessed ?? this.isProcessed,
      pdfQuality: pdfQuality ?? this.pdfQuality,
      pdfPageSize: pdfPageSize ?? this.pdfPageSize,
      pdfOrientation: pdfOrientation ?? this.pdfOrientation,
      pdfImageFit: pdfImageFit ?? this.pdfImageFit,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'imagePaths': imagePaths,
      'isProcessed': isProcessed,
      'pdfQuality': pdfQuality.name,
      'pdfPageSize': pdfPageSize.name,
      'pdfOrientation': pdfOrientation.name,
      'pdfImageFit': pdfImageFit.name,
    };
  }

  /// Create from JSON
  factory ScanDocument.fromJson(Map<String, dynamic> json) {
    return ScanDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePaths: List<String>.from(json['imagePaths'] as List),
      isProcessed: json['isProcessed'] as bool? ?? false,
      pdfQuality: PdfQuality.values.firstWhere(
        (e) => e.name == json['pdfQuality'],
        orElse: () => PdfQuality.medium,
      ),
      pdfPageSize: PdfPageSize.values.firstWhere(
        (e) => e.name == json['pdfPageSize'],
        orElse: () => PdfPageSize.a4,
      ),
      pdfOrientation: PdfOrientation.values.firstWhere(
        (e) => e.name == json['pdfOrientation'],
        orElse: () => PdfOrientation.portrait,
      ),
      pdfImageFit: PdfImageFit.values.firstWhere(
        (e) => e.name == json['pdfImageFit'],
        orElse: () => PdfImageFit.contain,
      ),
    );
  }

  /// Encode list to JSON string for SharedPreferences
  static String encodeList(List<ScanDocument> documents) {
    final jsonList = documents.map((doc) => doc.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Decode JSON string to list
  static List<ScanDocument> decodeList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ScanDocument.fromJson(json as Map<String, dynamic>)).toList();
  }
}
