import 'package:flutter/material.dart';

enum DialogType {
  info,
  warning,
  error,
  success,
  confirmation,
  custom,
}

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final DialogType type;
  final List<DialogAction> actions;
  final bool barrierDismissible;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final double? maxWidth;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
    this.iconColor,
    this.type = DialogType.info,
    this.actions = const [],
    this.barrierDismissible = true,
    this.backgroundColor,
    this.contentPadding,
    this.maxWidth = 400,
    this.showCloseButton = false,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? content,
    IconData? icon,
    Color? iconColor,
    DialogType type = DialogType.info,
    List<DialogAction> actions = const [],
    bool barrierDismissible = true,
    Color? backgroundColor,
    EdgeInsetsGeometry? contentPadding,
    double? maxWidth = 400,
    bool showCloseButton = false,
    VoidCallback? onClose,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => AppDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        icon: icon,
        iconColor: iconColor,
        type: type,
        actions: actions,
        barrierDismissible: barrierDismissible,
        backgroundColor: backgroundColor,
        contentPadding: contentPadding,
        maxWidth: maxWidth,
        showCloseButton: showCloseButton,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeConfig = _getTypeConfiguration();
    final effectiveIcon = icon ?? typeConfig.icon;
    final effectiveIconColor = iconColor ?? typeConfig.color;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, effectiveIcon, effectiveIconColor, typeConfig),
            if (content != null) _buildContent(),
            if (actions.isNotEmpty) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IconData? effectiveIcon, Color effectiveIconColor, _DialogTypeConfig typeConfig) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24, showCloseButton ? 16 : 24, subtitle != null || content != null ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            effectiveIconColor.withValues(alpha: 0.1),
            effectiveIconColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: subtitle != null || content != null ? Radius.zero : const Radius.circular(24),
          bottomRight: subtitle != null || content != null ? Radius.zero : const Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (effectiveIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                effectiveIcon,
                color: effectiveIconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showCloseButton)
            IconButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade600,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: contentPadding ?? const EdgeInsets.all(24),
        child: content!,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              flex: actions[i].flex,
              child: _buildActionButton(context, actions[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DialogAction action) {
    if (action.isOutlined) {
      return OutlinedButton(
        onPressed: action.onPressed ?? () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: action.color ?? Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (action.icon != null) ...[
              Icon(
                action.icon,
                size: 18,
                color: action.color ?? Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              action.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: action.color ?? Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: action.onPressed ?? () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.color ?? Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: action.isDestructive ? 0 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (action.icon != null) ...[
            Icon(
              action.icon,
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            action.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _DialogTypeConfig _getTypeConfiguration() {
    switch (type) {
      case DialogType.info:
        return _DialogTypeConfig(
          icon: Icons.info_outline,
          color: Colors.blue,
        );
      case DialogType.warning:
        return _DialogTypeConfig(
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
        );
      case DialogType.error:
        return _DialogTypeConfig(
          icon: Icons.error_outline,
          color: Colors.red,
        );
      case DialogType.success:
        return _DialogTypeConfig(
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );
      case DialogType.confirmation:
        return _DialogTypeConfig(
          icon: Icons.help_outline,
          color: Colors.blue,
        );
      case DialogType.custom:
        return _DialogTypeConfig(
          icon: null,
          color: Colors.blue,
        );
    }
  }
}

class DialogAction {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;
  final bool isDestructive;
  final int flex;

  const DialogAction({
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.isOutlined = false,
    this.isDestructive = false,
    this.flex = 1,
  });

  // Predefined action types
  static DialogAction cancel({
    String text = 'Cancel',
    VoidCallback? onPressed,
  }) {
    return DialogAction(
      text: text,
      onPressed: onPressed,
      isOutlined: true,
      color: Colors.grey.shade600,
    );
  }

  static DialogAction confirm({
    String text = 'Confirm',
    VoidCallback? onPressed,
    Color? color,
  }) {
    return DialogAction(
      text: text,
      onPressed: onPressed,
      color: color ?? Colors.blue,
      flex: 2,
    );
  }

  static DialogAction delete({
    String text = 'Delete',
    VoidCallback? onPressed,
  }) {
    return DialogAction(
      text: text,
      onPressed: onPressed,
      icon: Icons.delete_outline,
      color: Colors.red,
      isDestructive: true,
    );
  }

  static DialogAction save({
    String text = 'Save',
    VoidCallback? onPressed,
  }) {
    return DialogAction(
      text: text,
      onPressed: onPressed,
      icon: Icons.save_outlined,
      color: Colors.green,
      flex: 2,
    );
  }

  static DialogAction ok({
    String text = 'OK',
    VoidCallback? onPressed,
  }) {
    return DialogAction(
      text: text,
      onPressed: onPressed,
      color: Colors.blue,
    );
  }
}

class _DialogTypeConfig {
  final IconData? icon;
  final Color color;

  const _DialogTypeConfig({
    required this.icon,
    required this.color,
  });
}

// Convenience methods for common dialog types
class DialogUtils {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDestructive = false,
  }) {
    return AppDialog.show<bool>(
      context: context,
      title: title,
      type: isDestructive ? DialogType.warning : DialogType.confirmation,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        DialogAction.cancel(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          text: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          color: confirmColor ?? (isDestructive ? Colors.red : Colors.blue),
          flex: 2,
        ),
      ],
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return AppDialog.show(
      context: context,
      title: title,
      type: DialogType.info,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        DialogAction.ok(text: buttonText),
      ],
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return AppDialog.show(
      context: context,
      title: title,
      type: DialogType.error,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        DialogAction.ok(text: buttonText),
      ],
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return AppDialog.show(
      context: context,
      title: title,
      type: DialogType.success,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        DialogAction.ok(text: buttonText),
      ],
    );
  }
}