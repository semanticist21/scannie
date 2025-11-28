import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_modal.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Premium one-time purchase dialog
class PremiumDialog {
  /// Show premium dialog
  static void show(BuildContext context, {VoidCallback? onPurchase, bool isPremium = false}) {
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
                // Title
                Text(
                  isPremium ? 'premium.titleActive'.tr() : 'premium.title'.tr(),
                  style: AppTextStyles.h3.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                Text(
                  isPremium
                      ? 'premium.descriptionActive'.tr()
                      : 'premium.description'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
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
                            fontWeight: AppFontWeight.semiBold,
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
                      onPressed: () => Navigator.of(modalContext).pop(),
                      backgroundColor: colors.surface,
                      child: Text('common.close'.tr()),
                    ),
                  ),
                ] else ...[
                  // Purchase button
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: () {
                        onPurchase?.call();
                        Navigator.of(modalContext).pop();
                      },
                      child: Text('premium.unlock'.tr()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      onPressed: () => Navigator.of(modalContext).pop(),
                      backgroundColor: colors.surface,
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
                        if (modalContext.mounted) {
                          Navigator.of(modalContext).pop();
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
                          fontSize: AppFontSize.sm,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
      },
    );
  }
}
