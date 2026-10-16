import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';
import '../../widgets/approval_notice_detail_dialog.dart';
import '../../widgets/approval_document_sheet_attachments.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'dart:convert';

class AdminNoticeManagement extends ConsumerWidget {
  const AdminNoticeManagement({super.key, required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.canManageNotices) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: adminSurface(),
        child: const Text('관리자 계정만 공지사항을 관리할 수 있습니다.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('공지사항 관리', style: TheWeTextStyle.title)),
            FilledButton.icon(
              key: const ValueKey('admin-notice-create-button'),
              onPressed: () => _showNoticeEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('공지 작성'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.notices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
            decoration: adminSurface(),
            alignment: Alignment.center,
            child: Text(
              '작성된 공지사항이 없습니다.',
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
            ),
          )
        else
          ...state.notices.map(
            (notice) => Padding(
              key: ValueKey('admin-notice-${notice.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: double.infinity,
                  decoration: adminSurface(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () =>
                        showApprovalNoticeDetailDialog(context, notice),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          if (notice.isPinned) ...[
                            const Icon(
                              Icons.push_pin_outlined,
                              color: TheWeColor.blue300,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (notice.isDraft) ...[
                            const Icon(
                              Icons.edit_note_outlined,
                              color: TheWeColor.blue300,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.title.isEmpty
                                      ? '(제목 없음)'
                                      : notice.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.subtitle,
                                ),
                                const SizedBox(height: 8),
                                if (notice.isDraft)
                                  Text(
                                    '임시저장 · ${_noticeDate(notice.draftExpiresAt ?? '')} 자동 폐기',
                                    style: TheWeTextStyle.caption.copyWith(
                                      color: TheWeColor.danger,
                                    ),
                                  ),
                                Text(
                                  notice.content.isEmpty
                                      ? '(내용 없음)'
                                      : notice.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.body,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${notice.authorName} · ${_noticeDate(notice.createdAt)} · 첨부 ${notice.attachments.length}개',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.caption.copyWith(
                                    color: TheWeColor.black500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: ValueKey('admin-notice-edit-${notice.id}'),
                            onPressed: () =>
                                _showNoticeEditor(context, ref, notice: notice),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: notice.isDraft ? '임시저장본 이어 쓰기' : '공지 수정',
                          ),
                          IconButton(
                            key: ValueKey('admin-notice-delete-${notice.id}'),
                            onPressed: () =>
                                _deleteNotice(context, ref, notice),
                            icon: const Icon(Icons.delete_outline),
                            color: TheWeColor.danger,
                            tooltip: notice.isDraft ? '임시저장본 삭제' : '공지 삭제',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showNoticeEditor(
    BuildContext context,
    WidgetRef ref, {
    PortalNotice? notice,
  }) async {
    final pageContext = context;
    final title = TextEditingController(text: notice?.title ?? '');
    final content = TextEditingController(text: notice?.content ?? '');
    var isPinned = notice?.isPinned ?? false;
    final attachments = <PortalNoticeAttachment>[...?notice?.attachments];
    var saving = false;
    var draggingFiles = false;
    var error = '';
    Future<void> addFiles(
      List<XFile> files,
      BuildContext dialogContext,
      void Function(void Function()) setDialogState,
    ) async {
      try {
        var total = attachments.fold<int>(0, (sum, item) => sum + item.size);
        for (final file in files) {
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty ||
              bytes.length > 10 * 1024 * 1024 ||
              total + bytes.length > 14 * 1024 * 1024 ||
              attachments.length >= 10) {
            if (dialogContext.mounted) {
              setDialogState(
                () => error = '첨부파일은 개별 10MB, 전체 14MB, 최대 10개까지 가능합니다.',
              );
            }
            return;
          }
          total += bytes.length;
          attachments.add(
            PortalNoticeAttachment(
              name: file.name,
              mimeType: file.mimeType ?? 'application/octet-stream',
              size: bytes.length,
              base64Data: base64Encode(bytes),
            ),
          );
        }
        if (dialogContext.mounted) setDialogState(() => error = '');
      } catch (_) {
        if (dialogContext.mounted) {
          setDialogState(() => error = '첨부파일을 읽지 못했습니다. 다시 선택해 주세요.');
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          key: const ValueKey('admin-notice-editor'),
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text(
            notice == null
                ? '공지 작성'
                : notice.isDraft
                ? '임시저장본 이어 쓰기'
                : '공지 수정',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const ValueKey('admin-notice-title-field'),
                    controller: title,
                    maxLength: 200,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('admin-notice-content-field'),
                    controller: content,
                    minLines: 6,
                    maxLines: 12,
                    decoration: const InputDecoration(labelText: '내용'),
                  ),
                  if (notice == null || notice.isDraft) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '임시저장본은 마지막 저장 후 7일 동안 보관되며, 이후 자동 폐기됩니다.',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropTarget(
                    key: const ValueKey('admin-notice-drop-target'),
                    onDragEntered: (_) =>
                        setDialogState(() => draggingFiles = true),
                    onDragExited: (_) =>
                        setDialogState(() => draggingFiles = false),
                    onDragDone: (details) async {
                      setDialogState(() => draggingFiles = false);
                      if (!saving) {
                        await addFiles(
                          details.files,
                          dialogContext,
                          setDialogState,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: draggingFiles
                            ? TheWeColor.blueSurface
                            : TheWeColor.white,
                        border: Border.all(
                          color: draggingFiles
                              ? TheWeColor.blue300
                              : TheWeColor.black300,
                          width: draggingFiles ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('admin-notice-add-attachment'),
                            onPressed: saving
                                ? null
                                : () async {
                                    final files = await openFiles();
                                    if (!dialogContext.mounted) return;
                                    await addFiles(
                                      files,
                                      dialogContext,
                                      setDialogState,
                                    );
                                  },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('이미지·파일 첨부'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            draggingFiles
                                ? '여기에 놓으면 파일이 첨부됩니다.'
                                : '파일을 이 영역으로 드래그해도 됩니다.',
                            style: TheWeTextStyle.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...attachments.asMap().entries.map(
                    (entry) => ListTile(
                      key: ValueKey('admin-notice-attachment-${entry.key}'),
                      dense: true,
                      onTap: () async {
                        try {
                          final attachment = entry.value;
                          final bytes = attachment.base64Data != null
                              ? base64Decode(attachment.base64Data!)
                              : await ref
                                    .read(theWeApiServiceProvider)
                                    .downloadNoticeAttachment(
                                      notice!.id,
                                      attachment.id!,
                                    );
                          if (!dialogContext.mounted) return;
                          await showApprovalAttachmentPreview(
                            dialogContext,
                            ApprovalAttachment.fromBytes(
                              name: attachment.name,
                              mimeType: attachment.mimeType,
                              bytes: bytes,
                            ),
                          );
                        } catch (_) {
                          if (dialogContext.mounted) {
                            setDialogState(() => error = '첨부파일을 열지 못했습니다.');
                          }
                        }
                      },
                      leading: Icon(
                        entry.value.mimeType.startsWith('image/')
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(
                        entry.value.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(entry.value.size / 1024).toStringAsFixed(1)}KB',
                      ),
                      trailing: IconButton(
                        key: ValueKey(
                          'admin-notice-remove-attachment-${entry.key}',
                        ),
                        tooltip: '첨부파일 제거',
                        onPressed: saving
                            ? null
                            : () => setDialogState(
                                () => attachments.removeAt(entry.key),
                              ),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    key: const ValueKey('admin-notice-pinned-field'),
                    contentPadding: EdgeInsets.zero,
                    value: isPinned,
                    onChanged: saving
                        ? null
                        : (value) =>
                              setDialogState(() => isPinned = value ?? false),
                    title: const Text('상단 고정'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (error.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error,
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            if (notice == null || notice.isDraft)
              OutlinedButton(
                key: const ValueKey('admin-notice-save-draft-button'),
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() {
                          saving = true;
                          error = '';
                        });
                        final message = await ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .saveNotice(
                              noticeId: notice?.id,
                              title: title.text,
                              content: content.text,
                              isPinned: isPinned,
                              isDraft: true,
                              attachments: attachments,
                            );
                        if (!dialogContext.mounted) return;
                        if (message != null) {
                          setDialogState(() {
                            saving = false;
                            error = message;
                          });
                          return;
                        }
                        Navigator.pop(dialogContext);
                        showTheWeSnackBar(
                          pageContext,
                          message: '임시저장했습니다. 7일 후 자동 폐기됩니다.',
                        );
                      },
                child: Text(saving ? '저장 중...' : '임시저장'),
              ),
            FilledButton(
              key: const ValueKey('admin-notice-save-button'),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        error = '';
                      });
                      final message = await ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .saveNotice(
                            noticeId: notice?.id,
                            title: title.text,
                            content: content.text,
                            isPinned: isPinned,
                            isDraft: false,
                            attachments: attachments,
                          );
                      if (!dialogContext.mounted) return;
                      if (message != null) {
                        setDialogState(() {
                          saving = false;
                          error = message;
                        });
                        return;
                      }
                      Navigator.pop(dialogContext);
                      showTheWeSnackBar(
                        pageContext,
                        message: notice == null
                            ? '공지사항을 작성했습니다.'
                            : '공지사항을 수정했습니다.',
                      );
                    },
              child: Text(
                saving
                    ? '저장 중...'
                    : notice?.isDraft == true
                    ? '공지 게시'
                    : '저장',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotice(
    BuildContext context,
    WidgetRef ref,
    PortalNotice notice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeConfirmDialog(
        title: notice.isDraft ? '임시저장본을 삭제할까요?' : '공지사항을 삭제할까요?',
        message:
            '‘${notice.title.isEmpty ? '(제목 없음)' : notice.title}’은 삭제하면 다시 복구할 수 없습니다.',
        primaryLabel: '삭제',
        secondaryLabel: '취소',
        primaryColor: TheWeColor.danger,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final message = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .deleteNotice(notice.id);
    if (!context.mounted) return;
    showTheWeSnackBar(
      context,
      message: message ?? '공지사항을 삭제했습니다.',
      type: message == null
          ? TheWeSnackBarType.success
          : TheWeSnackBarType.error,
    );
  }
}

String _noticeDate(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;
