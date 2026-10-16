import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'approval_document_sheet_attachments.dart';

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
        if (notice.attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('첨부파일', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 6),
          ...notice.attachments.map(
            (attachment) => Consumer(
              builder: (context, ref, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final bytes = await ref
                            .read(theWeApiServiceProvider)
                            .downloadNoticeAttachment(
                              notice.id,
                              attachment.id!,
                            );
                        if (!context.mounted) return;
                        await showApprovalAttachmentPreview(
                          context,
                          ApprovalAttachment.fromBytes(
                            name: attachment.name,
                            mimeType: attachment.mimeType,
                            bytes: bytes,
                          ),
                        );
                      } catch (_) {
                        if (context.mounted) {
                          showTheWeSnackBar(
                            context,
                            message: '첨부파일을 열지 못했습니다.',
                            type: TheWeSnackBarType.error,
                          );
                        }
                      }
                    },
                    child: const Text('보기'),
                  ),
                  IconButton(
                    tooltip: '다운로드',
                    onPressed: () async {
                      try {
                        final bytes = await ref
                            .read(theWeApiServiceProvider)
                            .downloadNoticeAttachment(
                              notice.id,
                              attachment.id!,
                            );
                        final dot = attachment.name.lastIndexOf('.');
                        await FileSaver.instance.saveFile(
                          name: dot > 0
                              ? attachment.name.substring(0, dot)
                              : attachment.name,
                          bytes: Uint8List.fromList(bytes),
                          fileExtension: dot > 0
                              ? attachment.name.substring(dot + 1)
                              : 'bin',
                          mimeType: MimeType.custom,
                          customMimeType: attachment.mimeType,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          showTheWeSnackBar(
                            context,
                            message: '첨부파일을 저장하지 못했습니다.',
                            type: TheWeSnackBarType.error,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
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
