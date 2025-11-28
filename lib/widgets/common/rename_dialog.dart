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
      pageListBuilder: (modalContext) {
        final colors = ThemedColors.of(modalContext);
        return [
        WoltModalSheetPage(
          backgroundColor: colors.surface,
          hasSabGradient: false,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          child: _RenameContent(
            controller: controller,
            modalContext: modalContext,
            onSave: onSave,
          ),
        ),
      ];
      },
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
    final colors = ThemedColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dialogs.renameScan'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'dialogs.renameScanDesc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
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
