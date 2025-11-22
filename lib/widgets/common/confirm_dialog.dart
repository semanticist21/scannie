import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Common confirmation dialog widget
class ConfirmDialog {
  /// Show a confirmation dialog
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    DialogBackground(
      blur: 6,
      dismissable: true,
      barrierColor: AppColors.barrier,
      dialog: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
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
                  title,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: Text(cancelText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isDestructive)
                      ShadButton.destructive(
                        child: Text(confirmText),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                      )
                    else
                      ShadButton(
                        child: Text(confirmText),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);
  }

  /// Show a confirmation dialog and return true if confirmed, false if cancelled
  static Future<bool> showAsync({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDestructive = false,
    bool dismissable = true,
  }) async {
    final completer = Completer<bool>();

    DialogBackground(
      blur: 6,
      dismissable: dismissable,
      barrierColor: AppColors.barrier,
      dialog: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
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
                  title,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: Text(cancelText),
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete(false);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isDestructive)
                      ShadButton.destructive(
                        child: Text(confirmText),
                        onPressed: () {
                          Navigator.of(context).pop();
                          completer.complete(true);
                        },
                      )
                    else
                      ShadButton(
                        child: Text(confirmText),
                        onPressed: () {
                          Navigator.of(context).pop();
                          completer.complete(true);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);

    return completer.future;
  }
}
