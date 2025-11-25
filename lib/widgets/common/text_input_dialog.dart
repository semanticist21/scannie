import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_toast.dart';
import '../../utils/app_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Common text input dialog widget
class TextInputDialog {
  /// Maximum allowed filename length (common limit for iOS/Android)
  static const int maxLength = 100;

  /// Characters not allowed in filenames
  static const String forbiddenChars = r'/\:*?"<>|';

  /// Validate filename and return error message if invalid
  static String? _validateName(String name, BuildContext context) {
    if (name.isEmpty) {
      return 'validation.nameEmpty'.tr();
    }

    if (name.length > maxLength) {
      return 'validation.nameTooLong'.tr(namedArgs: {'max': maxLength.toString()});
    }

    for (int i = 0; i < forbiddenChars.length; i++) {
      if (name.contains(forbiddenChars[i])) {
        return 'validation.nameForbiddenChars'.tr(namedArgs: {'chars': forbiddenChars});
      }
    }

    // Check for names that are just dots
    if (name == '.' || name == '..') {
      return 'validation.nameInvalid'.tr();
    }

    return null; // Valid
  }

  /// Show a text input dialog
  static void show({
    required BuildContext context,
    required String title,
    required String description,
    required String initialValue,
    String placeholder = 'Enter text',
    String cancelText = 'Cancel',
    String confirmText = 'Save',
    required Future<void> Function(String value) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    AppModal.showDialog(
      context: context,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          backgroundColor: AppColors.surface,
          hasSabGradient: false,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          child: _TextInputContent(
            controller: controller,
            title: title,
            description: description,
            placeholder: placeholder,
            cancelText: cancelText,
            confirmText: confirmText,
            modalContext: modalContext,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}

class _TextInputContent extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String description;
  final String placeholder;
  final String cancelText;
  final String confirmText;
  final BuildContext modalContext;
  final Future<void> Function(String value) onSave;

  const _TextInputContent({
    required this.controller,
    required this.title,
    required this.description,
    required this.placeholder,
    required this.cancelText,
    required this.confirmText,
    required this.modalContext,
    required this.onSave,
  });

  @override
  State<_TextInputContent> createState() => _TextInputContentState();
}

class _TextInputContentState extends State<_TextInputContent> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ShadInput(
            controller: widget.controller,
            placeholder: Text(widget.placeholder),
            autofocus: true,
            maxLength: TextInputDialog.maxLength,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length} / ${TextInputDialog.maxLength}',
              style: AppTextStyles.caption.copyWith(
                color: widget.controller.text.length > TextInputDialog.maxLength
                    ? AppColors.error
                    : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                child: Text(widget.cancelText),
                onPressed: () => Navigator.of(widget.modalContext).pop(),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadButton(
                child: Text(widget.confirmText),
                onPressed: () async {
                  final value = widget.controller.text.trim();
                  final error = TextInputDialog._validateName(value, context);
                  if (error != null) {
                    AppToast.show(context, error, isError: true);
                    return;
                  }

                  await widget.onSave(value);
                  if (widget.modalContext.mounted) {
                    final route = ModalRoute.of(widget.modalContext);
                    if (route != null && route.isCurrent) {
                      Navigator.of(widget.modalContext).pop();
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
