import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class ApprovalEmptyState extends StatelessWidget {
  const ApprovalEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt, color: TheWeColor.green, size: 32),
          const SizedBox(height: 10),
          Text('검색 결과가 없습니다.', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 4),
          Text(
            '다른 문서명, 기안자, 양식명으로 검색해보세요.',
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
        ],
      ),
    );
  }
}
