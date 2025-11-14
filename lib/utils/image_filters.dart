import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

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
  /// Uses grayscale + high contrast for document scanning
  static img.Image applyBlackAndWhite(img.Image image) {
    // First convert to grayscale
    var processed = img.grayscale(image);

    // Apply high contrast to create black and white effect
    processed = img.adjustColor(
      processed,
      contrast: 1.8,
      brightness: 1.1,
    );

    // Apply threshold binarization
    processed = _applyThreshold(processed, threshold: 128);

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

  /// Apply threshold binarization
  /// Converts pixels to pure black or white based on threshold
  /// [threshold] value from 0-255, default 128
  static img.Image _applyThreshold(img.Image image, {int threshold = 128}) {
    final processed = image.clone();

    for (final pixel in processed) {
      // Get luminance (grayscale value)
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();

      // Apply threshold
      final newValue = luminance > threshold ? 255 : 0;

      pixel
        ..r = newValue
        ..g = newValue
        ..b = newValue;
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
