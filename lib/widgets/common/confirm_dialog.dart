import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../utils/app_modal.dart';
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
    required AsyncCallback onConfirm,
  }) {
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: Text(cancelText),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isDestructive)
                      ShadButton.destructive(
                        child: Text(confirmText),
                        onPressed: () async {
                          await onConfirm();
                          if (modalContext.mounted) {
                            Navigator.of(modalContext).pop();
                          }
                        },
                      )
                    else
                      ShadButton(
                        child: Text(confirmText),
                        onPressed: () async {
                          await onConfirm();
                          if (modalContext.mounted) {
                            Navigator.of(modalContext).pop();
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ];
      },
    );
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
    final result = await AppModal.showDialog<bool>(
      context: context,
      barrierDismissible: dismissable,
      pageListBuilder: (modalContext) {
        final colors = ThemedColors.of(modalContext);
        return [
        WoltModalSheetPage(
          backgroundColor: colors.surface,
          hasSabGradient: false,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: Text(cancelText),
                      onPressed: () => Navigator.of(modalContext).pop(false),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isDestructive)
                      ShadButton.destructive(
                        child: Text(confirmText),
                        onPressed: () => Navigator.of(modalContext).pop(true),
                      )
                    else
                      ShadButton(
                        child: Text(confirmText),
                        onPressed: () => Navigator.of(modalContext).pop(true),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ];
      },
    );

    return result ?? false;
  }
}
