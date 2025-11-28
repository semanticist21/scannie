import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_modal.dart';
import '../../utils/app_toast.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/purchase_service.dart';

/// Premium one-time purchase dialog
class PremiumDialog {
  /// Show premium dialog
  static void show(BuildContext context, {VoidCallback? onPurchaseComplete, bool isPremium = false}) {
    AppModal.showDialog(
      context: context,
      pageListBuilder: (modalContext) {
        final colors = ThemedColors.of(modalContext);
        final purchaseService = PurchaseService.instance;
        final priceString = purchaseService.priceString;

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
                  // Purchase button with price
                  _PurchaseButton(
                    priceString: priceString,
                    colors: colors,
                    onPurchaseComplete: () {
                      onPurchaseComplete?.call();
                      Navigator.of(modalContext).pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Restore purchases button
                  _RestoreButton(colors: colors),
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
                            onPurchaseComplete: onPurchaseComplete,
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

/// Purchase button with loading state
class _PurchaseButton extends StatefulWidget {
  final String priceString;
  final ThemedColors colors;
  final VoidCallback onPurchaseComplete;

  const _PurchaseButton({
    required this.priceString,
    required this.colors,
    required this.onPurchaseComplete,
  });

  @override
  State<_PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends State<_PurchaseButton> {
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final purchaseService = PurchaseService.instance;

      if (!purchaseService.isAvailable) {
        if (mounted) {
          AppToast.error(context, 'premium.storeNotAvailable'.tr());
        }
        return;
      }

      final success = await purchaseService.purchasePremium();

      if (!success && mounted) {
        // Purchase was initiated but may have been cancelled by user
        // Don't show error - the purchase stream will handle actual errors
        debugPrint('💎 Purchase not initiated');
      }

      // Note: onPurchaseComplete will be called when the purchase stream
      // confirms the purchase is complete. For now, we close the dialog
      // The purchase result will be handled by PurchaseService
    } catch (e) {
      debugPrint('💎 Purchase error: $e');
      if (mounted) {
        AppToast.error(context, 'premium.purchaseFailed'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        onPressed: _isLoading ? null : _handlePurchase,
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('premium.unlockWithPrice'.tr(args: [widget.priceString])),
      ),
    );
  }
}

/// Restore purchases button
class _RestoreButton extends StatefulWidget {
  final ThemedColors colors;

  const _RestoreButton({required this.colors});

  @override
  State<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends State<_RestoreButton> {
  bool _isLoading = false;

  Future<void> _handleRestore() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final purchaseService = PurchaseService.instance;
      final success = await purchaseService.restorePurchases();

      if (mounted) {
        if (success) {
          AppToast.success(context, 'premium.restoreRequested'.tr());
        } else {
          AppToast.error(context, 'premium.restoreFailed'.tr());
        }
      }
    } catch (e) {
      debugPrint('💎 Restore error: $e');
      if (mounted) {
        AppToast.error(context, 'premium.restoreFailed'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ShadButton.ghost(
        onPressed: _isLoading ? null : _handleRestore,
        child: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.colors.textSecondary),
                ),
              )
            : Text(
                'premium.restore'.tr(),
                style: TextStyle(
                  color: widget.colors.textSecondary,
                  fontSize: AppFontSize.sm,
                ),
              ),
      ),
    );
  }
}
