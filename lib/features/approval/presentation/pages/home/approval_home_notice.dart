import 'approval_home_dependencies.dart';

class ApprovalHomeNoticePanel extends StatefulWidget {
  const ApprovalHomeNoticePanel({super.key});

  @override
  State<ApprovalHomeNoticePanel> createState() => _PortalNoticePanelState();
}

class _PortalNoticePanelState extends State<ApprovalHomeNoticePanel> {
  static const _pageSize = 5;
  int page = 0;

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
    _PortalNotice(
      category: '인사 안내',
      title: '8월 휴가 신청 및 업무 인수인계 안내',
      date: '2026-06-20',
      body: '하계 휴가 신청 전 업무 인수인계 내용을 확인해 주세요.',
    ),
    _PortalNotice(
      category: '전자결재',
      title: '기업업무추진비 기안일 입력 방법 안내',
      date: '2026-06-18',
      body: '기업업무추진비 양식은 기안일을 직접 입력할 수 있습니다.',
    ),
    _PortalNotice(
      category: '보안 안내',
      title: 'OTP 인증번호 관리 주의',
      date: '2026-06-15',
      body: '관리자 전환에 사용하는 OTP 번호를 타인에게 공유하지 마세요.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '모바일 전자결재 화면 개선 안내',
      date: '2026-06-12',
      body: '모바일에서 결재 문서와 휴가 내역을 더 편리하게 확인할 수 있도록 개선했습니다.',
    ),
  ];

  void _showDetail(BuildContext context, _PortalNotice notice) {
    showDialog<void>(
      context: context,
      builder: (context) => TheWeModalSurface(
        maxWidth: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TheWeModalAlertIcon(
              icon: Icons.campaign_rounded,
              foregroundColor: TheWeColor.blue300,
              backgroundColor: TheWeColor.blueSurface,
            ),
            const SizedBox(height: 20),
            Text(
              notice.title,
              textAlign: TextAlign.center,
              style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${notice.category} · ${notice.date}',
              textAlign: TextAlign.center,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              notice.body,
              textAlign: TextAlign.center,
              style: TheWeTextStyle.body.copyWith(height: 1.7),
            ),
            const SizedBox(height: 22),
            TheWeModalActions(
              centered: true,
              primaryLabel: '확인',
              onPrimaryPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = (_items.length / _pageSize).ceil();
    final start = page * _pageSize;
    final visibleItems = _items.skip(start).take(_pageSize);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공지사항', style: TheWeTextStyle.title),
            const SizedBox(height: 18),
            ...visibleItems.map(
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
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const ValueKey('notice-page-previous'),
                  tooltip: '이전 공지',
                  onPressed: page > 0 ? () => setState(() => page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${page + 1} / $pageCount',
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
                IconButton(
                  key: const ValueKey('notice-page-next'),
                  tooltip: '다음 공지',
                  onPressed: page < pageCount - 1
                      ? () => setState(() => page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
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
