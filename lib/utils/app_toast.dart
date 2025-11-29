import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/export_service.dart';

/// Centralized toast notification utility for consistent app-wide messaging
class AppToast {
  /// Show success notification
  static void success(BuildContext context, String message) {
    final colors = ThemedColors.of(context);

    ElegantNotification(
      title: Text(
        'toast.success'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(color: colors.textSecondary),
      ),
      icon: Icon(Icons.check_circle, color: colors.success),
      background: colors.surface,
      progressIndicatorColor: colors.success,
      toastDuration: const Duration(milliseconds: 2500),
      showProgressIndicator: true,
      borderRadius: BorderRadius.circular(AppRadius.md),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
    ).show(context);
  }

  /// Show error notification
  static void error(BuildContext context, String message) {
    final colors = ThemedColors.of(context);

    ElegantNotification(
      title: Text(
        'toast.error'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(color: colors.textSecondary),
      ),
      icon: Icon(Icons.error, color: colors.error),
      background: colors.surface,
      progressIndicatorColor: colors.error,
      toastDuration: const Duration(milliseconds: 2500),
      showProgressIndicator: true,
      borderRadius: BorderRadius.circular(AppRadius.md),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
    ).show(context);
  }

  /// Show info notification (for processing/loading states)
  /// Returns the notification instance for manual dismissal
  static ElegantNotification info(BuildContext context, String message) {
    final colors = ThemedColors.of(context);

    final notification = ElegantNotification(
      title: Text(
        'toast.processing'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(color: colors.textSecondary),
      ),
      icon: Icon(Icons.info, color: AppColors.primary),
      background: colors.surface,
      progressIndicatorColor: AppColors.primary,
      toastDuration: const Duration(
          seconds: 30), // Long duration, will be dismissed manually
      showProgressIndicator: true,
      borderRadius: BorderRadius.circular(AppRadius.md),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
    );
    notification.show(context);
    return notification;
  }

  /// Convenience method that shows success or error based on isError flag
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (isError) {
      error(context, message);
    } else {
      success(context, message);
    }
  }

  /// Show toast based on ExportResult
  /// Returns true if result was successful (for convenience)
  static bool showExportResult(BuildContext context, ExportResult result) {
    switch (result.type) {
      case ExportResultType.success:
        // Success cases are often silent (file manager opens, etc.)
        // But for image saves, show count
        if (result.savedCount != null && result.totalCount != null) {
          success(
            context,
            'toast.imagesSaved'.tr(namedArgs: {
              'count': result.savedCount.toString(),
              'total': result.totalCount.toString(),
            }),
          );
        }
        return true;

      case ExportResultType.cancelled:
        // User cancelled - no toast needed
        return false;

      case ExportResultType.errorNoImages:
        error(context, 'toast.noImagesToExport'.tr());
        return false;

      case ExportResultType.errorGeneratingPdf:
        error(context, 'toast.failedToExportPdf'.tr());
        return false;

      case ExportResultType.errorCreatingZip:
        error(context, 'toast.failedToCreateZip'.tr());
        return false;

      case ExportResultType.errorSavingFile:
        error(context, 'toast.failedToSavePdf'.tr());
        return false;

      case ExportResultType.errorSavingImages:
        error(context, 'toast.failedToSaveImages'.tr());
        return false;
    }
  }
}
