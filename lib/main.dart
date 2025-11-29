import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/gallery_screen.dart';
import 'screens/edit_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'models/scan_document.dart';
import 'services/ad_service.dart';
import 'services/theme_service.dart';
import 'services/purchase_service.dart';

// Global RouteObserver for detecting route changes
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  // Ensure Flutter bindings are initialized and preserve splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();

  // Initialize theme service
  await ThemeService.instance.initialize();

  // Initialize AdMob
  await AdService.instance.initialize();

  // Initialize In-App Purchase
  await PurchaseService.instance.initialize();

  // Remove splash screen after initialization
  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        // 75 languages supported by Google Play Store
        Locale('af'),      // Afrikaans
        Locale('am'),      // Amharic
        Locale('ar'),      // Arabic
        Locale('az'),      // Azerbaijani
        Locale('be'),      // Belarusian
        Locale('bg'),      // Bulgarian
        Locale('bn'),      // Bengali
        Locale('bs'),      // Bosnian
        Locale('ca'),      // Catalan
        Locale('cs'),      // Czech
        Locale('cy'),      // Welsh
        Locale('da'),      // Danish
        Locale('de'),      // German
        Locale('el'),      // Greek
        Locale('en'),      // English
        Locale('es'),      // Spanish
        Locale('et'),      // Estonian
        Locale('eu'),      // Basque
        Locale('fa'),      // Persian
        Locale('fi'),      // Finnish
        Locale('fil'),     // Filipino
        Locale('fr'),      // French
        Locale('ga'),      // Irish
        Locale('gl'),      // Galician
        Locale('gu'),      // Gujarati
        Locale('he'),      // Hebrew
        Locale('hi'),      // Hindi
        Locale('hr'),      // Croatian
        Locale('hu'),      // Hungarian
        Locale('hy'),      // Armenian
        Locale('id'),      // Indonesian
        Locale('is'),      // Icelandic
        Locale('it'),      // Italian
        Locale('ja'),      // Japanese
        Locale('ka'),      // Georgian
        Locale('kk'),      // Kazakh
        Locale('km'),      // Khmer
        Locale('kn'),      // Kannada
        Locale('ko'),      // Korean
        Locale('ky'),      // Kyrgyz
        Locale('lo'),      // Lao
        Locale('lt'),      // Lithuanian
        Locale('lv'),      // Latvian
        Locale('mk'),      // Macedonian
        Locale('ml'),      // Malayalam
        Locale('mn'),      // Mongolian
        Locale('mr'),      // Marathi
        Locale('ms'),      // Malay
        Locale('mt'),      // Maltese
        Locale('my'),      // Burmese
        Locale('nb'),      // Norwegian Bokmål
        Locale('ne'),      // Nepali
        Locale('nl'),      // Dutch
        Locale('pa'),      // Punjabi
        Locale('pl'),      // Polish
        Locale('pt'),      // Portuguese
        Locale('ro'),      // Romanian
        Locale('ru'),      // Russian
        Locale('si'),      // Sinhala
        Locale('sk'),      // Slovak
        Locale('sl'),      // Slovenian
        Locale('sq'),      // Albanian
        Locale('sr'),      // Serbian
        Locale('sv'),      // Swedish
        Locale('sw'),      // Swahili
        Locale('ta'),      // Tamil
        Locale('te'),      // Telugu
        Locale('th'),      // Thai
        Locale('tr'),      // Turkish
        Locale('uk'),      // Ukrainian
        Locale('ur'),      // Urdu
        Locale('uz'),      // Uzbek
        Locale('vi'),      // Vietnamese
        Locale('zh'),      // Chinese
        Locale('zu'),      // Zulu
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ScannierApp(),
    ),
  );
}

class ScannierApp extends StatefulWidget {
  const ScannierApp({super.key});

  @override
  State<ScannierApp> createState() => _ScannierAppState();
}

class _ScannierAppState extends State<ScannierApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeService.instance.flutterThemeMode;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Update system UI overlay based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.backgroundDark : AppColors.background,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return ToastificationWrapper(
      child: ShadApp(
        title: 'Scannie',
        debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme mode (system, light, or dark)
      themeMode: themeMode,

      // Light theme - Shadcn configuration with Teal color scheme
      // Teal palette from Tailwind CSS:
      // 400: #2dd4bf, 500: #14b8a6, 600: #0d9488, 700: #0f766e
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light().copyWith(
          primary: const Color(0xFF0d9488),  // teal-600
          primaryForeground: const Color(0xFFFFFFFF),
        ),
        primaryButtonTheme: ShadButtonTheme(
          backgroundColor: const Color(0xFF0d9488),
          foregroundColor: const Color(0xFFFFFFFF),
          hoverBackgroundColor: const Color(0xFF0f766e),
          hoverForegroundColor: const Color(0xFFFFFFFF),
        ),
      ),

      // Dark theme - Shadcn configuration with Teal color scheme
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark().copyWith(
          primary: const Color(0xFF2dd4bf),  // teal-400 (brighter for dark mode)
          primaryForeground: const Color(0xFF0F172A),  // slate-900
          background: AppColors.backgroundDark,
          foreground: AppColors.textPrimaryDark,
          card: AppColors.cardBackgroundDark,
          cardForeground: AppColors.textPrimaryDark,
          muted: AppColors.slate700,
          mutedForeground: AppColors.textSecondaryDark,
          border: AppColors.borderDark,
          input: AppColors.borderDark,
        ),
        primaryButtonTheme: ShadButtonTheme(
          backgroundColor: const Color(0xFF0d9488),  // teal-600
          foregroundColor: const Color(0xFFFFFFFF),
          hoverBackgroundColor: const Color(0xFF14b8a6),  // teal-500 (lighter on hover for dark)
          hoverForegroundColor: const Color(0xFFFFFFFF),
        ),
      ),

      // Material theme for backwards compatibility with existing Material widgets
      materialThemeBuilder: (context, theme) {
        final brightness = theme.brightness;
        if (brightness == Brightness.dark) {
          return AppTheme.darkTheme;
        }
        return AppTheme.lightTheme;
      },

      // Initial route
      home: const GalleryScreen(),

      // Navigator observers for route awareness
      navigatorObservers: [routeObserver],

      // Route configuration
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/edit':
            return MaterialPageRoute(
              builder: (context) => const EditScreen(),
              settings: settings,
            );

          case '/viewer':
            final document = settings.arguments as ScanDocument?;
            if (document == null) {
              return MaterialPageRoute(
                builder: (context) => const GalleryScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(document: document),
            );

          default:
            return MaterialPageRoute(
              builder: (context) => const GalleryScreen(),
            );
        }
      },
      ),
    );
  }
}
