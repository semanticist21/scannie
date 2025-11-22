import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../utils/app_toast.dart';
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

  /// Show the rename dialog
  static void show({
    required BuildContext context,
    required String currentName,
    required Future<void> Function(String newName) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    DialogBackground(
      blur: 6,
      dismissable: true,
      barrierColor: AppColors.barrier,
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
                  boxShadow: AppShadows.dialog,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rename Scan',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter a new name for this document',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShadInput(
                      controller: controller,
                      placeholder: const Text('Document name'),
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
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ShadButton(
                          child: const Text('Save'),
                          onPressed: () async {
                            final newName = controller.text.trim();
                            final error = _validateName(newName);
                            if (error != null) {
                              AppToast.show(context, error, isError: true);
                              return;
                            }

                            Navigator.of(context).pop();
                            await onSave(newName);
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
