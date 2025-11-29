import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
      toastDuration: const Duration(seconds: 2),
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
      toastDuration: const Duration(seconds: 3),
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
}
