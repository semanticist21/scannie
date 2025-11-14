import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import '../models/scanned_document.dart';
import '../services/image_service.dart';

class EdgeDetectionScreen extends StatefulWidget {
  final String imagePath;

  const EdgeDetectionScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<EdgeDetectionScreen> createState() => _EdgeDetectionScreenState();
}

class _EdgeDetectionScreenState extends State<EdgeDetectionScreen> {
  String? _processedImagePath;
  bool _isProcessing = false;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _detectEdges();
  }

  Future<void> _detectEdges() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // edge_detection 패키지 사용
      // detectEdge()는 bool을 반환하며, 성공 시 자동으로 파일을 생성합니다
      bool success = await EdgeDetection.detectEdge(widget.imagePath);

      if (success) {
        // 감지 성공 - edge_detection 패키지가 자동으로 생성한 파일 사용
        // 패키지가 반환하는 경로를 사용해야 하는데, 현재 버전에서는 직접 경로를 얻을 수 없으므로
        // 원본 이미지를 사용
        setState(() {
          _processedImagePath = widget.imagePath;
          _isProcessing = false;
        });
      } else {
        // 감지 실패 - 원본 이미지를 그대로 사용
        setState(() {
          _processedImagePath = widget.imagePath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Edge detection 실패: $e');
      // 실패 시 원본 이미지 사용
      setState(() {
        _processedImagePath = widget.imagePath;
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_processedImagePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 이미지 향상 적용
      final enhancedPath = await _imageService.enhanceImage(_processedImagePath!);

      // 문서 생성
      final document = ScannedDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: enhancedPath,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context, document);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  void _retake() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _retake,
        ),
        title: const Text(
          '문서 감지',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '문서 테두리를 감지하고 있습니다...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : _processedImagePath != null
              ? Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.file(
                          File(_processedImagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _retake,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('다시 찍기'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveDocument,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('저장하기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
    );
  }
}
