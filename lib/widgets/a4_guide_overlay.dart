import 'package:flutter/material.dart';

class A4GuideOverlay extends StatelessWidget {
  final bool isAligned;

  const A4GuideOverlay({
    super.key,
    this.isAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: A4GuidePainter(isAligned: isAligned),
      child: Container(),
    );
  }
}

class A4GuidePainter extends CustomPainter {
  final bool isAligned;

  A4GuidePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    // A4 비율 (1:1.414)
    final guideWidth = size.width * 0.8;
    final guideHeight = guideWidth * 1.414;

    final left = (size.width - guideWidth) / 2;
    final top = (size.height - guideHeight) / 2;

    // 반투명 배경 (가이드 외부)
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // 전체 화면
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      darkPaint,
    );

    // 가이드 영역 (투명하게)
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear;

    canvas.drawRect(
      Rect.fromLTWH(left, top, guideWidth, guideHeight),
      clearPaint,
    );

    // 가이드 테두리
    final borderPaint = Paint()
      ..color = isAligned ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(left, top, guideWidth, guideHeight),
      borderPaint,
    );

    // 모서리 강조
    const cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = isAligned ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // 좌상단
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // 우상단
    canvas.drawLine(Offset(left + guideWidth, top),
                    Offset(left + guideWidth - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + guideWidth, top),
                    Offset(left + guideWidth, top + cornerLength), cornerPaint);

    // 좌하단
    canvas.drawLine(Offset(left, top + guideHeight),
                    Offset(left + cornerLength, top + guideHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + guideHeight),
                    Offset(left, top + guideHeight - cornerLength), cornerPaint);

    // 우하단
    canvas.drawLine(Offset(left + guideWidth, top + guideHeight),
                    Offset(left + guideWidth - cornerLength, top + guideHeight), cornerPaint);
    canvas.drawLine(Offset(left + guideWidth, top + guideHeight),
                    Offset(left + guideWidth, top + guideHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(A4GuidePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
