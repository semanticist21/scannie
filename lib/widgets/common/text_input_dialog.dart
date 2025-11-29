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
  /// Maximum allowed filename length in bytes (UTF-8)
  /// iOS/Android both support 255 bytes, using 200 for safety with extensions
  static const int maxLength = 200;

  /// Characters not allowed in filenames (iOS + Android/FAT32)
  static const String forbiddenChars = r'/\:*?"<>|';

  /// Windows/FAT32 reserved names (also problematic on Android external storage)
  static const List<String> reservedNames = [
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
  ];

  /// Validate filename and return error message if invalid
  static String? _validateName(String name, BuildContext context) {
    // 1. Empty check
    if (name.isEmpty) {
      return 'validation.nameEmpty'.tr();
    }

    // 2. UTF-8 byte length check (filesystem limit is 255 bytes)
    final byteLength = name.codeUnits.length;
    if (byteLength > maxLength) {
      return 'validation.nameTooLong'.tr(namedArgs: {'max': maxLength.toString()});
    }

    // 3. Forbidden characters check (iOS: /: Android/FAT32: /\:*?"<>|)
    for (int i = 0; i < forbiddenChars.length; i++) {
      if (name.contains(forbiddenChars[i])) {
        return 'validation.nameForbiddenChars'.tr(namedArgs: {'chars': forbiddenChars});
      }
    }

    // 4. Control characters check (ASCII 0-31)
    for (int i = 0; i < name.length; i++) {
      final code = name.codeUnitAt(i);
      if (code < 32) {
        return 'validation.nameControlChars'.tr();
      }
    }

    // 5. Names that are just dots (. or ..)
    if (name == '.' || name == '..') {
      return 'validation.nameInvalid'.tr();
    }

    // 6. Leading/trailing dots (problematic on FAT32)
    if (name.startsWith('.') || name.endsWith('.')) {
      return 'validation.nameLeadingTrailingDot'.tr();
    }

    // 7. Reserved names check (Windows/FAT32 - case insensitive)
    final upperName = name.toUpperCase();
    // Check exact match or match with extension (e.g., CON.txt)
    final baseName = upperName.contains('.')
        ? upperName.substring(0, upperName.indexOf('.'))
        : upperName;
    if (reservedNames.contains(baseName)) {
      return 'validation.nameReserved'.tr();
    }

    return null; // Valid
  }

  /// Show a text input dialog
  static void show({
    required BuildContext context,
    required String title,
    required String description,
    required String initialValue,
    String? placeholder,
    String? cancelText,
    String? confirmText,
    required Future<void> Function(String value) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    final actualPlaceholder = placeholder ?? 'gallery.documentNamePlaceholder'.tr();
    final actualCancelText = cancelText ?? 'common.cancel'.tr();
    final actualConfirmText = confirmText ?? 'common.save'.tr();

    AppModal.showDialog(
      context: context,
      pageListBuilder: (modalContext) {
        final colors = ThemedColors.of(modalContext);
        return [
        WoltModalSheetPage(
          backgroundColor: colors.surface,
          hasSabGradient: false,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          child: _TextInputContent(
            controller: controller,
            title: title,
            description: description,
            placeholder: actualPlaceholder,
            cancelText: actualCancelText,
            confirmText: actualConfirmText,
            modalContext: modalContext,
            onSave: onSave,
          ),
        ),
      ];
      },
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
    final colors = ThemedColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTextStyles.h3.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
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
                    ? colors.error
                    : colors.textHint,
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
