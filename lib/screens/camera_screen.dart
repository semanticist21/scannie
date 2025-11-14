import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/a4_guide_overlay.dart';
import '../models/scanned_document.dart';
import 'edge_detection_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDocumentAligned = false;
  Timer? _autoCaptureTimes;
  int _alignedFrames = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 카메라 권한 요청
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라 권한이 필요합니다')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // 사용 가능한 카메라 목록 가져오기
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 카메라가 없습니다')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // 후면 카메라 선택
    final camera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startEdgeDetection();
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
    }
  }

  void _startEdgeDetection() {
    // 실시간 엣지 디텍션 시뮬레이션
    // 실제로는 edge_detection 패키지나 ML Kit 사용
    _autoCaptureTimes = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // 여기서는 랜덤으로 시뮬레이션
      // 실제로는 카메라 프레임에서 문서 테두리를 찾아야 함
      final isAligned = _simulateDocumentDetection();

      if (isAligned) {
        _alignedFrames++;
        if (_alignedFrames >= 3) {
          // 3프레임 연속 정렬되면 자동 촬영
          _autoCapture();
          _alignedFrames = 0;
        }
      } else {
        _alignedFrames = 0;
      }

      if (mounted) {
        setState(() {
          _isDocumentAligned = isAligned;
        });
      }
    });
  }

  bool _simulateDocumentDetection() {
    // 실제로는 edge_detection 패키지로 문서 테두리 검출
    // 여기서는 30% 확률로 정렬된 것으로 시뮬레이션
    return DateTime.now().millisecond % 10 < 3;
  }

  Future<void> _autoCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // 타이머 정지 (중복 촬영 방지)
      _autoCaptureTimes?.cancel();

      // 자동 촬영 사운드/피드백
      _showCaptureAnimation();

      final image = await _controller!.takePicture();

      if (mounted) {
        // Edge detection 화면으로 이동
        final document = await Navigator.push<ScannedDocument>(
          context,
          MaterialPageRoute(
            builder: (context) => EdgeDetectionScreen(
              imagePath: image.path,
            ),
          ),
        );

        if (document != null && mounted) {
          // 문서가 저장되면 갤러리로 돌아감
          Navigator.pop(context, document);
        } else {
          // 취소하면 다시 타이머 시작
          _startEdgeDetection();
        }
      }
    } catch (e) {
      debugPrint('촬영 실패: $e');
      // 실패 시 다시 타이머 시작
      if (mounted) {
        _startEdgeDetection();
      }
    }
  }

  void _showCaptureAnimation() {
    // 촬영 애니메이션 (흰색 플래시)
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.white,
        builder: (context) => Container(),
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCaptureTimes?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // A4 가이드 오버레이
          Positioned.fill(
            child: A4GuideOverlay(isAligned: _isDocumentAligned),
          ),

          // 상단 UI
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),

          // 하단 안내 텍스트
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isDocumentAligned
                      ? '✓ 정렬됨 - 자동 촬영 중...'
                      : '문서를 가이드에 맞춰주세요',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // 수동 촬영 버튼
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _autoCapture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
