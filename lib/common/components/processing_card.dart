import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class ProcessingCard extends StatelessWidget {
  final String title;
  final String drafter;
  final String date;
  final String form;
  final String status;
  final int progress;
  final VoidCallback? onTap;

  const ProcessingCard({
    super.key,
    required this.title,
    required this.drafter,
    required this.date,
    required this.form,
    this.status = '진행중',
    this.progress = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: TheWeColor.white,
          border: Border.all(
            color: TheWeColor.black300.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: TheWeColor.black900.withValues(alpha: 0.05),
              offset: const Offset(0, 8),
              blurRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: status),
                  const Spacer(),
                  Text('$progress%', style: TheWeTextStyle.caption),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TheWeTextStyle.subtitle,
              ),
              const SizedBox(height: 12),
              _InfoLine(label: '기안자', value: drafter),
              _InfoLine(label: '기안일', value: date),
              _InfoLine(label: '결재양식', value: form),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 100) / 100,
                  minHeight: 5,
                  backgroundColor: TheWeColor.blue100.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(TheWeColor.blue300),
                ),
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: TheWeColor.black300.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('상세 보기', style: TheWeTextStyle.caption),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: TheWeColor.black500,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == '결재대기' ? TheWeColor.pink : TheWeColor.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TheWeTextStyle.caption.copyWith(color: color)),
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
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 52,
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
              style: TheWeTextStyle.caption,
            ),
          ),
        ],
      ),
    );
  }
}
