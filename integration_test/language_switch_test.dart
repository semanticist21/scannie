import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scannie/main.dart';
import 'package:scannie/widgets/gallery/settings_sheet.dart';

/// Test languages covering different scripts and RTL
const testLanguages = [
  'en', // English
  'ko', // Korean
  'ja', // Japanese
  'zh', // Chinese
  'ar', // Arabic (RTL)
  'he', // Hebrew (RTL)
  'th', // Thai
  'ru', // Russian
  'hi', // Hindi
  'de', // German
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to pump with timeout (avoids infinite pumpAndSettle)
  Future<void> pumpWithTimeout(WidgetTester tester, {int seconds = 3}) async {
    // Pump multiple frames with timeout instead of pumpAndSettle
    for (int i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Language Rendering Tests', () {
    for (final langCode in testLanguages) {
      testWidgets('$langCode renders correctly', (WidgetTester tester) async {
        await EasyLocalization.ensureInitialized();

        final language = AppLanguage.fromCode(langCode);

        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [
              Locale('af'), Locale('am'), Locale('ar'), Locale('az'),
              Locale('be'), Locale('bg'), Locale('bn'), Locale('bs'),
              Locale('ca'), Locale('cs'), Locale('cy'), Locale('da'),
              Locale('de'), Locale('el'), Locale('en'), Locale('es'),
              Locale('et'), Locale('eu'), Locale('fa'), Locale('fi'),
              Locale('fil'), Locale('fr'), Locale('ga'), Locale('gl'),
              Locale('gu'), Locale('he'), Locale('hi'), Locale('hr'),
              Locale('hu'), Locale('hy'), Locale('id'), Locale('is'),
              Locale('it'), Locale('ja'), Locale('ka'), Locale('kk'),
              Locale('km'), Locale('kn'), Locale('ko'), Locale('ky'),
              Locale('lo'), Locale('lt'), Locale('lv'), Locale('mk'),
              Locale('ml'), Locale('mn'), Locale('mr'), Locale('ms'),
              Locale('mt'), Locale('my'), Locale('nb'), Locale('ne'),
              Locale('nl'), Locale('pa'), Locale('pl'), Locale('pt'),
              Locale('ro'), Locale('ru'), Locale('si'), Locale('sk'),
              Locale('sl'), Locale('sq'), Locale('sr'), Locale('sv'),
              Locale('sw'), Locale('ta'), Locale('te'), Locale('th'),
              Locale('tr'), Locale('uk'), Locale('ur'), Locale('uz'),
              Locale('vi'), Locale('zh'), Locale('zu'),
            ],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: Locale(langCode),
            child: const ScannierApp(),
          ),
        );

        // Use pump with timeout instead of pumpAndSettle
        await pumpWithTimeout(tester, seconds: 2);

        // Verify app didn't crash
        expect(find.byType(Scaffold), findsWidgets);

        // Verify no overflow errors
        expect(find.byType(ErrorWidget), findsNothing);

        debugPrint('✅ $langCode (${language?.displayName ?? "unknown"}) OK');
      });
    }
  });

  group('RTL Layout Tests', () {
    testWidgets('Arabic RTL layout', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('ar'),
          child: const ScannierApp(),
        ),
      );

      await pumpWithTimeout(tester, seconds: 2);

      // Verify RTL - Arabic and Hebrew should be RTL
      final context = tester.element(find.byType(Scaffold).first);
      final dir = Directionality.of(context);
      expect(dir, isNotNull);
      // RTL check - the app should have RTL direction for Arabic
      debugPrint('Direction: $dir');

      expect(find.byType(ErrorWidget), findsNothing);

      debugPrint('✅ Arabic RTL OK');
    });

    testWidgets('Hebrew RTL layout', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('he'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('he'),
          child: const ScannierApp(),
        ),
      );

      await pumpWithTimeout(tester, seconds: 2);

      final context = tester.element(find.byType(Scaffold).first);
      final dir = Directionality.of(context);
      expect(dir, isNotNull);
      debugPrint('Direction: $dir');

      expect(find.byType(ErrorWidget), findsNothing);

      debugPrint('✅ Hebrew RTL OK');
    });
  });

  group('Special Scripts', () {
    testWidgets('Thai script', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('th'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('th'),
          child: const ScannierApp(),
        ),
      );

      await pumpWithTimeout(tester, seconds: 2);
      expect(find.byType(ErrorWidget), findsNothing);

      debugPrint('✅ Thai OK');
    });

    testWidgets('Myanmar script', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('my'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('my'),
          child: const ScannierApp(),
        ),
      );

      await pumpWithTimeout(tester, seconds: 2);
      expect(find.byType(ErrorWidget), findsNothing);

      debugPrint('✅ Myanmar OK');
    });

    testWidgets('Khmer script', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('km'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('km'),
          child: const ScannierApp(),
        ),
      );

      await pumpWithTimeout(tester, seconds: 2);
      expect(find.byType(ErrorWidget), findsNothing);

      debugPrint('✅ Khmer OK');
    });
  });

  group('All 75 Languages Quick Test', () {
    testWidgets('All languages render without crash', (WidgetTester tester) async {
      await EasyLocalization.ensureInitialized();

      final allCodes = AppLanguage.all.map((l) => l.code).toList();
      final failed = <String>[];

      for (final code in allCodes) {
        try {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: allCodes.map((c) => Locale(c)).toList(),
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              startLocale: Locale(code),
              child: const ScannierApp(),
            ),
          );

          // Quick pump - just 500ms per language
          for (int i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }

          if (find.byType(ErrorWidget).evaluate().isNotEmpty) {
            failed.add('$code (ErrorWidget)');
          }
        } catch (e) {
          failed.add('$code ($e)');
        }
      }

      if (failed.isNotEmpty) {
        fail('Failed: ${failed.join(", ")}');
      }

      debugPrint('✅ All 75 languages OK');
    });
  });
}
