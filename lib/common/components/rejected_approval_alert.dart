import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

class RejectedApprovalAlert extends StatelessWidget {
  const RejectedApprovalAlert({
    super.key,
    required this.document,
    required this.pendingCount,
    required this.onOpen,
    required this.onDismiss,
  });

  final ApprovalDocument document;
  final int pendingCount;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return SafeArea(
      minimum: EdgeInsets.all(compact ? 10 : 18),
      child: Material(
        key: const ValueKey('rejected-approval-alert'),
        color: TheWeColor.white,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: compact ? double.infinity : 390,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TheWeColor.danger.withValues(alpha: .3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: TheWeColor.dangerSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_return_outlined,
                  size: 20,
                  color: TheWeColor.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('결재 문서가 반려됐습니다', style: TheWeTextStyle.subtitle),
                    const SizedBox(height: 3),
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.body,
                    ),
                    if (pendingCount > 1) ...[
                      const SizedBox(height: 3),
                      Text(
                        '확인하지 않은 반려 문서가 ${pendingCount - 1}건 더 있습니다.',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton(
                      key: const ValueKey('rejected-approval-open'),
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: TheWeColor.danger,
                      ),
                      child: const Text('문서 확인'),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('rejected-approval-dismiss'),
                tooltip: '이 알림 확인',
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
