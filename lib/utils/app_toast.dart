import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/export_service.dart';

/// Centralized toast notification utility for consistent app-wide messaging
/// Uses toastification with flat style, max 1 toast at a time
class AppToast {
  /// Dismiss all existing toasts before showing new one
  static void _dismissAll() {
    toastification.dismissAll(delayForAnimation: false);
  }

  /// Show success notification
  static void success(BuildContext context, String message) {
    _dismissAll();

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(milliseconds: 2500),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 200),
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: false,
      dragToClose: true,
    );
  }

  /// Show error notification
  static void error(BuildContext context, String message) {
    _dismissAll();

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(milliseconds: 2500),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 200),
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: false,
      dragToClose: true,
    );
  }

  /// Show info notification (for processing/loading states)
  /// Returns the ToastificationItem for manual dismissal
  static ToastificationItem info(BuildContext context, String message) {
    _dismissAll();

    return toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 30),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 200),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: false,
      dragToClose: false,
    );
  }

  /// Dismiss a specific toast
  static void dismiss(ToastificationItem item) {
    toastification.dismiss(item);
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
