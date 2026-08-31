import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

enum TheWeSnackBarType { success, error, info }

void showTheWeSnackBar(
  BuildContext context, {
  required String message,
  TheWeSnackBarType type = TheWeSnackBarType.success,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final accent = switch (type) {
    TheWeSnackBarType.success => TheWeColor.green,
    TheWeSnackBarType.error => TheWeColor.danger,
    TheWeSnackBarType.info => TheWeColor.blue300,
  };
  final icon = switch (type) {
    TheWeSnackBarType.success => Icons.check_rounded,
    TheWeSnackBarType.error => Icons.priority_high_rounded,
    TheWeSnackBarType.info => Icons.info_outline_rounded,
  };
  final availableWidth = MediaQuery.sizeOf(context).width - 32;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        width: math.min(availableWidth, 680),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: const Color(0xFF4D5357),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: type == TheWeSnackBarType.error
            ? const Duration(seconds: 6)
            : const Duration(seconds: 3),
        dismissDirection: DismissDirection.down,
        showCloseIcon: type == TheWeSnackBarType.error,
        closeIconColor: Colors.white,
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TheWeTextStyle.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: TheWeColor.blue200,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
