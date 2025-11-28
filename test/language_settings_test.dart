import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:scannie/widgets/gallery/settings_sheet.dart';

void main() {
  group('AppLanguage', () {
    test('should have exactly 75 languages', () {
      expect(AppLanguage.all.length, equals(75));
    });

    test('all language codes should be unique', () {
      final codes = AppLanguage.all.map((lang) => lang.code).toSet();
      expect(codes.length, equals(AppLanguage.all.length));
    });

    test('all display names should be non-empty', () {
      for (final lang in AppLanguage.all) {
        expect(lang.displayName.isNotEmpty, isTrue,
            reason: 'Language ${lang.code} has empty displayName');
      }
    });

    test('all native names should be non-empty', () {
      for (final lang in AppLanguage.all) {
        expect(lang.nativeName.isNotEmpty, isTrue,
            reason: 'Language ${lang.code} has empty nativeName');
      }
    });

    test('fromCode should return correct language for all codes', () {
      for (final lang in AppLanguage.all) {
        final found = AppLanguage.fromCode(lang.code);
        expect(found, isNotNull, reason: 'Language ${lang.code} not found');
        expect(found!.code, equals(lang.code));
        expect(found.displayName, equals(lang.displayName));
        expect(found.nativeName, equals(lang.nativeName));
      }
    });

    test('fromCode should return null for unknown codes', () {
      expect(AppLanguage.fromCode('xyz'), isNull);
      expect(AppLanguage.fromCode(''), isNull);
      expect(AppLanguage.fromCode('unknown'), isNull);
    });

    test('equality should work correctly', () {
      final lang1 = AppLanguage.fromCode('en');
      final lang2 = AppLanguage.fromCode('en');
      final lang3 = AppLanguage.fromCode('ko');

      expect(lang1, equals(lang2));
      expect(lang1, isNot(equals(lang3)));
    });

    test('hashCode should be consistent with equality', () {
      final lang1 = AppLanguage.fromCode('en');
      final lang2 = AppLanguage.fromCode('en');

      expect(lang1.hashCode, equals(lang2.hashCode));
    });

    test('should contain all Google Play Store supported language codes', () {
      final expectedCodes = [
        'af', 'am', 'ar', 'az', 'be', 'bg', 'bn', 'bs', 'ca', 'cs',
        'cy', 'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi',
        'fil', 'fr', 'ga', 'gl', 'gu', 'he', 'hi', 'hr', 'hu', 'hy',
        'id', 'is', 'it', 'ja', 'ka', 'kk', 'km', 'kn', 'ko', 'ky',
        'lo', 'lt', 'lv', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt', 'my',
        'nb', 'ne', 'nl', 'pa', 'pl', 'pt', 'ro', 'ru', 'si', 'sk',
        'sl', 'sq', 'sr', 'sv', 'sw', 'ta', 'te', 'th', 'tr', 'uk',
        'ur', 'uz', 'vi', 'zh', 'zu',
      ];

      final actualCodes = AppLanguage.all.map((lang) => lang.code).toSet();

      for (final code in expectedCodes) {
        expect(actualCodes.contains(code), isTrue,
            reason: 'Missing language code: $code');
      }
    });

    test('languages should be sorted alphabetically by displayName', () {
      final displayNames = AppLanguage.all.map((lang) => lang.displayName).toList();
      final sortedDisplayNames = List<String>.from(displayNames)..sort();

      expect(displayNames, equals(sortedDisplayNames));
    });
  });

  group('Translation Files', () {
    final translationsPath = 'assets/translations';

    test('all 75 translation files should exist', () {
      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        expect(file.existsSync(), isTrue,
            reason: 'Missing translation file: ${lang.code}.json');
      }
    });

    test('all translation files should be valid JSON', () {
      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          try {
            final content = file.readAsStringSync();
            json.decode(content);
          } catch (e) {
            fail('Invalid JSON in ${lang.code}.json: $e');
          }
        }
      }
    });

    test('all translation files should have required top-level keys', () {
      final requiredTopLevelKeys = [
        'common',
        'gallery',
        'edit',
        'viewer',
        'settings',
        'premium',
        'dialogs',
        'validation',
        'toast',
        'filters',
        'imageViewer',
        'pdfQuality',
        'tooltips',
        'tags',
      ];

      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;

          for (final key in requiredTopLevelKeys) {
            expect(data.containsKey(key), isTrue,
                reason: '${lang.code}.json missing top-level key: $key');
          }
        }
      }
    });

    test('all translation files should have settings.searchLanguage key', () {
      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;
          final settings = data['settings'] as Map<String, dynamic>?;

          expect(settings, isNotNull,
              reason: '${lang.code}.json missing settings section');
          expect(settings!.containsKey('searchLanguage'), isTrue,
              reason: '${lang.code}.json missing settings.searchLanguage key');
        }
      }
    });

    test('all translation files should have settings.noLanguageFound key', () {
      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;
          final settings = data['settings'] as Map<String, dynamic>?;

          expect(settings, isNotNull,
              reason: '${lang.code}.json missing settings section');
          expect(settings!.containsKey('noLanguageFound'), isTrue,
              reason: '${lang.code}.json missing settings.noLanguageFound key');
        }
      }
    });

    test('all translation files should have consistent key counts', () {
      int? expectedKeyCount;
      String? referenceFile;

      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;
          final keyCount = _countKeys(data);

          if (expectedKeyCount == null) {
            expectedKeyCount = keyCount;
            referenceFile = lang.code;
          } else {
            expect(keyCount, equals(expectedKeyCount),
                reason:
                    '${lang.code}.json has $keyCount keys, but $referenceFile.json has $expectedKeyCount keys');
          }
        }
      }
    });

    test('no translation file should contain empty string values', () {
      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;
          final emptyKeys = _findEmptyValues(data, '');

          expect(emptyKeys.isEmpty, isTrue,
              reason:
                  '${lang.code}.json has empty values at: ${emptyKeys.join(", ")}');
        }
      }
    });

    test('all translation files should preserve ICU message format parameters', () {
      // Check that parameter placeholders are present in translations
      final parametersToCheck = {
        'gallery.selectedCount': ['{count}'],
        'gallery.deleteScans': ['{count}'],
        'gallery.deletedScans': ['{count}'],
        'edit.title': ['{count}'],
        'viewer.pdfQuality': ['{quality}'],
        'viewer.deleteDocumentMessage': ['{name}'],
        'viewer.downloadImagesMessage': ['{count}'],
        'viewer.pageOf': ['{current}', '{total}'],
        'validation.nameTooLong': ['{max}'],
        'validation.nameForbiddenChars': ['{chars}'],
        'validation.tagTooLong': ['{max}'],
        'toast.failedToLoadDocuments': ['{error}'],
        'toast.failedToSaveImage': ['{error}'],
        'toast.failedToShareImage': ['{error}'],
        'toast.scanFailed': ['{error}'],
        'dialogs.deleteScanMessage': ['{name}'],
        'premium.unlockWithPrice': ['{0}'],
      };

      for (final lang in AppLanguage.all) {
        final file = File('$translationsPath/${lang.code}.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = json.decode(content) as Map<String, dynamic>;

          for (final entry in parametersToCheck.entries) {
            final keyPath = entry.key.split('.');
            final expectedParams = entry.value;

            dynamic value = data;
            for (final key in keyPath) {
              if (value is Map<String, dynamic>) {
                value = value[key];
              } else {
                value = null;
                break;
              }
            }

            if (value is String) {
              for (final param in expectedParams) {
                expect(value.contains(param), isTrue,
                    reason:
                        '${lang.code}.json: ${entry.key} missing parameter $param');
              }
            }
          }
        }
      }
    });
  });
}

/// Recursively count all leaf keys in a nested map
int _countKeys(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      count += _countKeys(value);
    } else {
      count++;
    }
  }
  return count;
}

/// Recursively find all paths with empty string values
List<String> _findEmptyValues(Map<String, dynamic> map, String prefix) {
  final emptyPaths = <String>[];
  for (final entry in map.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      emptyPaths.addAll(_findEmptyValues(entry.value, path));
    } else if (entry.value is String && (entry.value as String).isEmpty) {
      emptyPaths.add(path);
    }
  }
  return emptyPaths;
}
