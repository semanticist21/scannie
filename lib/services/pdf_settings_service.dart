import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_document.dart';

/// Service for managing global PDF default settings
class PdfSettingsService {
  static const String _keyQuality = 'pdf_default_quality';
  static const String _keyPageSize = 'pdf_default_page_size';
  static const String _keyOrientation = 'pdf_default_orientation';
  static const String _keyImageFit = 'pdf_default_image_fit';
  static const String _keyMargin = 'pdf_default_margin';

  static PdfSettingsService? _instance;
  late SharedPreferences _prefs;

  PdfSettingsService._();

  /// Get singleton instance
  static Future<PdfSettingsService> getInstance() async {
    if (_instance == null) {
      _instance = PdfSettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Get default PDF quality
  PdfQuality get defaultQuality {
    final value = _prefs.getString(_keyQuality);
    return PdfQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PdfQuality.medium,
    );
  }

  /// Set default PDF quality
  Future<void> setDefaultQuality(PdfQuality quality) async {
    await _prefs.setString(_keyQuality, quality.name);
  }

  /// Get default page size
  PdfPageSize get defaultPageSize {
    final value = _prefs.getString(_keyPageSize);
    return PdfPageSize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PdfPageSize.a4,
    );
  }

  /// Set default page size
  Future<void> setDefaultPageSize(PdfPageSize size) async {
    await _prefs.setString(_keyPageSize, size.name);
  }

  /// Get default orientation
  PdfOrientation get defaultOrientation {
    final value = _prefs.getString(_keyOrientation);
    return PdfOrientation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PdfOrientation.portrait,
    );
  }

  /// Set default orientation
  Future<void> setDefaultOrientation(PdfOrientation orientation) async {
    await _prefs.setString(_keyOrientation, orientation.name);
  }

  /// Get default image fit
  PdfImageFit get defaultImageFit {
    final value = _prefs.getString(_keyImageFit);
    return PdfImageFit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PdfImageFit.contain,
    );
  }

  /// Set default image fit
  Future<void> setDefaultImageFit(PdfImageFit fit) async {
    await _prefs.setString(_keyImageFit, fit.name);
  }

  /// Get default margin
  PdfMargin get defaultMargin {
    final value = _prefs.getString(_keyMargin);
    return PdfMargin.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PdfMargin.none,
    );
  }

  /// Set default margin
  Future<void> setDefaultMargin(PdfMargin margin) async {
    await _prefs.setString(_keyMargin, margin.name);
  }

  /// Create a ScanDocument with current default settings applied
  ScanDocument applyDefaultsToDocument(ScanDocument document) {
    return document.copyWith(
      pdfQuality: defaultQuality,
      pdfPageSize: defaultPageSize,
      pdfOrientation: defaultOrientation,
      pdfImageFit: defaultImageFit,
      pdfMargin: defaultMargin,
    );
  }
}
