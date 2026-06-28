import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class ApprovalMetricTile extends StatelessWidget {
  const ApprovalMetricTile({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    this.selected = false,
  });

  final double width;
  final String title;
  final int value;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? TheWeColor.blue300 : TheWeColor.black500;

    return Container(
      width: width,
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? TheWeColor.blue100.withValues(alpha: 0.34)
            : TheWeColor.white,
        border: Border.all(
          color: selected
              ? TheWeColor.blue200
              : TheWeColor.black300.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
                Text('$value', style: TheWeTextStyle.metric),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
        ],
      ),
    );
  }
}
