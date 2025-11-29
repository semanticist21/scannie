import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Custom dialog type with blur background
class _BlurDialogType extends WoltDialogType {
  _BlurDialogType(BuildContext context)
      : super(
          shapeBorder: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
            side: BorderSide(
              color: ThemedColors.of(context).border,
              width: 1,
            ),
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
  _BlurBottomSheetType(BuildContext context)
      : super(
          shapeBorder: RoundedRectangleBorder(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            side: BorderSide(
              color: ThemedColors.of(context).border,
              width: 1,
            ),
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
      modalTypeBuilder: (ctx) => _BlurDialogType(ctx),
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
      modalTypeBuilder: (ctx) => _BlurBottomSheetType(ctx),
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
