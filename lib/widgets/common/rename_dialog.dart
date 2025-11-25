import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_toast.dart';
import '../../utils/app_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Common rename dialog widget
class RenameDialog {
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

  /// Show the rename dialog
  static void show({
    required BuildContext context,
    required String currentName,
    required Future<void> Function(String newName) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    AppModal.showDialog(
      context: context,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          backgroundColor: AppColors.surface,
          hasSabGradient: false,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          child: _RenameContent(
            controller: controller,
            modalContext: modalContext,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}

class _RenameContent extends StatefulWidget {
  final TextEditingController controller;
  final BuildContext modalContext;
  final Future<void> Function(String newName) onSave;

  const _RenameContent({
    required this.controller,
    required this.modalContext,
    required this.onSave,
  });

  @override
  State<_RenameContent> createState() => _RenameContentState();
}

class _RenameContentState extends State<_RenameContent> {
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
          Text('dialogs.renameScan'.tr(), style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'dialogs.renameScanDesc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ShadInput(
            controller: widget.controller,
            placeholder: Text('gallery.documentNamePlaceholder'.tr()),
            autofocus: true,
            maxLength: RenameDialog.maxLength,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length} / ${RenameDialog.maxLength}',
              style: AppTextStyles.caption.copyWith(
                color: widget.controller.text.length > RenameDialog.maxLength
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
                child: Text('common.cancel'.tr()),
                onPressed: () => Navigator.of(widget.modalContext).pop(),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadButton(
                child: Text('common.save'.tr()),
                onPressed: () async {
                  final newName = widget.controller.text.trim();
                  final error = RenameDialog._validateName(newName, context);
                  if (error != null) {
                    AppToast.show(context, error, isError: true);
                    return;
                  }

                  await widget.onSave(newName);
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
