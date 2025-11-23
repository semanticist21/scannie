import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Premium one-time purchase dialog
class PremiumDialog {
  /// Show premium dialog
  static void show(BuildContext context, {VoidCallback? onPurchase, bool isPremium = false}) {
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
                      isPremium ? 'premium.titleActive'.tr() : 'premium.title'.tr(),
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Description
                    Text(
                      isPremium
                          ? 'premium.descriptionActive'.tr()
                          : 'premium.description'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (isPremium) ...[
                      // Premium active indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.circleCheck,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'premium.unlocked'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton.outline(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('common.close'.tr()),
                        ),
                      ),
                    ] else ...[
                      // Purchase button
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          onPressed: () {
                            // Call onPurchase BEFORE pop to ensure state is saved
                            onPurchase?.call();
                            Navigator.of(context).pop();
                          },
                          child: Text('premium.unlock'.tr()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton.outline(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('premium.maybeLater'.tr()),
                        ),
                      ),
                    ],

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
                              // Reopen dialog with updated state
                              PremiumDialog.show(
                                context,
                                onPurchase: onPurchase,
                                isPremium: false,
                              );
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
