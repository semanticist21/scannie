import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/scan_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Search delegate for documents
class DocumentSearchDelegate extends SearchDelegate<ScanDocument?> {
  final List<ScanDocument> documents;

  DocumentSearchDelegate(this.documents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = documents.where((doc) {
      return doc.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results found',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final document = results[index];
        return ListTile(
          leading: const Icon(LucideIcons.fileText),
          title: Text(document.name),
          subtitle: Text('${document.imagePaths.length} pages'),
          onTap: () => close(context, document),
        );
      },
    );
  }
}
