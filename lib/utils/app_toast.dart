import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:easy_localization/easy_localization.dart';

/// Centralized toast notification utility for consistent app-wide messaging
class AppToast {
  /// Show success notification
  static void success(BuildContext context, String message) {
    ElegantNotification.success(
      title: Text('toast.success'.tr()),
      description: Text(message),
      toastDuration: const Duration(seconds: 3),
      showProgressIndicator: true,
      height: 75,
    ).show(context);
  }

  /// Show error notification
  static void error(BuildContext context, String message) {
    ElegantNotification.error(
      title: Text('toast.error'.tr()),
      description: Text(message),
      toastDuration: const Duration(seconds: 3),
      showProgressIndicator: true,
    ).show(context);
  }

  /// Show info notification (for processing/loading states)
  static void info(BuildContext context, String message) {
    ElegantNotification.info(
      title: Text('toast.processing'.tr()),
      description: Text(message),
      toastDuration: const Duration(seconds: 5),
      showProgressIndicator: true,
    ).show(context);
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
}
