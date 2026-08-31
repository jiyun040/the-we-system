import 'approval_absence_dependencies.dart';
import 'approval_absence_cards.dart';
import 'approval_absence_management.dart';
import 'approval_absence_month_widgets.dart';
import 'approval_absence_tables.dart';

class ApprovalLeavePromotionSection extends StatelessWidget {
  const ApprovalLeavePromotionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ApprovalAttendanceSectionCard(
      title: '연차촉진 현황',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ApprovalFeatureActionRow(
            actions: ['항목별 대상자 조회', '통지문 발송', '발송 이력 확인'],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '이름, 촉진구분을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ApprovalStatusMetricCard(
                title: '전체',
                value: '0명',
                caption: '촉진대상자',
                accent: TheWeColor.black900,
                width: 180,
              ),
              ApprovalStatusMetricCard(
                title: '매칭',
                value: '0명',
                caption: '진행중',
                accent: TheWeColor.black500,
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '1차 촉진',
                value: '0명',
                caption: '1차 진행',
                accent: TheWeColor.green,
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '미회송',
                value: '0명',
                caption: '응답대기',
                accent: Color(0xFF8B5CF6),
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '제출완료',
                value: '0명',
                caption: '문서 완료',
                accent: Color(0xFF10B981),
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '통보완료',
                value: '0명',
                caption: '알림 완료',
                accent: Color(0xFF22C55E),
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '확인완료',
                value: '0명',
                caption: '확인 처리',
                accent: TheWeColor.black500,
                width: 150,
              ),
              ApprovalStatusMetricCard(
                title: '무효불가',
                value: '0명',
                caption: '예외 대상',
                accent: TheWeColor.pink,
                width: 150,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ApprovalGenericTable(
            headers: const [
              ApprovalAttendanceTableHeader('상태', flex: 2),
              ApprovalAttendanceTableHeader('사원명', flex: 2),
              ApprovalAttendanceTableHeader('입사일', flex: 2),
              ApprovalAttendanceTableHeader('촉진구분', flex: 2),
              ApprovalAttendanceTableHeader('촉진연차', flex: 2),
              ApprovalAttendanceTableHeader('촉진기간', flex: 2),
              ApprovalAttendanceTableHeader('1차 촉진일시', flex: 2),
              ApprovalAttendanceTableHeader('제출기한', flex: 2),
              ApprovalAttendanceTableHeader('파일 수신일시', flex: 2),
              ApprovalAttendanceTableHeader('작성내역', flex: 2),
            ],
            rows: const [],
            emptyMessage: '촉진 대상자가 없습니다.',
          ),
        ],
      ),
    );
  }
}

class ApprovalRetiredLeaveSection extends StatelessWidget {
  const ApprovalRetiredLeaveSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ApprovalAttendanceSectionCard(
      title: '퇴사자 연차관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ApprovalFeatureActionRow(
            actions: ['퇴사자 연차정산', '연차 정산 조정', '연도별 퇴사자 관리'],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const search = TextField(
                decoration: InputDecoration(
                  hintText: '사번, 이름을 검색하세요.',
                  prefixIcon: Icon(Icons.search),
                ),
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('엑셀 다운로드'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(child: search),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('엑셀 다운로드'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ApprovalGenericTable(
            headers: const [
              ApprovalAttendanceTableHeader('사번', flex: 2),
              ApprovalAttendanceTableHeader('사원명', flex: 2),
              ApprovalAttendanceTableHeader('부서명', flex: 2),
              ApprovalAttendanceTableHeader('입사일', flex: 2),
              ApprovalAttendanceTableHeader('퇴사일', flex: 2),
              ApprovalAttendanceTableHeader('입사일 기준 연차수', flex: 2),
              ApprovalAttendanceTableHeader('회계연도 기준 연차수', flex: 2),
              ApprovalAttendanceTableHeader('사용 연차수', flex: 2),
              ApprovalAttendanceTableHeader('미사용 연차수', flex: 2),
            ],
            rows: const [
              [
                'R-110',
                '김호민',
                '회계',
                '2021-03-01',
                '2026-06-30',
                '15일',
                '15일',
                '12일',
                '3일',
              ],
              [
                'R-118',
                '조상훈',
                '세무',
                '2022-08-09',
                '2026-07-31',
                '14일',
                '15일',
                '10일',
                '4일',
              ],
            ],
          ),
        ],
      ),
    );
  }
}
