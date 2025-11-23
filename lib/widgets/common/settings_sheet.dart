import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// App language options
enum AppLanguage {
  english,
  korean;

  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.korean:
        return '한국어';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.korean:
        return 'ko';
    }
  }
}

/// View mode options for document list
enum ViewMode {
  list,
  grid;

  String get displayName {
    switch (this) {
      case ViewMode.list:
        return 'List';
      case ViewMode.grid:
        return 'Grid';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewMode.list:
        return LucideIcons.list;
      case ViewMode.grid:
        return LucideIcons.layoutGrid;
    }
  }
}

/// Bottom sheet for app settings
class SettingsSheet extends StatelessWidget {
  final bool isGridView;
  final ValueChanged<bool> onViewModeChanged;
  final bool isPremium;
  final VoidCallback onPremiumTap;
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const SettingsSheet({
    super.key,
    required this.isGridView,
    required this.onViewModeChanged,
    required this.isPremium,
    required this.onPremiumTap,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  /// Show the settings bottom sheet
  static void show({
    required BuildContext context,
    required bool isGridView,
    required ValueChanged<bool> onViewModeChanged,
    required bool isPremium,
    required VoidCallback onPremiumTap,
    required AppLanguage currentLanguage,
    required ValueChanged<AppLanguage> onLanguageChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SettingsSheet(
        isGridView: isGridView,
        onViewModeChanged: (isGrid) {
          Navigator.pop(sheetContext);
          onViewModeChanged(isGrid);
        },
        isPremium: isPremium,
        onPremiumTap: () {
          Navigator.pop(sheetContext);
          onPremiumTap();
        },
        currentLanguage: currentLanguage,
        onLanguageChanged: (language) {
          Navigator.pop(sheetContext);
          onLanguageChanged(language);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = isGridView ? ViewMode.grid : ViewMode.list;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'settings.title'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

          // Premium section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.premium'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: onPremiumTap,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 22,
                          color: isPremium
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            isPremium ? 'settings.premiumActive'.tr() : 'settings.getPremium'.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Language section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.language'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Language select
                SizedBox(
                  width: 160,
                  child: ShadSelect<AppLanguage>(
                    initialValue: currentLanguage,
                    onChanged: (value) {
                      if (value != null) {
                        onLanguageChanged(value);
                      }
                    },
                    selectedOptionBuilder: (context, value) => Row(
                      children: [
                        const Icon(
                          LucideIcons.globe,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            value.displayName,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    options: AppLanguage.values
                        .map(
                          (language) => ShadOption(
                            value: language,
                            child: Text(
                              language.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // View Mode section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.viewMode'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // View mode options
                ...ViewMode.values.map((mode) {
                  final isSelected = mode == currentMode;
                  return InkWell(
                    onTap: () => onViewModeChanged(mode == ViewMode.grid),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(
                            mode.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'settings.${mode.name}'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
