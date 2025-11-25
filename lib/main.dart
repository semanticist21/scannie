import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_theme.dart';
import 'screens/gallery_screen.dart';
import 'screens/edit_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'models/scan_document.dart';
import 'services/ad_service.dart';

// Global RouteObserver for detecting route changes
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();

  // Initialize AdMob
  await AdService.instance.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ScannierApp(),
    ),
  );
}

class ScannierApp extends StatelessWidget {
  const ScannierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Scannie',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Shadcn theme configuration
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),

      // Material theme for backwards compatibility with existing Material widgets
      materialThemeBuilder: (context, theme) {
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
              settings: settings, // Pass arguments to EditScreen
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
    );
  }
}
