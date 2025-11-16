import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_document.dart';

/// Service for persisting documents to local storage
class DocumentStorage {
  static const String _documentsKey = 'scanned_documents';

  /// Save documents to persistent storage
  static Future<void> saveDocuments(List<ScanDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = ScanDocument.encodeList(documents);
    await prefs.setString(_documentsKey, jsonString);
  }

  /// Load documents from persistent storage
  static Future<List<ScanDocument>> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_documentsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      return ScanDocument.decodeList(jsonString);
    } catch (e) {
      // If decoding fails, return empty list
      // This can happen if storage format changes
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
