import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/export_service.dart';
import '../../utils/app_toast.dart';

/// Full screen image viewer (read-only, no editing)
/// Used in DocumentViewerScreen for viewing scanned pages
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialPage;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    required this.initialPage,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Share current image
  Future<void> _shareImage() async {
    try {
      final imagePath = widget.imagePaths[_currentPage];
      final imageFile = File(imagePath);

      // Check if file exists before sharing
      if (!imageFile.existsSync()) {
        if (mounted) {
          AppToast.show(context, 'toast.imageNotFound'.tr(), isError: true);
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        AppToast.show(
          context,
          'toast.failedToShareImage'.tr(namedArgs: {'error': e.toString()}),
          isError: true,
        );
      }
    }
  }

  /// Download current image to gallery
  Future<void> _downloadImage() async {
    final imagePath = widget.imagePaths[_currentPage];
    final result = await ExportService.instance.saveImagesToGallery([imagePath]);

    if (!mounted) return;

    // Show appropriate feedback based on result
    if (result.isSuccess) {
      AppToast.show(context, 'toast.imageSavedToPhotos'.tr());
    } else {
      AppToast.showExportResult(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          children: [
            // Image PageView with zoom
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                bottom: widget.imagePaths.length > 1
                    ? MediaQuery.of(context).padding.bottom + 56
                    : MediaQuery.of(context).padding.bottom,
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imagePaths.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(widget.imagePaths[index]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top bar with close button
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Share button
                      IconButton(
                        icon: Icon(LucideIcons.share2, color: Colors.white),
                        onPressed: _shareImage,
                        tooltip: 'common.share'.tr(),
                      ),
                      // Download button
                      IconButton(
                        icon: Icon(LucideIcons.download, color: Colors.white),
                        onPressed: _downloadImage,
                        tooltip: 'common.download'.tr(),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom bar with page indicator
            if (_showControls && widget.imagePaths.length > 1)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
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
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  child: Center(
                    child: Text(
                      '${_currentPage + 1} / ${widget.imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
