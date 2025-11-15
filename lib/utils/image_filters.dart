import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
// import 'package:opencv_dart/opencv_dart.dart' as cv;  // iOS arm64 문제로 임시 비활성화

/// Image filter utility functions for document scanning
class ImageFilters {
  /// Apply original filter (no changes)
  static img.Image applyOriginal(img.Image image) {
    return img.copyResize(image, width: image.width, height: image.height);
  }

  /// Apply grayscale filter
  static img.Image applyGrayscale(img.Image image) {
    return img.grayscale(image);
  }

  /// Apply black and white (binarization) filter
  /// Uses image package's built-in luminanceThreshold for reliable results
  static img.Image applyBlackAndWhite(img.Image image) {
    // 1. Convert to grayscale
    var processed = img.grayscale(image);

    // 2. Normalize histogram for better contrast
    processed = img.normalize(processed, min: 0, max: 255);

    // 3. Apply luminance threshold (built-in function)
    // threshold: 0.5 = 50% brightness cutoff
    // outputColor: false = binary (0 or 255), not inverted
    processed = img.luminanceThreshold(
      processed,
      threshold: 0.5,
      outputColor: false,
      amount: 1.0,
    );

    return processed;
  }

  /// Apply Sepia filter for warm vintage tone
  /// Fast implementation using pre-calculated ColorMatrix
  static img.Image applySepia(img.Image image) {
    final result = image.clone();

    // Sepia tone matrix (standard sepia transformation)
    // Output R = 0.393*R + 0.769*G + 0.189*B
    // Output G = 0.349*R + 0.686*G + 0.168*B
    // Output B = 0.272*R + 0.534*G + 0.131*B
    for (final pixel in result) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final newR = ((0.393 * r) + (0.769 * g) + (0.189 * b)).clamp(0, 255).toInt();
      final newG = ((0.349 * r) + (0.686 * g) + (0.168 * b)).clamp(0, 255).toInt();
      final newB = ((0.272 * r) + (0.534 * g) + (0.131 * b)).clamp(0, 255).toInt();

      pixel
        ..r = newR
        ..g = newG
        ..b = newB;
    }

