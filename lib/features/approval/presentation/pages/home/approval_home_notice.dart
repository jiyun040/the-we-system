import 'approval_home_dependencies.dart';
import '../../widgets/approval_notice_detail_dialog.dart';

class ApprovalHomeNoticePanel extends StatelessWidget {
  const ApprovalHomeNoticePanel({super.key, required this.notices});

  final List<PortalNotice> notices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('공지사항', style: TheWeTextStyle.title),
        const SizedBox(height: 18),
        if (notices.isEmpty)
          Text(
            '등록된 공지사항이 없습니다.',
            style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
          )
        else
          ...notices
              .take(5)
              .map(
                (notice) => Padding(
                  key: ValueKey('home-notice-${notice.id}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: notice.isPinned
                            ? TheWeColor.blueSurface
                            : TheWeColor.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TheWeColor.black300.withValues(alpha: .25),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            showApprovalNoticeDetailDialog(context, notice),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (notice.isPinned) ...[
                                    const Icon(
                                      Icons.push_pin_outlined,
                                      size: 16,
                                      color: TheWeColor.blue300,
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      notice.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TheWeTextStyle.subtitle,
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
                              const SizedBox(height: 7),
                              Text(
                                notice.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.body,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notice.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.caption.copyWith(
                                  color: TheWeColor.black500,
                                ),
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
}

String _noticeDate(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;
