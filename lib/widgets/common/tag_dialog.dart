import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_toast.dart';
import '../../utils/app_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/scan_document.dart';

/// Dialog for adding/editing document tags
class TagDialog {
  /// Maximum allowed tag length
  static const int maxLength = 12;

  /// Show the tag dialog
  static void show({
    required BuildContext context,
    String? currentTagText,
    int? currentTagColor,
    required Future<void> Function(String? tagText, int? tagColor) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: currentTagText ?? '');

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
          child: _TagContent(
            controller: controller,
            modalContext: modalContext,
            initialColor: currentTagColor,
            hasExistingTag: currentTagText != null && currentTagText.isNotEmpty,
            onSave: onSave,
          ),
        ),
      ];
      },
    );
  }
}

class _TagContent extends StatefulWidget {
  final TextEditingController controller;
  final BuildContext modalContext;
  final int? initialColor;
  final bool hasExistingTag;
  final Future<void> Function(String? tagText, int? tagColor) onSave;

  const _TagContent({
    required this.controller,
    required this.modalContext,
    required this.initialColor,
    required this.hasExistingTag,
    required this.onSave,
  });

  @override
  State<_TagContent> createState() => _TagContentState();
}

class _TagContentState extends State<_TagContent> {
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? TagColors.presets.first;
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
            widget.hasExistingTag
                ? 'dialogs.editTag'.tr()
                : 'dialogs.addTag'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'dialogs.tagDesc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Preset tags section
          _buildPresetTags(),
          const SizedBox(height: AppSpacing.md),
          // Custom tag input
          ShadInput(
            controller: widget.controller,
            placeholder: Text('dialogs.tagPlaceholder'.tr()),
            autofocus: true,
            maxLength: TagDialog.maxLength,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length} / ${TagDialog.maxLength}',
              style: AppTextStyles.caption.copyWith(
                color: widget.controller.text.length > TagDialog.maxLength
                    ? colors.error
                    : colors.textHint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'dialogs.tagColor'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: AppFontWeight.medium,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildColorPicker(),
          const SizedBox(height: AppSpacing.lg),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildPresetTags() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TagPreset.presets.map((preset) {
        final presetColor = Color(preset.color);
        final contrastColor = _getContrastColor(presetColor);

        return GestureDetector(
          onTap: () {
            setState(() {
              widget.controller.text = preset.label.tr();
              _selectedColor = preset.color;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: presetColor,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Text(
              preset.label.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: contrastColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TagColors.presets.map((colorValue) {
        final isSelected = _selectedColor == colorValue;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = colorValue;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: _getContrastColor(Color(colorValue)),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        if (widget.hasExistingTag)
          ShadButton.outline(
            child: Text('dialogs.removeTag'.tr()),
            onPressed: () async {
              await widget.onSave(null, null);
              if (widget.modalContext.mounted) {
                final route = ModalRoute.of(widget.modalContext);
                if (route != null && route.isCurrent) {
                  Navigator.of(widget.modalContext).pop();
                }
              }
            },
          ),
        const Spacer(),
        ShadButton.outline(
          child: Text('common.cancel'.tr()),
          onPressed: () => Navigator.of(widget.modalContext).pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        ShadButton(
          child: Text('common.save'.tr()),
          onPressed: () async {
            final tagText = widget.controller.text.trim();

            if (tagText.isEmpty) {
              AppToast.show(context, 'validation.tagEmpty'.tr(), isError: true);
              return;
            }

            if (tagText.length > TagDialog.maxLength) {
              AppToast.show(
                context,
                'validation.tagTooLong'.tr(namedArgs: {'max': TagDialog.maxLength.toString()}),
                isError: true,
              );
              return;
            }

            await widget.onSave(tagText, _selectedColor);
            if (widget.modalContext.mounted) {
              final route = ModalRoute.of(widget.modalContext);
              if (route != null && route.isCurrent) {
                Navigator.of(widget.modalContext).pop();
              }
            }
          },
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppColors.black : AppColors.white;
  }
}
