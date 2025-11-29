import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Custom dialog type with blur background
class _BlurDialogType extends WoltDialogType {
  const _BlurDialogType()
      : super(
          shapeBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
            side: BorderSide(color: AppColors.border, width: 1),
          ),
        );

  @override
  Widget decorateModal(
    BuildContext context,
    Widget modal,
    bool useSafeArea,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: AppColors.transparent),
          ),
        ),
        super.decorateModal(context, modal, useSafeArea),
      ],
    );
  }
}

/// Custom bottom sheet type with blur background
class _BlurBottomSheetType extends WoltBottomSheetType {
  const _BlurBottomSheetType()
      : super(
          shapeBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            side: BorderSide(color: AppColors.border, width: 1),
          ),
          showDragHandle: false, // We draw our own drag handle in content
        );

  @override
  Widget decorateModal(
    BuildContext context,
    Widget modal,
    bool useSafeArea,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: AppColors.transparent),
          ),
        ),
        super.decorateModal(context, modal, useSafeArea),
      ],
    );
  }
}

/// Utility class for showing modals with consistent styling
class AppModal {
  AppModal._();

  /// Show a dialog-style modal (centered with blur)
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required List<WoltModalSheetPage> Function(BuildContext) pageListBuilder,
    bool barrierDismissible = true,
  }) {
    return WoltModalSheet.show<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      modalTypeBuilder: (_) => const _BlurDialogType(),
      pageListBuilder: pageListBuilder,
    );
  }

  /// Show a bottom sheet modal (from bottom with blur)
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required List<WoltModalSheetPage> Function(BuildContext) pageListBuilder,
    bool barrierDismissible = true,
  }) {
    return WoltModalSheet.show<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      modalTypeBuilder: (_) => const _BlurBottomSheetType(),
      pageListBuilder: pageListBuilder,
    );
  }

  /// Standard drag handle widget for bottom sheets
  static Widget buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}
