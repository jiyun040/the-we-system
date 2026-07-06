part of 'approval_home_page.dart';

class _PortalNoticePanel extends StatelessWidget {
  const _PortalNoticePanel();

  static const _items = [
    _PortalNotice(
      category: '세무정보',
      title: '2026년 7월 세무일정 안내',
      date: '2026-06-26',
      body: '7월 원천세 신고, 부가세 예정 신고, 지급명세서 제출 일정을 확인해 주세요.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 변경사항 공지',
      date: '2026-06-26',
      body: '외부기관 연동센터 인증 방식이 갱신되었습니다. 전자결재 첨부 연동은 정상 이용 가능합니다.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 점검 일정',
      date: '2026-06-23',
      body: '정기 점검 시간에는 일부 문서 조회와 파일 첨부가 지연될 수 있습니다.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 작업 완료',
      date: '2026-06-23',
      body: '연동센터 작업이 완료되어 모든 전자결재 및 근태 메뉴를 정상 이용할 수 있습니다.',
    ),
  ];

  void _showDetail(BuildContext context, _PortalNotice notice) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${notice.category} · ${notice.date}',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 16),
            Text(notice.body, style: TheWeTextStyle.body),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공지사항', style: TheWeTextStyle.title),
            const SizedBox(height: 18),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => _showDetail(context, item),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.category}  ${item.title}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.body,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.date,
                                style: TheWeTextStyle.caption.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.category}  ${item.title}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.body,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.date,
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
          ],
        );
      },
    );
  }
}

class _PortalNotice {
  const _PortalNotice({
    required this.category,
    required this.title,
    required this.date,
    required this.body,
  });

  final String category;
  final String title;
  final String date;
  final String body;
}
