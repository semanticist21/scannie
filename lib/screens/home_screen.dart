import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
import '../providers/document_provider.dart';
import '../models/scanned_document.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GalleryScreen(),
    const Center(child: Text('통계')), // 나중에 추가 가능
  ];

  Future<void> _openCamera() async {
    final result = await Navigator.push<ScannedDocument>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (result != null && mounted) {
      // 카메라에서 돌아온 문서를 Provider에 추가
      Provider.of<DocumentProvider>(context, listen: false).addDocument(result);

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 문서가 저장되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        icon: const Icon(Icons.camera_alt),
        label: const Text('스캔하기'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '보관함',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
          ),
        ],
      ),
    );
  }
}
