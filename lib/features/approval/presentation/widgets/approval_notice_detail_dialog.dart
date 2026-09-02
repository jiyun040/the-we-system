import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

Future<void> showApprovalNoticeDetailDialog(
  BuildContext context,
  PortalNotice notice,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => TheWeModalSurface(
    key: const ValueKey('notice-detail-dialog'),
    maxWidth: 680,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TheWeModalHeader(
          title: notice.title,
          onClose: () => Navigator.pop(dialogContext),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (notice.isPinned) ...[
              const Icon(
                Icons.push_pin_outlined,
                size: 16,
                color: TheWeColor.blue300,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                notice.authorName,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
            ),
            Text(
              _noticeDate(notice.createdAt),
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Divider(color: TheWeColor.black300.withValues(alpha: .35)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .52,
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              notice.content,
              key: const ValueKey('notice-detail-content'),
              style: TheWeTextStyle.body.copyWith(height: 1.65),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const ValueKey('notice-detail-close-button'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ),
      ],
    ),
  ),
);

String _noticeDate(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;
