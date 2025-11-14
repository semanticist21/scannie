import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

/// Camera screen with custom rectangle guide frame overlay
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isCapturing = false;
  bool _isAutoMode = true; // Auto capture mode
  int _countdown = 0; // Countdown for auto capture
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _errorMessage = '카메라 권한이 필요합니다';
      });
      return;
    }

    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = '카메라를 찾을 수 없습니다';
        });
        return;
      }

      // Use the back camera
      final camera = _cameras!.first;

      // Initialize camera controller
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Start auto capture countdown if in auto mode
      if (_isAutoMode) {
        _startCountdown();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '카메라 초기화 실패: $e';
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _capturePhoto();
      }
    });
  }

  void _toggleAutoMode() {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });

    if (_isAutoMode && _isInitialized && !_isCapturing) {
      _startCountdown();
    } else {
      _countdownTimer?.cancel();
      setState(() {
        _countdown = 0;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('플래시 토글 실패: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Set flash mode for capture
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.auto);
      }

      // Capture image
      final XFile image = await _controller!.takePicture();

      // Turn off flash after capture
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      }

      // Show success feedback
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: AppSpacing.sm),
              Text('문서가 촬영되었습니다'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 800),
        ),
      );

      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to edit screen
      if (!mounted) return;
      final result = await navigator.pushNamed(
        '/edit',
        arguments: image.path,
      );

      // If saved, return result to gallery
      if (result != null && mounted) {
        navigator.pop(result);
      } else if (mounted && _isAutoMode) {
        // Restart countdown if in auto mode and didn't save
        _startCountdown();
      }
    } catch (e) {
      debugPrint('사진 촬영 실패: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('촬영 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );

      // Restart countdown in auto mode after error
      if (_isAutoMode && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _startCountdown();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _errorMessage != null
            ? _buildErrorView()
            : !_isInitialized
                ? _buildLoadingView()
                : Stack(
                    children: [
                      // Camera preview
                      _buildCameraPreview(),

                      // Rectangle guide overlay
                      _buildGuideOverlay(),

                      // Top controls
                      _buildTopControls(),

                      // Bottom controls
                      _buildBottomControls(),

                      // Capturing overlay
                      if (_isCapturing) _buildCapturingOverlay(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    final navigator = Navigator.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                if (_errorMessage!.contains('권한')) {
                  openAppSettings();
                } else {
                  navigator.pop();
                }
              },
              child: Text(
                _errorMessage!.contains('권한') ? '설정 열기' : '돌아가기',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '카메라 초기화 중...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    // Calculate scale to fill screen
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return Center(
      child: CustomPaint(
        size: Size(
          MediaQuery.of(context).size.width * 0.85,
          MediaQuery.of(context).size.height * 0.6,
        ),
        painter: DocumentGuidePainter(),
      ),
    );
  }

  Widget _buildTopControls() {
    final navigator = Navigator.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => navigator.pop(),
            ),

            // Title
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.document_scanner,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '문서 스캔',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flash toggle
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Auto/Manual mode toggle
                IconButton(
                  icon: Icon(
                    _isAutoMode ? Icons.auto_mode : Icons.touch_app,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleAutoMode,
                  tooltip: _isAutoMode ? 'Auto Mode' : 'Manual Mode',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode and instruction text
            if (_isAutoMode && _countdown > 0)
              Text(
                '$_countdown초 후 자동 촬영',
                style: AppTextStyles.h2.copyWith(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _isAutoMode
                  ? '네모 가이드 안에 문서를 맞춰주세요'
                  : '버튼을 눌러 촬영하세요',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.lg),

            // Manual capture button (only shown in manual mode)
            if (!_isAutoMode)
              GestureDetector(
                onTap: _isCapturing ? null : _capturePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Countdown circle indicator (in auto mode)
            if (_isAutoMode)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _countdown > 0 ? Colors.yellow : Colors.white.withValues(alpha: 0.5),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: _countdown > 0
                      ? Text(
                          '$_countdown',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        )
                      : Icon(
                          Icons.auto_mode,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 32,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

/// Custom painter for document guide rectangle overlay
class DocumentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 모든 가이드를 노란색으로 통일
    const guideColor = Colors.yellow;

    final paint = Paint()
      ..color = guideColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw full rectangle
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // Draw corner markers (larger and more visible)
    const cornerLength = 40.0;
    const cornerThickness = 4.0;

    final cornerPaint = Paint()
      ..color = guideColor
      ..strokeWidth = cornerThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(0, 0).translate(0, size.height),
      Offset(cornerLength, size.height),
      cornerPaint,
    );

    // Draw center crosshair
    final center = Offset(size.width / 2, size.height / 2);
    const crosshairSize = 20.0;
    final crosshairPaint = Paint()
      ..color = guideColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy + crosshairSize),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
