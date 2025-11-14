import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/gallery_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/edit_screen.dart';
import 'screens/export_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'models/scan_document.dart';

void main() {
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ScannierApp());
}

class ScannierApp extends StatelessWidget {
  const ScannierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scannie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Initial route
      home: const GalleryScreen(),

      // Route configuration
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/camera':
            return MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            );

          case '/edit':
            return MaterialPageRoute(
              builder: (context) => const EditScreen(),
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

          case '/export':
            final document = settings.arguments as ScanDocument?;
            if (document == null) {
              return MaterialPageRoute(
                builder: (context) => const GalleryScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => ExportScreen(document: document),
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
