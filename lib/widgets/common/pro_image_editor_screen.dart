import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Pro Image Editor wrapper screen
/// For editing images with full capabilities (crop, rotate, filters, etc.)
class ProImageEditorScreen extends StatefulWidget {
  final String imagePath;
  final bool saveToTemp; // true = save to temp (EditScreen), false = overwrite original (DocumentViewer)

  const ProImageEditorScreen({
    super.key,
    required this.imagePath,
    this.saveToTemp = true, // Default to temp for EditScreen
  });

  @override
  State<ProImageEditorScreen> createState() => _ProImageEditorScreenState();
}

class _ProImageEditorScreenState extends State<ProImageEditorScreen> {
  bool _hasPopped = false; // Track if we've already popped

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from popping during editing
        debugPrint('🚫 ProImageEditor: Back button pressed, ignoring');
        return false;
      },
      child: ProImageEditor.file(
        File(widget.imagePath),
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
            if (_hasPopped) {
              debugPrint('⚠️ Already popped, ignoring onImageEditingComplete');
              return;
            }
            _hasPopped = true;

            String resultPath;

            if (widget.saveToTemp) {
              // EditScreen: Save to temp file (user hasn't saved yet)
              final tempDir = await getTemporaryDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final extension = path.extension(widget.imagePath);
              final tempFilePath =
                  path.join(tempDir.path, 'edited_$timestamp$extension');
              await File(tempFilePath).writeAsBytes(bytes);
              resultPath = tempFilePath;
              debugPrint('✅ Image edited and saved to temp: $tempFilePath');
            } else {
              // DocumentViewer: Overwrite original file directly
              final originalFile = File(widget.imagePath);
              await originalFile.writeAsBytes(bytes);
              resultPath = widget.imagePath;
              debugPrint('✅ Image edited and overwritten: $widget.imagePath');
            }

            // Return result path to caller
            debugPrint('📤 Returning to previous screen with result');
            if (mounted) {
              Navigator.of(context).pop(resultPath);
            }
          },
          onCloseEditor: (EditorMode editorMode) {
            if (_hasPopped) {
              debugPrint('⚠️ Already popped, ignoring onCloseEditor');
              return;
            }
            _hasPopped = true;

            // User cancelled - return null
            debugPrint('❌ Editing cancelled, returning to previous screen');
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
