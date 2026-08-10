import 'dart:math' as math;

import 'approval_absence_dependencies.dart';
import 'approval_absence_cards.dart';
import 'approval_absence_company_table.dart';
import 'approval_absence_month_widgets.dart';
import 'approval_absence_seed.dart';
import 'approval_absence_tables.dart';
import 'approval_attendance_models.dart';

class ApprovalMyAttendanceSection extends StatelessWidget {
  const ApprovalMyAttendanceSection({
    super.key,
    required this.view,
    required this.user,
    required this.snapshot,
    required this.onChangeView,
    required this.onOpenRequest,
  });

  final AttendanceView view;
  final EmployeeAccount user;
  final AttendanceSnapshot snapshot;
  final ValueChanged<AttendanceView> onChangeView;
  final ValueChanged<AttendanceRequestKind> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final remainingHours = math.max(
      0,
      snapshot.weeklyRequiredHours - snapshot.weeklyWorkedHours,
    );
    final progress = snapshot.weeklyRequiredHours == 0
        ? 0.0
        : (snapshot.weeklyWorkedHours / snapshot.weeklyRequiredHours).clamp(
            0.0,
            1.0,
          );

    if (view == AttendanceView.monthly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApprovalAttendanceSectionCard(
            title: '내 근태현황',
            subtitle: null,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${now.year}년 ${now.month}월',
                      style: TheWeTextStyle.title,
                    ),
                    ApprovalModeToggle(
                      label: '주간',
                      selected: false,
                      onTap: () => onChangeView(AttendanceView.weekly),
                    ),
                    ApprovalModeToggle(
                      label: '월간',
                      selected: true,
                      onTap: () => onChangeView(AttendanceView.monthly),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ApprovalMonthAttendanceGrid(now: now),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ApprovalAttendanceSectionCard(
            title: '승인요청내역',
            subtitle: null,
            child: ApprovalRequestTable(requests: snapshot.requests),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApprovalAttendanceSectionCard(
          title: '내 근태현황',
          subtitle: null,
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${formatApprovalDate(weekStart)} ~ ${formatApprovalDate(weekEnd)}',
                    style: TheWeTextStyle.title,
                  ),
                  ApprovalModeToggle(
                    label: '주간',
                    selected: true,
                    onTap: () => onChangeView(AttendanceView.weekly),
                  ),
                  ApprovalModeToggle(
                    label: '월간',
                    selected: false,
                    onTap: () => onChangeView(AttendanceView.monthly),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 900;
                  final summary = ApprovalAttendanceSurfaceCard(
                    color: const Color(0xFFF8FCFE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주간누적 ${snapshot.weeklyWorkedHours.toStringAsFixed(1)}시간',
                          style: TheWeTextStyle.title.copyWith(
                            color: TheWeColor.blue300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: TheWeColor.blue100,
                            color: TheWeColor.blue300,
                          ),
                        ),
                      ],
                    ),
                  );
                  final stats = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ApprovalMetricTile(
                        label: '잔여 근무일',
                        value: '${snapshot.remainingWorkDays}일/5일',
                        accent: TheWeColor.green,
                      ),
                      ApprovalMetricTile(
                        label: '잔여 근로시간',
                        value: '${remainingHours.toStringAsFixed(1)}h',
                        accent: TheWeColor.blue300,
                      ),
                      ApprovalMetricTile(
                        label: '총 근로시간',
                        value: snapshot.clockOutTime == null
                            ? '0h 00m'
                            : '8h 00m',
                        accent: TheWeColor.black900,
                      ),
                      ApprovalMetricTile(
                        label: '휴가',
                        value:
                            '${snapshot.annualLeaveUsed.toStringAsFixed(1)}일',
                        accent: TheWeColor.pink,
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      children: [summary, const SizedBox(height: 14), stats],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: summary),
                      const SizedBox(width: 14),
                      Expanded(flex: 7, child: stats),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ApprovalAttendanceSectionCard(
          title: '주간 근무 타임라인',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ApprovalMetricTile(
                    label: '근무시작',
                    value: snapshot.clockInTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  ApprovalMetricTile(
                    label: '근무종료',
                    value: snapshot.clockOutTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  ApprovalMetricTile(
                    label: '총 근로시간',
                    value: snapshot.clockOutTime == null
                        ? '0h 0m 0s'
                        : '8h 0m 0s',
                    accent: TheWeColor.blue300,
                  ),
                  ApprovalMetricTile(
                    label: '승인요청내역',
                    value: '${snapshot.requests.length}건',
                    accent: TheWeColor.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ApprovalWeekStrip(now: now),
              const SizedBox(height: 16),
              ApprovalTimelineChart(
                clockInTime: snapshot.clockInTime,
                clockOutTime: snapshot.clockOutTime,
                requestCount: snapshot.requests.length,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ApprovalLegendDot(
                    label: '정상',
                    color: const Color(0xFF9CA3AF),
                  ),
                  ApprovalLegendDot(label: '근태이상', color: TheWeColor.pink),
                  ApprovalLegendDot(
                    label: '수정',
                    color: const Color(0xFF8B5CF6),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        onOpenRequest(AttendanceRequestKind.workTimeCorrection),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: Text(
                      '근무시간 수정 신청',
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.blue300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ApprovalAttendanceSectionCard(
          title: '승인요청내역',
          subtitle: null,
          child: ApprovalRequestTable(requests: snapshot.requests),
        ),
        const SizedBox(height: 18),
        ApprovalAttendanceSectionCard(
          title: '근무상태 변경 이력',
          subtitle: null,
          child: snapshot.delegations.isEmpty
              ? Text(
                  '등록된 근무상태 변경 이력이 없습니다.',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                )
              : Column(
                  children: snapshot.delegations
                      .map((item) => ApprovalDelegationItem(item: item))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
