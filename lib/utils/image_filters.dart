import 'dart:io';
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
  /// CamScanner-style: Adaptive thresholding + shadow removal for clean document scan
  static img.Image applyBlackAndWhite(img.Image image) {
    // 1. Convert to grayscale
    var processed = img.grayscale(image);

    // 2. Remove shadows using illumination correction
    processed = _removeIllumination(processed);

    // 3. Normalize histogram (stretch to full 0-255 range)
    processed = img.normalize(processed, min: 0, max: 255);

    // 4. Apply adaptive threshold for better shadow handling
    processed = _applyAdaptiveThreshold(processed, blockSize: 25, c: 10);

    // 5. Final contrast boost for crisp text
    processed = img.contrast(processed, contrast: 1.2);

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

  /// Remove illumination (shadows) using Gaussian blur estimation
  /// CamScanner-style shadow removal: estimate background illumination and subtract
  static img.Image _removeIllumination(img.Image image) {
    // 1. Create illumination map using large Gaussian blur
    // This estimates the uneven lighting/shadows
    final illumination = img.gaussianBlur(image, radius: 20);

    // 2. Subtract illumination from original to get reflectance
    final result = image.clone();

    for (final pixel in result) {
      final illumPixel = illumination.getPixel(pixel.x, pixel.y);

      // For each channel, calculate: original + (128 - illumination)
      // This normalizes lighting while preserving detail
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final illumR = illumPixel.r.toInt();
      final illumG = illumPixel.g.toInt();
      final illumB = illumPixel.b.toInt();

      // Add offset to prevent negative values
      final newR = (r + 128 - illumR).clamp(0, 255).toInt();
      final newG = (g + 128 - illumG).clamp(0, 255).toInt();
      final newB = (b + 128 - illumB).clamp(0, 255).toInt();

      pixel
        ..r = newR
        ..g = newG
        ..b = newB;
    }

    return result;
  }

  /// Adaptive threshold binarization
  /// CamScanner-style: uses local neighborhood to determine threshold
  /// [blockSize] size of local neighborhood (must be odd), larger = smoother
  /// [c] constant subtracted from mean (higher = more aggressive)
  static img.Image _applyAdaptiveThreshold(
    img.Image image, {
    int blockSize = 25,
    int c = 10,
  }) {
    // Ensure blockSize is odd
    if (blockSize % 2 == 0) blockSize++;

    final result = image.clone();
    final halfBlock = blockSize ~/ 2;

    // For each pixel, calculate local mean and apply threshold
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate local mean in neighborhood
        int sum = 0;
        int count = 0;

        for (int dy = -halfBlock; dy <= halfBlock; dy++) {
          for (int dx = -halfBlock; dx <= halfBlock; dx++) {
            final nx = (x + dx).clamp(0, image.width - 1);
            final ny = (y + dy).clamp(0, image.height - 1);

            final neighbor = image.getPixel(nx, ny);
            sum += neighbor.r.toInt(); // Grayscale, so r=g=b
            count++;
          }
        }

        final localMean = sum / count;
        final pixel = result.getPixel(x, y);
        final pixelValue = pixel.r.toInt();

        // Threshold: pixel > (localMean - c) ? white : black
        final threshold = (localMean - c).clamp(0, 255).toInt();
        final newValue = pixelValue > threshold ? 255 : 0;

        pixel
          ..r = newValue
          ..g = newValue
          ..b = newValue;
      }
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
