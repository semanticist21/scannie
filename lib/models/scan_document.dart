import 'dart:convert';

/// PDF quality settings for export
enum PdfQuality {
  low,      // ~5-10% of original
  medium,   // ~15-20% of original
  high,     // ~30-40% of original
  original, // 100% original quality
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

  const ScanDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.imagePaths,
    this.isProcessed = false,
    this.pdfQuality = PdfQuality.high,
  });

  ScanDocument copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? imagePaths,
    bool? isProcessed,
    PdfQuality? pdfQuality,
  }) {
    return ScanDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      isProcessed: isProcessed ?? this.isProcessed,
      pdfQuality: pdfQuality ?? this.pdfQuality,
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
        orElse: () => PdfQuality.high,
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
