import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../utils/app_toast.dart';
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
  static String? _validateName(String name) {
    if (name.isEmpty) {
      return 'Name cannot be empty';
    }

    if (name.length > maxLength) {
      return 'Name must be $maxLength characters or less';
    }

    for (int i = 0; i < forbiddenChars.length; i++) {
      if (name.contains(forbiddenChars[i])) {
        return 'Name cannot contain: $forbiddenChars';
      }
    }

    // Check for names that are just dots
    if (name == '.' || name == '..') {
      return 'Invalid name';
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

    DialogBackground(
      blur: 6,
      dismissable: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      dialog: Material(
        color: Colors.transparent,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 320,
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShadInput(
                      controller: controller,
                      placeholder: Text(placeholder),
                      autofocus: true,
                      maxLength: maxLength,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${controller.text.length} / $maxLength',
                        style: AppTextStyles.caption.copyWith(
                          color: controller.text.length > maxLength
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
                          child: Text(cancelText),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ShadButton(
                          child: Text(confirmText),
                          onPressed: () async {
                            final value = controller.text.trim();
                            final error = _validateName(value);
                            if (error != null) {
                              AppToast.show(context, error, isError: true);
                              return;
                            }

                            Navigator.of(context).pop();
                            await onSave(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);
  }
}
