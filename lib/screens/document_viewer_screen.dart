import 'package:flutter/material.dart';
import '../models/scan_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';

/// Document viewer screen showing all pages in a gallery
class DocumentViewerScreen extends StatefulWidget {
  final ScanDocument document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isGridView = true;
  final Set<int> _selectedPages = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.document.name,
        actions: [
          if (_selectedPages.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _selectedPages.clear());
              },
              child: Text('Cancel (${_selectedPages.length})'),
            )
          else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() => _isGridView = !_isGridView);
              },
              tooltip: _isGridView ? 'List View' : 'Grid View',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showOptions,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Document info card
          _buildDocumentInfo(),

          // Pages gallery
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _selectedPages.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _addPages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Pages'),
            )
          : null,
      bottomNavigationBar: _selectedPages.isNotEmpty ? _buildSelectionBar() : null,
    );
  }

  Widget _buildDocumentInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            Icons.description,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.document.imagePaths.length} pages',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Created ${_formatDate(widget.document.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _exportToPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 210 / 297, // A4 ratio
      ),
      itemCount: widget.document.imagePaths.length,
      itemBuilder: (context, index) {
        return _buildPageCard(index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: widget.document.imagePaths.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildPageCard(index, isListView: true),
        );
      },
    );
  }

  Widget _buildPageCard(int index, {bool isListView = false}) {
    final isSelected = _selectedPages.contains(index);

    return GestureDetector(
      onTap: () {
        if (_selectedPages.isEmpty) {
          _viewFullScreen(index);
        } else {
          _toggleSelection(index);
        }
      },
      onLongPress: () => _toggleSelection(index),
      child: Stack(
        children: [
          // Page container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Column(
                children: [
                  // Image placeholder
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: isListView ? 80 : 60,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  // Page number
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selection overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Selection checkbox (always visible in selection mode)
          if (_selectedPages.isNotEmpty)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectionAction(
              icon: Icons.edit,
              label: 'Edit',
              onPressed: _editSelected,
            ),
            _buildSelectionAction(
              icon: Icons.share,
              label: 'Share',
              onPressed: _shareSelected,
            ),
            _buildSelectionAction(
              icon: Icons.rotate_right,
              label: 'Rotate',
              onPressed: _rotateSelected,
            ),
            _buildSelectionAction(
              icon: Icons.delete,
              label: 'Delete',
              onPressed: _deleteSelected,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedPages.contains(index)) {
        _selectedPages.remove(index);
      } else {
        _selectedPages.add(index);
      }
    });
  }

  void _viewFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          document: widget.document,
          initialPage: index,
        ),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select All'),
              onTap: () {
                Navigator.pop(context);
                _selectAll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export to PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Document'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Document Info'),
              onTap: () {
                Navigator.pop(context);
                _showDocumentInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedPages.clear();
      for (int i = 0; i < widget.document.imagePaths.length; i++) {
        _selectedPages.add(i);
      }
    });
  }

  void _editSelected() {
    _showSnackBar('Edit ${_selectedPages.length} pages');
  }

  void _shareSelected() {
    _showSnackBar('Share ${_selectedPages.length} pages');
  }

  void _rotateSelected() {
    _showSnackBar('Rotate ${_selectedPages.length} pages');
    setState(() => _selectedPages.clear());
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pages'),
        content: Text('Delete ${_selectedPages.length} selected pages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('${_selectedPages.length} pages deleted');
              setState(() => _selectedPages.clear());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addPages() {
    _showSnackBar('Opening camera...');
  }

  void _exportToPdf() {
    Navigator.pushNamed(
      context,
      '/export',
      arguments: widget.document,
    );
  }

  void _shareDocument() {
    _showSnackBar('Sharing document...');
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.document.name),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow('Pages', '${widget.document.imagePaths.length}'),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow('Created', _formatDate(widget.document.createdAt)),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              'Status',
              widget.document.isProcessed ? 'Processed' : 'Processing',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Full screen image viewer with zoom
class FullScreenImageViewer extends StatefulWidget {
  final ScanDocument document;
  final int initialPage;

  const FullScreenImageViewer({
    super.key,
    required this.document,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Page viewer with zoom
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: widget.document.imagePaths.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: AspectRatio(
                          aspectRatio: 210 / 297,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 120,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Page ${index + 1}',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Controls overlay
            if (_showControls) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Page ${_currentPage + 1} of ${widget.document.imagePaths.length}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Page indicator
              Positioned(
                bottom: AppSpacing.xl,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        Text(
                          '${_currentPage + 1} / ${widget.document.imagePaths.length}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: _currentPage < widget.document.imagePaths.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
