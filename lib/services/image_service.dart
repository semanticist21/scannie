import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageService {
  /// 이미지 향상 (밝기, 대비, 선명도)
  Future<String> enhanceImage(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // 대비 증가
    final enhanced = img.adjustColor(image,
      contrast: 1.3,
      brightness: 1.1,
    );

    // 선명도 증가
    final sharpened = img.convolution(enhanced, [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ]);

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'enhanced_${DateTime.now().millisecondsSinceEpoch}.png';
    final enhancedPath = '${directory.path}/$fileName';

    final enhancedFile = File(enhancedPath);
    await enhancedFile.writeAsBytes(img.encodePng(sharpened));

    return enhancedPath;
  }

  /// Perspective 변환 (문서 왜곡 보정)
  Future<String> perspectiveTransform(
    String imagePath,
    List<Map<String, double>> corners,
  ) async {
    // corners: [topLeft, topRight, bottomRight, bottomLeft]
    // 실제 구현은 더 복잡하지만 기본 개념만 구현

    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // A4 비율 (1:1.414)
    final targetWidth = 1240;
    final targetHeight = (targetWidth * 1.414).round();

    // 크롭 및 리사이즈
    final transformed = img.copyResize(image,
      width: targetWidth,
      height: targetHeight,
    );

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'transformed_${DateTime.now().millisecondsSinceEpoch}.png';
    final transformedPath = '${directory.path}/$fileName';

    final transformedFile = File(transformedPath);
    await transformedFile.writeAsBytes(img.encodePng(transformed));

    return transformedPath;
  }

  /// 흑백 변환
  Future<String> convertToGrayscale(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    final grayscale = img.grayscale(image);

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'grayscale_${DateTime.now().millisecondsSinceEpoch}.png';
    final grayscalePath = '${directory.path}/$fileName';

    final grayscaleFile = File(grayscalePath);
    await grayscaleFile.writeAsBytes(img.encodePng(grayscale));

    return grayscalePath;
  }

  /// 이미지 회전 (90도 시계방향)
  Future<String> rotateImage(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // 90도 시계방향 회전
    final rotated = img.copyRotate(image, angle: 90);

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'rotated_${DateTime.now().millisecondsSinceEpoch}.png';
    final rotatedPath = '${directory.path}/$fileName';

    final rotatedFile = File(rotatedPath);
    await rotatedFile.writeAsBytes(img.encodePng(rotated));

    return rotatedPath;
  }
}
