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
}
