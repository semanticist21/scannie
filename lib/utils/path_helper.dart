import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for converting between relative and absolute paths
/// This prevents data loss when iOS changes sandbox UUID on app updates
class PathHelper {
  static const String _scannieDir = 'Scannie';
  static String? _cachedDocsPath;

  /// Get the base documents directory path (cached for performance)
  static Future<String> getDocsPath() async {
    if (_cachedDocsPath != null) return _cachedDocsPath!;
    final docsDir = await getApplicationDocumentsDirectory();
    _cachedDocsPath = docsDir.path;
    return _cachedDocsPath!;
  }

  /// Clear cached path (useful for testing)
  static void clearCache() {
    _cachedDocsPath = null;
  }

  /// Check if a path is already a relative path (doesn't start with /)
  static bool isRelativePath(String filePath) {
    return !filePath.startsWith('/');
  }

  /// Check if path is in our Scannie directory
  static bool isInScannieDir(String filePath) {
    return filePath.contains('/$_scannieDir/');
  }

  /// Convert absolute path to relative path for storage
  /// Example: /var/.../Documents/Scannie/doc123/page_001.jpg -> Scannie/doc123/page_001.jpg
  static Future<String> toRelativePath(String absolutePath) async {
    // Already relative
    if (isRelativePath(absolutePath)) {
      return absolutePath;
    }

    // Check if it's in our Scannie directory
    if (isInScannieDir(absolutePath)) {
      // Extract the relative part starting from "Scannie/"
      final scannieIndex = absolutePath.indexOf('/$_scannieDir/');
      if (scannieIndex != -1) {
        return absolutePath.substring(scannieIndex + 1); // Skip the leading /
      }
    }

    // If not in Scannie dir, try to make it relative to Documents
    final docsPath = await getDocsPath();
    if (absolutePath.startsWith(docsPath)) {
      return absolutePath.substring(docsPath.length + 1); // +1 for the /
    }

    // Can't convert, return as-is (legacy path)
    debugPrint('⚠️ Cannot convert to relative: $absolutePath');
    return absolutePath;
  }

  /// Convert relative path to absolute path for runtime use
  /// Example: Scannie/doc123/page_001.jpg -> /var/.../Documents/Scannie/doc123/page_001.jpg
  /// Also handles legacy absolute paths by reconstructing with current base
  static Future<String> toAbsolutePath(String storedPath) async {
    final docsPath = await getDocsPath();

    // Already relative, just prepend docs path
    if (isRelativePath(storedPath)) {
      return path.join(docsPath, storedPath);
    }

    // It's an absolute path - check if it's a legacy path with old UUID
    // If it contains /Scannie/, extract relative part and reconstruct
    if (isInScannieDir(storedPath)) {
      final scannieIndex = storedPath.indexOf('/$_scannieDir/');
      if (scannieIndex != -1) {
        final relativePart = storedPath.substring(scannieIndex + 1);
        final newAbsolutePath = path.join(docsPath, relativePart);

        // Check if file exists at new path
        if (await File(newAbsolutePath).exists()) {
          debugPrint('📂 Migrated legacy path: $storedPath -> $newAbsolutePath');
          return newAbsolutePath;
        }

        // File might still be at old location (same app version)
        if (await File(storedPath).exists()) {
          return storedPath;
        }

        // Neither exists, return new path anyway (file may be missing)
        debugPrint('⚠️ File not found at legacy or new path: $storedPath');
        return newAbsolutePath;
      }
    }

    // Not in Scannie dir, return as-is
    return storedPath;
  }

  /// Convert list of paths to relative paths
  static Future<List<String>> toRelativePaths(List<String> paths) async {
    final results = <String>[];
    for (final p in paths) {
      results.add(await toRelativePath(p));
    }
    return results;
  }

  /// Convert list of paths to absolute paths
  static Future<List<String>> toAbsolutePaths(List<String> paths) async {
    final results = <String>[];
    for (final p in paths) {
      results.add(await toAbsolutePath(p));
    }
    return results;
  }

  /// Migrate a legacy absolute path to new relative format
  /// Returns the relative path if file exists and was migrated, null otherwise
  static Future<String?> migrateLegacyPath(String legacyAbsolutePath) async {
    // Already relative
    if (isRelativePath(legacyAbsolutePath)) {
      return legacyAbsolutePath;
    }

    // Check if file exists at legacy path
    final file = File(legacyAbsolutePath);
    if (!await file.exists()) {
      debugPrint('⚠️ Legacy file not found: $legacyAbsolutePath');
      return null;
    }

    // File exists, return as relative
    return toRelativePath(legacyAbsolutePath);
  }

  /// Get the Scannie storage directory for a document
  static Future<Directory> getDocumentDir(String documentId) async {
    final docsPath = await getDocsPath();
    return Directory(path.join(docsPath, _scannieDir, documentId));
  }

  /// Create the Scannie directory structure if needed
  static Future<Directory> ensureDocumentDir(String documentId) async {
    final dir = await getDocumentDir(documentId);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
