import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Premium one-time purchase dialog
class PremiumDialog {
  /// Show premium dialog
  static void show(BuildContext context, {VoidCallback? onPurchase}) {
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
                // Title
                Text(
                  'Get Premium',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.md),

                // Benefit
                Text(
                  'Scan and create PDFs without limits.\nUnlimited access for just one purchase.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: () {
                      // TODO: Implement actual payment
                      Navigator.of(context).pop();
                      onPurchase?.call();
                    },
                    child: const Text('Unlock - \$1'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton.outline(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink);
  }
}
