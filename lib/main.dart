import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'providers/document_provider.da

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ScannieApp());
}

class ScannieApp extends StatelessWidget {
  const ScannieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DocumentProvider(),
      child: MaterialApp(
        title: 'Scannie',
        debugShowCheckedModeBanner: false,

        // Material 3 테마 적용
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        home: const HomeScreen(),
      ),
    );
  }
}
