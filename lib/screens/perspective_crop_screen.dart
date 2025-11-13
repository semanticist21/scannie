import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class PerspectiveCropScreen extends StatefulWidget {
  final String imagePath;

  const PerspectiveCropScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<PerspectiveCropScreen> createState() => _PerspectiveCropScreenState();
}

class _PerspectiveCropScreenState extends State<PerspectiveCropScreen> {
  ui.Image? _image;
  bool _isLoading = true;
  bool _isProcessing = false;
  final ImageService _imageService = ImageService();

  // 4개 포인트 (비율로 저장, 0.0~1.0)
  Offset _topLeft = const Offset(0.1, 0.1);
  Offset _topRight = const Offset(0.9, 0.1);
  Offset _bottomRight = const Offset(0.9, 0.9);
  Offset _bottomLeft = const Offset(0.1, 0.9);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _image = frame.image;
      _isLoading = false;
    });
  }

  Future<void> _applyCrop() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 4개 포인트를 픽셀 좌표로 변환
      final corners = [
        {'x': _topLeft.dx * _image!.width, 'y': _topLeft.dy * _image!.height},
        {'x': _topRight.dx * _image!.width, 'y': _topRight.dy * _image!.height},
        {'x': _bottomRight.dx * _image!.width, 'y': _bottomRight.dy * _image!.height},
        {'x': _bottomLeft.dx * _image!.width, 'y': _bottomLeft.dy * _image!.height},
      ];

      // Perspective transform 적용
      final croppedPath = await _imageService.perspectiveTransformWithPoints(
        widget.imagePath,
        corners,
      );

      if (mounted) {
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자르기 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '영역 조정',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _applyCrop,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '완료',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_image == null) return Container();

                  return Stack(
                    children: [
                      // 이미지
                      Center(
                        child: RawImage(
                          image: _image,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // 4점 오버레이
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CropOverlayPainter(
                            topLeft: _topLeft,
                            topRight: _topRight,
                            bottomRight: _bottomRight,
                            bottomLeft: _bottomLeft,
                            imageSize: Size(
                              _image!.width.toDouble(),
                              _image!.height.toDouble(),
                            ),
                          ),
                        ),
                      ),

                      // 드래그 가능한 4개 포인트
                      ..._buildDraggablePoints(constraints),
                    ],
                  );
                },
              ),
            ),
    );
  }

  List<Widget> _buildDraggablePoints(BoxConstraints constraints) {
    final points = [
      ('topLeft', _topLeft, (offset) => setState(() => _topLeft = offset)),
      ('topRight', _topRight, (offset) => setState(() => _topRight = offset)),
      ('bottomRight', _bottomRight, (offset) => setState(() => _bottomRight = offset)),
      ('bottomLeft', _bottomLeft, (offset) => setState(() => _bottomLeft = offset)),
    ];

    return points.map((point) {
      return _DraggablePoint(
        key: ValueKey(point.$1),
        position: point.$2,
        onDrag: point.$3,
      );
    }).toList();
  }
}

class _DraggablePoint extends StatelessWidget {
  final Offset position;
  final Function(Offset) onDrag;

  const _DraggablePoint({
    super.key,
    required this.position,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx - 20,
      top: MediaQuery.of(context).size.height * position.dy - 20,
      child: GestureDetector(
        onPanUpdate: (details) {
          final screenSize = MediaQuery.of(context).size;
          final newX = (position.dx * screenSize.width + details.delta.dx) / screenSize.width;
          final newY = (position.dy * screenSize.height + details.delta.dy) / screenSize.height;

          // 화면 밖으로 나가지 않도록 제한
          final clampedX = newX.clamp(0.0, 1.0);
          final clampedY = newY.clamp(0.0, 1.0);

          onDrag(Offset(clampedX, clampedY));
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.drag_indicator,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final Size imageSize;

  CropOverlayPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 어두운 배경
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // 4개 포인트 연결 (선)
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * topLeft.dx, size.height * topLeft.dy)
      ..lineTo(size.width * topRight.dx, size.height * topRight.dy)
      ..lineTo(size.width * bottomRight.dx, size.height * bottomRight.dy)
      ..lineTo(size.width * bottomLeft.dx, size.height * bottomLeft.dy)
      ..close();

    canvas.drawPath(path, linePaint);

    // 선택 영역 (반투명)
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) {
    return oldDelegate.topLeft != topLeft ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomRight != bottomRight ||
        oldDelegate.bottomLeft != bottomLeft;
  }
}
