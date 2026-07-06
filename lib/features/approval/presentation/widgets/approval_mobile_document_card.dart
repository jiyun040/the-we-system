import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

class ApprovalMobileDocumentCard extends StatelessWidget {
  const ApprovalMobileDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.actions = const [],
  });

  final ApprovalDocument document;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (document.status) {
      '완료' => TheWeColor.green,
      '반려' => TheWeColor.pink,
      '작성중' || '임시저장' => TheWeColor.black500,
      _ => TheWeColor.blue300,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TheWeColor.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: TheWeColor.black300.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TheWeTextStyle.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(text: document.status, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: '양식', value: document.form),
            _InfoLine(label: '기안자', value: document.drafter),
            _InfoLine(label: '기안일', value: document.draftedAt),
            _InfoLine(label: '문서번호', value: document.documentNo),
            if (document.linkedDocuments.isNotEmpty)
              _InfoLine(
                label: '첨부',
                value: '${document.linkedDocuments.length}건',
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TheWeTextStyle.caption.copyWith(color: color)),
    );
  }
}
