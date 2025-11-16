import 'dart:convert';

/// Model representing a scanned document
class ScanDocument {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> imagePaths;
  final bool isProcessed;

  const ScanDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.imagePaths,
    this.isProcessed = false,
  });

  ScanDocument copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? imagePaths,
    bool? isProcessed,
  }) {
    return ScanDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      isProcessed: isProcessed ?? this.isProcessed,
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