    return result;
  }

  /// Apply Vintage filter (Sepia + Vignette + Slight blur)
  /// CamScanner-style aged document effect
  static img.Image applyVintage(img.Image image) {
    // 1. Apply sepia tone
    var processed = applySepia(image);

    // 2. Reduce saturation slightly for faded look
    processed = img.adjustColor(processed, saturation: 0.85);

    // 3. Add vignette effect (darken edges)
    processed = _applyVignette(processed, intensity: 0.4);

    // 4. Slight warmth boost
    processed = img.adjustColor(processed, brightness: 1.05);

    return processed;
  }

  /// Apply magic color filter (auto color enhancement)
  /// Enhances colors and contrast for better document readability
  static img.Image applyMagicColor(img.Image image) {
    return img.adjustColor(
      image,
      contrast: 1.3,
      saturation: 1.2,
      brightness: 1.05,
    );
  }

  /// Apply lighten filter
  /// Brightens the image for better visibility
  static img.Image applyLighten(img.Image image) {
    return img.adjustColor(
      image,
      brightness: 1.3,
      exposure: 0.2,
    );
  }

  /// Apply custom brightness adjustment
  /// [value] ranges from -100 to 100
  static img.Image applyBrightness(img.Image image, double value) {
    // Convert slider value (-100 to 100) to brightness multiplier
    // -100 = 0.0 (black), 0 = 1.0 (normal), 100 = 2.0 (very bright)
    final brightness = 1.0 + (value / 100.0);
    return img.adjustColor(image, brightness: brightness);
  }

  /// Apply custom contrast adjustment
  /// [value] ranges from -100 to 100
  static img.Image applyContrast(img.Image image, double value) {
    // Convert slider value (-100 to 100) to contrast multiplier
    // -100 = 0.0 (gray), 0 = 1.0 (normal), 100 = 2.0 (high contrast)
    final contrast = 1.0 + (value / 100.0);
    return img.adjustColor(image, contrast: contrast);
  }

  /// Apply combined brightness and contrast adjustments
  static img.Image applyBrightnessAndContrast(
    img.Image image,
    double brightnessValue,
    double contrastValue,
  ) {
    final brightness = 1.0 + (brightnessValue / 100.0);
    final contrast = 1.0 + (contrastValue / 100.0);

    return img.adjustColor(
      image,
      brightness: brightness,
      contrast: contrast,
    );
  }

  /// Rotate image 90 degrees clockwise
  static img.Image rotate90(img.Image image) {
    return img.copyRotate(image, angle: 90);
  }

  /// Rotate image 180 degrees
  static img.Image rotate180(img.Image image) {
    return img.copyRotate(image, angle: 180);
  }

  /// Rotate image 270 degrees clockwise (90 counter-clockwise)
  static img.Image rotate270(img.Image image) {
    return img.copyRotate(image, angle: 270);
  }

  /// Load image from file path
  static Future<img.Image?> loadImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      // Error loading image
      return null;
    }
  }

  /// Load image from memory (Uint8List)
  static img.Image? loadImageFromMemory(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      // Error decoding image
      return null;
    }
  }

  /// Save image to file
  static Future<bool> saveImage(img.Image image, String path) async {
    try {
      final bytes = img.encodeJpg(image, quality: 95);
      final file = File(path);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      // Error saving image
      return false;
    }
  }

  /// Encode image to Uint8List for display
  static Uint8List encodeImage(img.Image image) {
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  /// Resize image while maintaining aspect ratio
  /// [maxWidth] maximum width, [maxHeight] maximum height
  static img.Image resizeImage(
    img.Image image, {
    int? maxWidth,
    int? maxHeight,
  }) {
    if (maxWidth == null && maxHeight == null) {
      return image;
    }

    if (maxWidth != null && maxHeight == null) {
      return img.copyResize(image, width: maxWidth);
    }

    if (maxHeight != null && maxWidth == null) {
      return img.copyResize(image, height: maxHeight);
    }

    // Both maxWidth and maxHeight specified
    final aspectRatio = image.width / image.height;
    final targetAspectRatio = maxWidth! / maxHeight!;

    if (aspectRatio > targetAspectRatio) {
      // Width is the limiting factor
      return img.copyResize(image, width: maxWidth);
    } else {
      // Height is the limiting factor
      return img.copyResize(image, height: maxHeight);
    }
  }


  /// Apply vignette effect (darken edges for vintage look)
  /// [intensity] 0.0 (no effect) to 1.0 (maximum darkening)
  static img.Image _applyVignette(img.Image image, {double intensity = 0.3}) {
    final result = image.clone();
    final centerX = image.width / 2.0;
    final centerY = image.height / 2.0;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (final pixel in result) {
      // Calculate distance from center (normalized 0-1)
      final dx = pixel.x - centerX;
      final dy = pixel.y - centerY;
      final distance = math.sqrt(dx * dx + dy * dy) / maxDistance;

      // Apply vignette: closer to edge = darker
      final vignette = 1.0 - (distance * intensity);
      final factor = vignette.clamp(0.0, 1.0);

      pixel
        ..r = (pixel.r.toInt() * factor).clamp(0, 255).toInt()
        ..g = (pixel.g.toInt() * factor).clamp(0, 255).toInt()
        ..b = (pixel.b.toInt() * factor).clamp(0, 255).toInt();
    }

    return result;
  }



  /// Remove shadows from document images using OpenCV
  /// This is a computationally intensive operation
  /// NOTE: iOS에서는 opencv_dart arm64 문제로 Fast 버전 사용
  static Future<img.Image> removeShadows(img.Image image) async {
    // iOS arm64 문제로 인해 임시로 Fast 버전 사용
    return removeShadowsFast(image);

    /* OpenCV 버전 (Android에서만 사용 가능)
    try {
      // 1. Convert img.Image to OpenCV Mat
      final bytes = img.encodeJpg(image);
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      // 2. Convert to LAB color space for better shadow processing
      final lab = cv.cvtColor(mat, cv.COLOR_BGR2Lab);

      // 3. Split LAB channels (L = Lightness, A, B = color)
      final channels = cv.split(lab);
      final l = channels[0]; // Lightness channel

      // 4. Apply morphological closing to estimate background
      // This creates a map of the illumination
      final kernel = cv.getStructuringElement(
        cv.MORPH_ELLIPSE,
        (15, 15),
      );
      final bg = cv.morphologyEx(l, cv.MORPH_CLOSE, kernel);

      // 5. Subtract background from original to remove shadows
      final diff = cv.subtract(bg, l);

      // 6. Normalize the result (stretch histogram to 0-255)
      final normalized = cv.Mat.empty();
      cv.normalize(
        diff,
        normalized,
        alpha: 0,
        beta: 255,
        normType: cv.NORM_MINMAX,
      );

      // 7. Merge back with original color channels
      channels[0] = normalized;
      final mergedLab = cv.merge(channels);

      // 8. Convert back to BGR
      final result = cv.cvtColor(mergedLab, cv.COLOR_Lab2BGR);

      // 9. Convert Mat back to img.Image
      final resultBytes = cv.imencode('.jpg', result).$2;
      final decodedImage = img.decodeImage(resultBytes);

      // Clean up OpenCV matrices
      mat.dispose();
      lab.dispose();
      for (int i = 0; i < channels.length; i++) {
        channels[i].dispose();
      }
      kernel.dispose();
      bg.dispose();
      diff.dispose();
      normalized.dispose();
      mergedLab.dispose();
      result.dispose();

      return decodedImage ?? image;
    } catch (e) {
      // If OpenCV processing fails, return original image
      return image;
    }
    */
  }

  /// Fast shadow removal using simple illumination correction
  /// Less effective than OpenCV but much faster
  static img.Image removeShadowsFast(img.Image image) {
    final processed = image.clone();

    // Calculate average brightness
    int totalBrightness = 0;
    int pixelCount = 0;

    for (final pixel in processed) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();
      totalBrightness += luminance;
      pixelCount++;
    }

    final avgBrightness = totalBrightness / pixelCount;
    const targetBrightness = 180; // Target average brightness

    // Brighten dark areas more than bright areas
    for (final pixel in processed) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b);

      // Calculate boost factor (more boost for darker pixels)
      final boost = luminance < avgBrightness
          ? 1.0 + ((avgBrightness - luminance) / avgBrightness) * 0.6
          : 1.0 + ((targetBrightness - luminance) / 255.0) * 0.3;

      pixel
        ..r = (r * boost).clamp(0, 255).toInt()
        ..g = (g * boost).clamp(0, 255).toInt()
        ..b = (b * boost).clamp(0, 255).toInt();
    }

    return processed;
  }

  /// Auto crop document edges (placeholder for future implementation)
  /// This would use edge detection algorithms
  static img.Image autoCrop(img.Image image) {
    // TODO: Implement edge detection and auto cropping
    // For now, return the original image
    return image;
  }
}
