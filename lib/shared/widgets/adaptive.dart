import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';

bool get isIOS => Platform.isIOS;

/// Adaptive filled button — CupertinoButton.filled on iOS, FilledButton on Android
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(strokeWidth: 2),
          )
        : child;

    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: content,
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: content,
    );
  }
}

/// Adaptive text field
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.expands = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool expands;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        maxLines: expands ? null : maxLines,
        maxLength: maxLength,
        expands: expands,
        focusNode: focusNode,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: expands ? null : maxLines,
      maxLength: maxLength,
      expands: expands,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Theme-aware color helpers
extension DarkModeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardColor =>
      isDark ? AppColors.darkSurfaceCard : AppColors.surfaceCard;
  Color get cardShadowColor =>
      isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(8);
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
  Color get dividerColor =>
      isDark ? AppColors.darkDivider : AppColors.divider;
}

/// Haptic helper
abstract final class Haptic {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
}

/// Adaptive alert dialog
Future<bool?> showAdaptiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelText = '취소',
  String confirmText = '확인',
  bool isDestructive = false,
}) {
  if (isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmText,
            style: isDestructive
                ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                : null,
          ),
        ),
      ],
    ),
  );
}
