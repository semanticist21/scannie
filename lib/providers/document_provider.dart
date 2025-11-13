import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scanned_document.dart';

class DocumentProvider extends ChangeNotifier {
  List<ScannedDocument> _documents = [];
  int _pdfCreatedToday = 0;
  String _lastResetDate = '';

  List<ScannedDocument> get documents => _documents;
  int get pdfCreatedToday => _pdfCreatedToday;
  final int maxPdfPerDay = 3;

  DocumentProvider() {
    _loadDocuments();
    _loadPdfCount();
  }

  /// 문서 추가
  void addDocument(ScannedDocument document) {
    _documents.add(document);
    _saveDocuments();
    notifyListeners();
  }

  /// 문서 삭제
  void removeDocument(int index) {
    _documents.removeAt(index);
    _saveDocuments();
    notifyListeners();
  }

  /// 문서 업데이트 (편집 후)
  void updateDocument(int index, ScannedDocument document) {
    _documents[index] = document;
    _saveDocuments();
    notifyListeners();
  }

  /// 문서 순서 변경
  void reorderDocuments(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }
    final item = _documents.removeAt(oldIndex);
    _documents.insert(newIndex, item);
    _saveDocuments();
    notifyListeners();
  }

  /// 모든 문서 삭제
  void clearAllDocuments() {
    _documents.clear();
    _saveDocuments();
    notifyListeners();
  }

  /// PDF 생성 횟수 증가
  void incrementPdfCount() {
    _checkAndResetPdfCount();
    _pdfCreatedToday++;
    _savePdfCount();
    notifyListeners();
  }

  /// PDF 생성 가능 여부 확인
  bool canCreatePdf() {
    _checkAndResetPdfCount();
    return _pdfCreatedToday < maxPdfPerDay;
  }

  /// 하루가 지났는지 확인하고 리셋
  void _checkAndResetPdfCount() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastResetDate != today) {
      _pdfCreatedToday = 0;
      _lastResetDate = today;
      _savePdfCount();
    }
  }

  /// SharedPreferences에서 문서 로드
  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('documents');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _documents = jsonList
            .map((json) => ScannedDocument.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('문서 로드 실패: $e');
    }
  }

  /// SharedPreferences에 문서 저장
  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _documents.map((doc) => doc.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString('documents', jsonString);
    } catch (e) {
      debugPrint('문서 저장 실패: $e');
    }
  }

  /// PDF 생성 횟수 로드
  Future<void> _loadPdfCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pdfCreatedToday = prefs.getInt('pdfCreatedToday') ?? 0;
      _lastResetDate = prefs.getString('lastResetDate') ?? '';
      _checkAndResetPdfCount();
      notifyListeners();
    } catch (e) {
      debugPrint('PDF 카운트 로드 실패: $e');
    }
  }

  /// PDF 생성 횟수 저장
  Future<void> _savePdfCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pdfCreatedToday', _pdfCreatedToday);
      await prefs.setString('lastResetDate', _lastResetDate);
    } catch (e) {
      debugPrint('PDF 카운트 저장 실패: $e');
    }
  }
}
