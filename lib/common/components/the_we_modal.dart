import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class TheWeModalSurface extends StatelessWidget {
  const TheWeModalSurface({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 560,
    this.maxHeightFactor = 0.9,
    this.padding,
    this.insetPadding,
  });

  final Widget child;
  final double? width;
  final double maxWidth;
  final double maxHeightFactor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;
    final modalHorizontalPadding = isPhone ? 22.0 : 28.0;
    final modalBottomPadding = isPhone ? 20.0 : 24.0;
    final EdgeInsets resolvedInset =
        insetPadding ??
        EdgeInsets.symmetric(horizontal: isPhone ? 18 : 24, vertical: 24);
    final resolvedPadding =
        padding ??
        EdgeInsets.only(
          left: modalHorizontalPadding,
          top: modalHorizontalPadding,
          right: modalHorizontalPadding,
          bottom: modalBottomPadding,
        );

    return Dialog(
      insetPadding: resolvedInset,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screen.height * maxHeightFactor,
        ),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: TheWeColor.shadow,
                blurRadius: 36,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: resolvedPadding,
            child: Material(color: Colors.transparent, child: child),
          ),
        ),
      ),
    );
  }
}

class TheWeModalHeader extends StatelessWidget {
  const TheWeModalHeader({
    super.key,
    required this.title,
    this.onClose,
    this.centered = false,
  });

  final String title;
  final VoidCallback? onClose;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    if (centered) {
      return Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 40,
            child: onClose == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 18,
                    color: TheWeColor.black500,
                  ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            splashRadius: 18,
            color: TheWeColor.black500,
          ),
      ],
    );
  }
}

class TheWeModalAlertIcon extends StatelessWidget {
  const TheWeModalAlertIcon({
    super.key,
    this.icon = Icons.priority_high_rounded,
    this.foregroundColor = TheWeColor.danger,
    this.backgroundColor = TheWeColor.dangerSurface,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: foregroundColor),
    );
  }
}

class TheWeModalActions extends StatelessWidget {
  const TheWeModalActions({
    super.key,
    this.primaryLabel = '확인',
    this.secondaryLabel,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.primaryColor,
    this.expand = false,
    this.centered = false,
  });

  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Color? primaryColor;
  final bool expand;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (secondaryLabel != null)
        _TheWeModalButton(
          label: secondaryLabel!,
          filled: false,
          expanded: expand,
          onPressed: onSecondaryPressed,
        ),
      _TheWeModalButton(
        label: primaryLabel,
        filled: true,
        expanded: expand,
        color: primaryColor ?? TheWeColor.green,
        onPressed: onPrimaryPressed,
      ),
    ];

    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.end,
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (expand) Expanded(child: buttons[index]) else buttons[index],
          if (index != buttons.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class TheWeConfirmDialog extends StatelessWidget {
  const TheWeConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.primaryLabel = '확인',
    this.secondaryLabel = '취소',
    this.primaryColor,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.showSecondary = true,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final Color? primaryColor;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool showSecondary;

  @override
  Widget build(BuildContext context) {
    return TheWeModalSurface(
      maxWidth: 540,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TheWeModalAlertIcon(),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TheWeTextStyle.body.copyWith(height: 1.7),
          ),
          const SizedBox(height: 24),
          TheWeModalActions(
            centered: true,
            primaryLabel: primaryLabel,
            secondaryLabel: showSecondary ? secondaryLabel : null,
            primaryColor: primaryColor,
            onPrimaryPressed: onPrimaryPressed,
            onSecondaryPressed: onSecondaryPressed,
          ),
        ],
      ),
    );
  }
}

class _TheWeModalButton extends StatelessWidget {
  const _TheWeModalButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.color,
    this.expanded = false,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'SUIT-Variable',
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: filled ? Colors.white : TheWeColor.black900,
    );

    final child = SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color ?? TheWeColor.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: (color ?? TheWeColor.green).withValues(
                  alpha: 0.45,
                ),
                textStyle: style,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: TheWeColor.black900,
                side: BorderSide(
                  color: TheWeColor.black300.withValues(alpha: 0.35),
                ),
                textStyle: style,
                elevation: 0,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(label),
            ),
    );

    if (expanded) {
      return child;
    }
    return IntrinsicWidth(child: child);
  }
}
