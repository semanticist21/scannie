import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/scanned_document.dart';
import '../services/image_service.dart';
import 'premium_screen.dart';

class EditScreen extends StatefulWidget {
  final ScannedDocument document;

  const EditScreen({super.key, required this.document});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late String _currentImagePath;
  final ImageService _imageService = ImageService();
  bool _isProcessing = false;

  // 필터 상태
  String _selectedFilter = 'original';

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.document.imagePath;
  }

  Future<void> _applyFilter(String filter) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedFilter = filter;
    });

    try {
      String newPath;

      switch (filter) {
        case 'grayscale':
          newPath = await _imageService.convertToGrayscale(widget.document.imagePath);
          break;
        case 'enhance':
          newPath = await _imageService.enhanceImage(widget.document.imagePath);
          break;
        case 'original':
          newPath = widget.document.imagePath;
          break;
        default:
          newPath = _currentImagePath;
      }

      if (mounted) {
        setState(() {
          _currentImagePath = newPath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('필터 적용 실패: $e')),
        );
      }
    }
  }

  Future<void> _cropImage() async {
    if (_isProcessing) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentImagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: '이미지 자르기',
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _currentImagePath = croppedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자르기 실패: $e')),
        );
      }
    }
  }

  Future<void> _rotateImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final rotatedPath = await _imageService.rotateImage(_currentImagePath);

      if (mounted) {
        setState(() {
          _currentImagePath = rotatedPath;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지가 90도 회전되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회전 실패: $e')),
        );
      }
    }
  }

  void _save() {
    final updatedDocument = ScannedDocument(
      id: widget.document.id,
      imagePath: _currentImagePath,
      createdAt: widget.document.createdAt,
    );
    Navigator.pop(context, updatedDocument);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('편집'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _save,
            child: const Text(
              '완료',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 이미지 프리뷰
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : Image.file(
                        File(_currentImagePath),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),

          // 필터 선택
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '필터',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterOption(
                        label: '원본',
                        icon: Icons.image,
                        isSelected: _selectedFilter == 'original',
                        onTap: () => _applyFilter('original'),
                      ),
                      const SizedBox(width: 12),
                      _FilterOption(
                        label: '향상',
                        icon: Icons.auto_awesome,
                        isSelected: _selectedFilter == 'enhance',
                        onTap: () => _applyFilter('enhance'),
                      ),
                      const SizedBox(width: 12),
                      _FilterOption(
                        label: '흑백',
                        icon: Icons.filter_b_and_w,
                        isSelected: _selectedFilter == 'grayscale',
                        onTap: () => _applyFilter('grayscale'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 추가 도구 (프리미엄 기능)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildToolButton(
                        icon: Icons.crop,
                        label: '자르기',
                        onTap: _cropImage,
                      ),
                      const SizedBox(height: 8),
                      _buildToolButton(
                        icon: Icons.rotate_right,
                        label: '회전',
                        onTap: _rotateImage,
                      ),
                      const SizedBox(height: 8),
                      _buildToolButton(
                        icon: Icons.high_quality,
                        label: '업스케일링 (Pro)',
                        isPro: true,
                        onTap: () {
                          _showProDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPro = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isPro ? Colors.amber : Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isPro ? Colors.amber[700] : Colors.black,
                ),
              ),
            ),
            if (isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showProDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리미엄 기능'),
        content: const Text(
          '업스케일링은 프리미엄 기능입니다.\n'
          '프리미엄으로 업그레이드하여 고해상도 이미지를 만들어보세요!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              // 프리미엄 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            child: const Text('프리미엄 보기'),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
