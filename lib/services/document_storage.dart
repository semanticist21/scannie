import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_document.dart';
import '../utils/path_helper.dart';

/// Service for persisting documents to local storage
class DocumentStorage {
  static const String _documentsKey = 'scanned_documents';

  /// Save documents to persistent storage
  /// Converts absolute paths to relative paths before saving
  static Future<void> saveDocuments(List<ScanDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert all image paths to relative paths before saving
    final documentsWithRelativePaths = <ScanDocument>[];
    for (final doc in documents) {
      final relativePaths = await PathHelper.toRelativePaths(doc.imagePaths);
      documentsWithRelativePaths.add(doc.copyWith(imagePaths: relativePaths));
    }

    final jsonString = ScanDocument.encodeList(documentsWithRelativePaths);
    await prefs.setString(_documentsKey, jsonString);
    debugPrint('💾 Saved ${documents.length} documents with relative paths');
  }

  /// Load documents from persistent storage
  /// Converts relative paths to absolute paths after loading
  static Future<List<ScanDocument>> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_documentsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final documents = ScanDocument.decodeList(jsonString);

      // Convert all image paths to absolute paths for runtime use
      final documentsWithAbsolutePaths = <ScanDocument>[];
      for (final doc in documents) {
        final absolutePaths = await PathHelper.toAbsolutePaths(doc.imagePaths);
        documentsWithAbsolutePaths.add(doc.copyWith(imagePaths: absolutePaths));
      }

      debugPrint('📂 Loaded ${documents.length} documents with absolute paths');
      return documentsWithAbsolutePaths;
    } catch (e) {
      // If decoding fails, return empty list
      // This can happen if storage format changes
      debugPrint('❌ Failed to load documents: $e');
      return [];
    }
  }

  /// Clear all documents from storage
  static Future<void> clearDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsKey);
  }

  /// Delete a single document by ID
  Future<void> deleteDocument(String documentId) async {
    final documents = await loadDocuments();
    final updatedDocuments = documents.where((doc) => doc.id != documentId).toList();
    await saveDocuments(updatedDocuments);
  }
}
