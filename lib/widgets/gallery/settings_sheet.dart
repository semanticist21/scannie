import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/scan_document.dart';
import '../../services/theme_service.dart';

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
class SettingsSheet extends StatefulWidget {
  final bool isGridView;
  final ValueChanged<bool> onViewModeChanged;
  final bool isPremium;
  final VoidCallback onPremiumTap;
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;
  // PDF settings
  final PdfQuality pdfQuality;
  final ValueChanged<PdfQuality> onPdfQualityChanged;
  final PdfPageSize pdfPageSize;
  final ValueChanged<PdfPageSize> onPdfPageSizeChanged;
  final PdfOrientation pdfOrientation;
  final ValueChanged<PdfOrientation> onPdfOrientationChanged;
  final PdfImageFit pdfImageFit;
  final ValueChanged<PdfImageFit> onPdfImageFitChanged;
  final PdfMargin pdfMargin;
  final ValueChanged<PdfMargin> onPdfMarginChanged;

  const SettingsSheet({
    super.key,
    required this.isGridView,
    required this.onViewModeChanged,
    required this.isPremium,
    required this.onPremiumTap,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.pdfQuality,
    required this.onPdfQualityChanged,
    required this.pdfPageSize,
    required this.onPdfPageSizeChanged,
    required this.pdfOrientation,
    required this.onPdfOrientationChanged,
    required this.pdfImageFit,
    required this.onPdfImageFitChanged,
    required this.pdfMargin,
    required this.onPdfMarginChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();

  /// Show the settings bottom sheet
  static void show({
    required BuildContext context,
    required bool isGridView,
    required ValueChanged<bool> onViewModeChanged,
    required bool isPremium,
    required VoidCallback onPremiumTap,
    required AppLanguage currentLanguage,
    required ValueChanged<AppLanguage> onLanguageChanged,
    required PdfQuality pdfQuality,
    required ValueChanged<PdfQuality> onPdfQualityChanged,
    required PdfPageSize pdfPageSize,
    required ValueChanged<PdfPageSize> onPdfPageSizeChanged,
    required PdfOrientation pdfOrientation,
    required ValueChanged<PdfOrientation> onPdfOrientationChanged,
    required PdfImageFit pdfImageFit,
    required ValueChanged<PdfImageFit> onPdfImageFitChanged,
    required PdfMargin pdfMargin,
    required ValueChanged<PdfMargin> onPdfMarginChanged,
  }) {
    final colors = ThemedColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SettingsSheet(
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
          pdfQuality: pdfQuality,
          onPdfQualityChanged: onPdfQualityChanged,
          pdfPageSize: pdfPageSize,
          onPdfPageSizeChanged: onPdfPageSizeChanged,
          pdfOrientation: pdfOrientation,
          onPdfOrientationChanged: onPdfOrientationChanged,
          pdfImageFit: pdfImageFit,
          onPdfImageFitChanged: onPdfImageFitChanged,
          pdfMargin: pdfMargin,
          onPdfMarginChanged: onPdfMarginChanged,
        ),
      ),
    );
  }
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppThemeMode _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = ThemeService.instance.themeMode;
  }

  Future<void> _setThemeMode(AppThemeMode mode) async {
    setState(() => _currentTheme = mode);
    await ThemeService.instance.setThemeMode(mode);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'settings.themeSystem'.tr();
      case AppThemeMode.light:
        return 'settings.themeLight'.tr();
      case AppThemeMode.dark:
        return 'settings.themeDark'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = widget.isGridView ? ViewMode.grid : ViewMode.list;
    final colors = ThemedColors.of(context);

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
                  color: colors.border,
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
                  fontWeight: AppFontWeight.semiBold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Premium section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.premium'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: widget.onPremiumTap,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isPremium ? LucideIcons.circleOff : LucideIcons.sparkles,
                            size: 22,
                            color: widget.isPremium
                                ? AppColors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              widget.isPremium ? 'settings.premiumActive'.tr() : 'settings.getPremium'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: AppFontWeight.medium,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Appearance section (Theme)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.appearance'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Theme options
                  ...AppThemeMode.values.map((mode) {
                    final isSelected = mode == _currentTheme;
                    return InkWell(
                      onTap: () => _setThemeMode(mode),
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
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              mode.icon,
                              size: 18,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _getThemeDisplayName(mode),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected
                                      ? AppFontWeight.semiBold
                                      : AppFontWeight.normal,
                                  color: colors.textPrimary,
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
            Divider(height: 1, color: colors.border),

            // View Mode section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.viewMode'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // View mode options
                  ...ViewMode.values.map((mode) {
                    final isSelected = mode == currentMode;
                    return InkWell(
                      onTap: () => widget.onViewModeChanged(mode == ViewMode.grid),
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
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              mode.icon,
                              size: 18,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'settings.${mode.name}'.tr(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected
                                      ? AppFontWeight.semiBold
                                      : AppFontWeight.normal,
                                  color: colors.textPrimary,
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
            Divider(height: 1, color: colors.border),

            // PDF Default Settings section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.pdfDefaults'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quality
                  _buildPdfOptionRow(
                    context,
                    colors: colors,
                    icon: LucideIcons.image,
                    label: 'settings.pdfQuality'.tr(),
                    child: SizedBox(
                      width: 120,
                      child: ShadSelect<PdfQuality>(
                        initialValue: widget.pdfQuality,
                        onChanged: (value) {
                          if (value != null) widget.onPdfQualityChanged(value);
                        },
                        selectedOptionBuilder: (context, value) => Text(
                          value.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        options: PdfQuality.values
                            .map((q) => ShadOption(
                                  value: q,
                                  child: Text(q.displayName),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Page Size
                  _buildPdfOptionRow(
                    context,
                    colors: colors,
                    icon: LucideIcons.fileText,
                    label: 'settings.pdfPageSize'.tr(),
                    child: SizedBox(
                      width: 120,
                      child: ShadSelect<PdfPageSize>(
                        initialValue: widget.pdfPageSize,
                        onChanged: (value) {
                          if (value != null) widget.onPdfPageSizeChanged(value);
                        },
                        selectedOptionBuilder: (context, value) => Text(
                          value.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        options: PdfPageSize.values
                            .map((s) => ShadOption(
                                  value: s,
                                  child: Text(s.displayName),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Orientation
                  _buildPdfOptionRow(
                    context,
                    colors: colors,
                    icon: LucideIcons.smartphone,
                    label: 'settings.pdfOrientation'.tr(),
                    child: SizedBox(
                      width: 120,
                      child: ShadSelect<PdfOrientation>(
                        initialValue: widget.pdfOrientation,
                        onChanged: (value) {
                          if (value != null) widget.onPdfOrientationChanged(value);
                        },
                        selectedOptionBuilder: (context, value) => Text(
                          value.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        options: PdfOrientation.values
                            .map((o) => ShadOption(
                                  value: o,
                                  child: Text(o.displayName),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Image Fit
                  _buildPdfOptionRow(
                    context,
                    colors: colors,
                    icon: LucideIcons.maximize,
                    label: 'settings.pdfImageFit'.tr(),
                    child: SizedBox(
                      width: 120,
                      child: ShadSelect<PdfImageFit>(
                        initialValue: widget.pdfImageFit,
                        onChanged: (value) {
                          if (value != null) widget.onPdfImageFitChanged(value);
                        },
                        selectedOptionBuilder: (context, value) => Text(
                          value.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        options: PdfImageFit.values
                            .map((f) => ShadOption(
                                  value: f,
                                  child: Text(f.displayName),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Margin
                  _buildPdfOptionRow(
                    context,
                    colors: colors,
                    icon: LucideIcons.square,
                    label: 'settings.pdfMargin'.tr(),
                    child: SizedBox(
                      width: 120,
                      child: ShadSelect<PdfMargin>(
                        initialValue: widget.pdfMargin,
                        onChanged: (value) {
                          if (value != null) widget.onPdfMarginChanged(value);
                        },
                        selectedOptionBuilder: (context, value) => Text(
                          value.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        options: PdfMargin.values
                            .map((m) => ShadOption(
                                  value: m,
                                  child: Text(m.displayName),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Language section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.language'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Language select
                  SizedBox(
                    width: 160,
                    child: ShadSelect<AppLanguage>(
                      initialValue: widget.currentLanguage,
                      onChanged: (value) {
                        if (value != null) {
                          widget.onLanguageChanged(value);
                        }
                      },
                      selectedOptionBuilder: (context, value) => Row(
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              value.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.textPrimary,
                              ),
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
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfOptionRow(
    BuildContext context, {
    required ThemedColors colors,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
