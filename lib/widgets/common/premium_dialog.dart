import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dialog tap from closing
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

                    // Debug: Reset premium button (only in debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton.ghost(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isPremium', false);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            '[DEV] Reset Premium',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Shrink, dismissable: true);
  }
}
