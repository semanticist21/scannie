import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../models/scan_document.dart';
import '../../services/theme_service.dart';

/// Language data for app localization (75 languages)
class AppLanguage {
  final String code;
  final String displayName;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
  });

  /// All supported languages sorted alphabetically by display name
  static const List<AppLanguage> all = [
    AppLanguage(code: 'af', displayName: 'Afrikaans', nativeName: 'Afrikaans'),
    AppLanguage(code: 'sq', displayName: 'Albanian', nativeName: 'Shqip'),
    AppLanguage(code: 'am', displayName: 'Amharic', nativeName: 'አማርኛ'),
    AppLanguage(code: 'ar', displayName: 'Arabic', nativeName: 'العربية'),
    AppLanguage(code: 'hy', displayName: 'Armenian', nativeName: 'Հdelays'),
    AppLanguage(code: 'az', displayName: 'Azerbaijani', nativeName: 'Azərbaycan'),
    AppLanguage(code: 'eu', displayName: 'Basque', nativeName: 'Euskara'),
    AppLanguage(code: 'be', displayName: 'Belarusian', nativeName: 'Беларуская'),
    AppLanguage(code: 'bn', displayName: 'Bengali', nativeName: 'বাংলা'),
    AppLanguage(code: 'bs', displayName: 'Bosnian', nativeName: 'Bosanski'),
    AppLanguage(code: 'bg', displayName: 'Bulgarian', nativeName: 'Български'),
    AppLanguage(code: 'my', displayName: 'Burmese', nativeName: 'မြန်မာ'),
    AppLanguage(code: 'ca', displayName: 'Catalan', nativeName: 'Català'),
    AppLanguage(code: 'zh', displayName: 'Chinese', nativeName: '中文'),
    AppLanguage(code: 'hr', displayName: 'Croatian', nativeName: 'Hrvatski'),
    AppLanguage(code: 'cs', displayName: 'Czech', nativeName: 'Čeština'),
    AppLanguage(code: 'da', displayName: 'Danish', nativeName: 'Dansk'),
    AppLanguage(code: 'nl', displayName: 'Dutch', nativeName: 'Nederlands'),
    AppLanguage(code: 'en', displayName: 'English', nativeName: 'English'),
    AppLanguage(code: 'et', displayName: 'Estonian', nativeName: 'Eesti'),
    AppLanguage(code: 'fil', displayName: 'Filipino', nativeName: 'Filipino'),
    AppLanguage(code: 'fi', displayName: 'Finnish', nativeName: 'Suomi'),
    AppLanguage(code: 'fr', displayName: 'French', nativeName: 'Français'),
    AppLanguage(code: 'gl', displayName: 'Galician', nativeName: 'Galego'),
    AppLanguage(code: 'ka', displayName: 'Georgian', nativeName: 'ქართული'),
    AppLanguage(code: 'de', displayName: 'German', nativeName: 'Deutsch'),
    AppLanguage(code: 'el', displayName: 'Greek', nativeName: 'Ελληνικά'),
    AppLanguage(code: 'gu', displayName: 'Gujarati', nativeName: 'ગુજરાતી'),
    AppLanguage(code: 'he', displayName: 'Hebrew', nativeName: 'עברית'),
    AppLanguage(code: 'hi', displayName: 'Hindi', nativeName: 'हिन्दी'),
    AppLanguage(code: 'hu', displayName: 'Hungarian', nativeName: 'Magyar'),
    AppLanguage(code: 'is', displayName: 'Icelandic', nativeName: 'Íslenska'),
    AppLanguage(code: 'id', displayName: 'Indonesian', nativeName: 'Indonesia'),
    AppLanguage(code: 'ga', displayName: 'Irish', nativeName: 'Gaeilge'),
    AppLanguage(code: 'it', displayName: 'Italian', nativeName: 'Italiano'),
    AppLanguage(code: 'ja', displayName: 'Japanese', nativeName: '日本語'),
    AppLanguage(code: 'kn', displayName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    AppLanguage(code: 'kk', displayName: 'Kazakh', nativeName: 'Қазақ'),
    AppLanguage(code: 'km', displayName: 'Khmer', nativeName: 'ខ្មែរ'),
    AppLanguage(code: 'ko', displayName: 'Korean', nativeName: '한국어'),
    AppLanguage(code: 'ky', displayName: 'Kyrgyz', nativeName: 'Кыргызча'),
    AppLanguage(code: 'lo', displayName: 'Lao', nativeName: 'ລາວ'),
    AppLanguage(code: 'lv', displayName: 'Latvian', nativeName: 'Latviešu'),
    AppLanguage(code: 'lt', displayName: 'Lithuanian', nativeName: 'Lietuvių'),
    AppLanguage(code: 'mk', displayName: 'Macedonian', nativeName: 'Македонски'),
    AppLanguage(code: 'ms', displayName: 'Malay', nativeName: 'Melayu'),
    AppLanguage(code: 'ml', displayName: 'Malayalam', nativeName: 'മലയാളം'),
    AppLanguage(code: 'mt', displayName: 'Maltese', nativeName: 'Malti'),
    AppLanguage(code: 'mr', displayName: 'Marathi', nativeName: 'मराठी'),
    AppLanguage(code: 'mn', displayName: 'Mongolian', nativeName: 'Монгол'),
    AppLanguage(code: 'ne', displayName: 'Nepali', nativeName: 'नेपाली'),
    AppLanguage(code: 'nb', displayName: 'Norwegian', nativeName: 'Norsk'),
    AppLanguage(code: 'fa', displayName: 'Persian', nativeName: 'فارسی'),
    AppLanguage(code: 'pl', displayName: 'Polish', nativeName: 'Polski'),
    AppLanguage(code: 'pt', displayName: 'Portuguese', nativeName: 'Português'),
    AppLanguage(code: 'pa', displayName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    AppLanguage(code: 'ro', displayName: 'Romanian', nativeName: 'Română'),
    AppLanguage(code: 'ru', displayName: 'Russian', nativeName: 'Русский'),
    AppLanguage(code: 'sr', displayName: 'Serbian', nativeName: 'Српски'),
    AppLanguage(code: 'si', displayName: 'Sinhala', nativeName: 'සිංහල'),
    AppLanguage(code: 'sk', displayName: 'Slovak', nativeName: 'Slovenčina'),
    AppLanguage(code: 'sl', displayName: 'Slovenian', nativeName: 'Slovenščina'),
    AppLanguage(code: 'es', displayName: 'Spanish', nativeName: 'Español'),
    AppLanguage(code: 'sw', displayName: 'Swahili', nativeName: 'Kiswahili'),
    AppLanguage(code: 'sv', displayName: 'Swedish', nativeName: 'Svenska'),
    AppLanguage(code: 'ta', displayName: 'Tamil', nativeName: 'தமிழ்'),
    AppLanguage(code: 'te', displayName: 'Telugu', nativeName: 'తెలుగు'),
    AppLanguage(code: 'th', displayName: 'Thai', nativeName: 'ไทย'),
    AppLanguage(code: 'tr', displayName: 'Turkish', nativeName: 'Türkçe'),
    AppLanguage(code: 'uk', displayName: 'Ukrainian', nativeName: 'Українська'),
    AppLanguage(code: 'ur', displayName: 'Urdu', nativeName: 'اردو'),
    AppLanguage(code: 'uz', displayName: 'Uzbek', nativeName: 'Oʻzbek'),
    AppLanguage(code: 'vi', displayName: 'Vietnamese', nativeName: 'Tiếng Việt'),
    AppLanguage(code: 'cy', displayName: 'Welsh', nativeName: 'Cymraeg'),
    AppLanguage(code: 'zu', displayName: 'Zulu', nativeName: 'isiZulu'),
  ];

  /// Find language by code
  static AppLanguage? fromCode(String code) {
    try {
      return all.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
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
  String _versionString = '';

  @override
  void initState() {
    super.initState();
    _currentTheme = ThemeService.instance.themeMode;
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _versionString = 'Scannie ${packageInfo.version} (+${packageInfo.buildNumber})';
      });
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar - FIXED (not scrollable, for drag-to-close)
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
          // Header - FIXED
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

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  // Language select - opens a separate bottom sheet
                  InkWell(
                    onTap: () => _showLanguageSelector(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 22,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.currentLanguage.displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: AppFontWeight.medium,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.currentLanguage.nativeName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
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
            const SizedBox(height: AppSpacing.sm),

                  // Version info (at bottom)
                  if (_versionString.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Center(
                        child: Text(
                          _versionString,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final colors = ThemedColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _LanguageSelectorSheet(
        currentLanguage: widget.currentLanguage,
        onLanguageSelected: (language) {
          // Close language selector sheet first
          Navigator.pop(sheetContext);
          // Then close settings sheet and trigger callback
          widget.onLanguageChanged(language);
        },
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

/// Separate StatefulWidget for language selector with search
class _LanguageSelectorSheet extends StatefulWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageSelected;

  const _LanguageSelectorSheet({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<_LanguageSelectorSheet> createState() => _LanguageSelectorSheetState();
}

class _LanguageSelectorSheetState extends State<_LanguageSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return AppLanguage.all;
    }
    final query = _searchQuery.toLowerCase();
    return AppLanguage.all.where((lang) {
      return lang.displayName.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemedColors.of(context);
    final filteredLanguages = _filteredLanguages;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Row(
              children: [
                Text(
                  'settings.language'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppFontWeight.semiBold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredLanguages.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'settings.searchLanguage'.tr(),
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textHint,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: colors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colors.border),
          // Current language (pinned at top when not searching)
          if (_searchQuery.isEmpty) ...[
            _buildLanguageItem(
              context,
              language: widget.currentLanguage,
              isSelected: true,
              colors: colors,
            ),
            Divider(height: 1, color: colors.border),
          ],
          // Language list
          Expanded(
            child: filteredLanguages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 48,
                          color: colors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'settings.noLanguageFound'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final language = filteredLanguages[index];
                      // Skip current language in list when not searching (already shown at top)
                      if (_searchQuery.isEmpty &&
                          language.code == widget.currentLanguage.code) {
                        return const SizedBox.shrink();
                      }
                      final isSelected =
                          language.code == widget.currentLanguage.code;
                      return _buildLanguageItem(
                        context,
                        language: language,
                        isSelected: isSelected,
                        colors: colors,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required AppLanguage language,
    required bool isSelected,
    required ThemedColors colors,
  }) {
    return InkWell(
      onTap: () => widget.onLanguageSelected(language),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 22,
              color: isSelected ? AppColors.primary : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.displayName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? AppFontWeight.semiBold : AppFontWeight.normal,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    language.nativeName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
