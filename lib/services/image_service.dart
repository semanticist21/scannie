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

  /// 4점 기반 Perspective 변환 (사용자 지정 포인트)
  Future<String> perspectiveTransformWithPoints(
    String imagePath,
    List<Map<String, double>> corners,
  ) async {
    // corners: [topLeft, topRight, bottomRight, bottomLeft]
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // 4개 포인트로부터 문서의 폭과 높이 계산
    final tl = corners[0];
    final tr = corners[1];
    final br = corners[2];
    final bl = corners[3];

    // 상단 폭과 하단 폭 중 최대값
    final topWidth = ((tr['x']! - tl['x']!).abs()).toInt();
    final bottomWidth = ((br['x']! - bl['x']!).abs()).toInt();
    final maxWidth = topWidth > bottomWidth ? topWidth : bottomWidth;

    // 좌측 높이와 우측 높이 중 최대값
    final leftHeight = ((bl['y']! - tl['y']!).abs()).toInt();
    final rightHeight = ((br['y']! - tr['y']!).abs()).toInt();
    final maxHeight = leftHeight > rightHeight ? leftHeight : rightHeight;

    // 최소 크기 보장
    final targetWidth = maxWidth > 100 ? maxWidth : 100;
    final targetHeight = maxHeight > 100 ? maxHeight : 100;

    // 간단한 crop (실제 perspective transform은 복잡한 행렬 계산 필요)
    // 여기서는 bounding box로 crop 후 resize
    final minX = [tl['x']!, tr['x']!, br['x']!, bl['x']!].reduce((a, b) => a < b ? a : b).toInt().clamp(0, image.width - 1);
    final maxX = [tl['x']!, tr['x']!, br['x']!, bl['x']!].reduce((a, b) => a > b ? a : b).toInt().clamp(0, image.width);
    final minY = [tl['y']!, tr['y']!, br['y']!, bl['y']!].reduce((a, b) => a < b ? a : b).toInt().clamp(0, image.height - 1);
    final maxY = [tl['y']!, tr['y']!, br['y']!, bl['y']!].reduce((a, b) => a > b ? a : b).toInt().clamp(0, image.height);

    final cropWidth = (maxX - minX).clamp(1, image.width);
    final cropHeight = (maxY - minY).clamp(1, image.height);

    // Crop
    final cropped = img.copyCrop(image,
      x: minX,
      y: minY,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to target dimensions
    final transformed = img.copyResize(cropped,
      width: targetWidth,
      height: targetHeight,
    );

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'perspective_${DateTime.now().millisecondsSinceEpoch}.png';
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

  /// 이미지 업스케일링 (2배 확대 + 선명도 향상)
  /// Pro 기능
  Future<String> upscaleImage(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // 2배 크기로 확대
    final upscaled = img.copyResize(
      image,
      width: image.width * 2,
      height: image.height * 2,
      interpolation: img.Interpolation.cubic, // 고품질 보간
    );

    // 선명도 향상
    final sharpened = img.convolution(upscaled, [
      -1, -1, -1,
      -1, 9, -1,
      -1, -1, -1,
    ]);

    // 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'upscaled_${DateTime.now().millisecondsSinceEpoch}.png';
    final upscaledPath = '${directory.path}/$fileName';

    final upscaledFile = File(upscaledPath);
    await upscaledFile.writeAsBytes(img.encodePng(sharpened));

    return upscaledPath;
  }
}
