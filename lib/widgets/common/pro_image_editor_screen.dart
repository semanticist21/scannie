import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Pro Image Editor wrapper screen
/// For editing images with full capabilities (crop, rotate, filters, etc.)
class ProImageEditorScreen extends StatelessWidget {
  final String imagePath;
  final bool saveToTemp; // true = save to temp (EditScreen), false = overwrite original (DocumentViewer)

  const ProImageEditorScreen({
    super.key,
    required this.imagePath,
    this.saveToTemp = true, // Default to temp for EditScreen
  });

  @override
  Widget build(BuildContext context) {
    return ProImageEditor.file(
      File(imagePath),
      configs: ProImageEditorConfigs(
        cropRotateEditor: CropRotateEditorConfigs(
          tiltConfigs: TiltConfigs(
            showTiltButton: true,
            showTiltRotate: true,
            showTiltVertical: true,
            showTiltHorizontal: true,
            tiltRotateMin: -45.0,
            tiltRotateMax: 45.0,
            tiltVerticalMin: -30.0,
            tiltVerticalMax: 30.0,
            tiltHorizontalMin: -30.0,
            tiltHorizontalMax: 30.0,
          ),
        ),
      ),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          String resultPath;

          if (saveToTemp) {
            // EditScreen: Save to temp file (user hasn't saved yet)
            final tempDir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final extension = path.extension(imagePath);
            final tempFilePath =
                path.join(tempDir.path, 'edited_$timestamp$extension');
            await File(tempFilePath).writeAsBytes(bytes);
            resultPath = tempFilePath;
            debugPrint('✅ Image edited and saved to temp: $tempFilePath');
          } else {
            // DocumentViewer: Overwrite original file directly
            final originalFile = File(imagePath);
            await originalFile.writeAsBytes(bytes);
            resultPath = imagePath;
            debugPrint('✅ Image edited and overwritten: $imagePath');
          }

          // Return result path to caller
          if (context.mounted) {
            Navigator.pop(context, resultPath);
          }
        },
        onCloseEditor: (EditorMode editorMode) {
          // User cancelled - return null
          Navigator.pop(context);
        },
      ),
    );
  }
}
