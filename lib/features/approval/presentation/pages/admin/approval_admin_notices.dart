import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';
import '../../widgets/approval_notice_detail_dialog.dart';

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.subtitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notice.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.body,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${notice.authorName} · ${_noticeDate(notice.createdAt)}',
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
                            tooltip: '공지 수정',
                          ),
                          IconButton(
                            key: ValueKey('admin-notice-delete-${notice.id}'),
                            onPressed: () =>
                                _deleteNotice(context, ref, notice),
                            icon: const Icon(Icons.delete_outline),
                            color: TheWeColor.danger,
                            tooltip: '공지 삭제',
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
    var saving = false;
    var error = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          key: const ValueKey('admin-notice-editor'),
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text(notice == null ? '공지 작성' : '공지 수정'),
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
              child: Text(saving ? '저장 중...' : '저장'),
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
      builder: (context) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: Text('‘${notice.title}’ 공지사항을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
            child: const Text('삭제'),
          ),
        ],
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
