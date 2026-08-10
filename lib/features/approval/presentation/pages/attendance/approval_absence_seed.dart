import 'approval_absence_dependencies.dart';
import 'approval_absence_company_table.dart';
import 'approval_attendance_models.dart';

List<ApprovalCompanyAttendanceRowData> buildApprovalCompanyRows(
  List<EmployeeAccount> accounts,
  Map<String, AttendanceSnapshot> attendanceMap,
) {
  return accounts.map((account) {
    final snapshot =
        attendanceMap[account.id] ??
        approvalAttendanceSeedState[account.id] ??
        _emptyAttendanceSnapshot;
    final hasPendingOvertime = snapshot.requests.any(
      (item) => item.type.contains('초과근로') && item.status.contains('결재대기'),
    );
    final stateLabel = snapshot.lateCount > 0 ? '지각' : '정상';
    final anomalyLabel = hasPendingOvertime
        ? '미승인 초과근무'
        : snapshot.lateCount > 0
        ? '지각'
        : '정상';

    return ApprovalCompanyAttendanceRowData(
      account: account,
      snapshot: snapshot,
      stateLabel: stateLabel,
      anomalyLabel: anomalyLabel,
    );
  }).toList();
}

String formatApprovalTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatApprovalDate(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}

String formatApprovalKoreanDateTime(DateTime time) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '${time.year}년 $month월 $day일 (${weekdays[time.weekday - 1]}) $hour:$minute:$second';
}

const _emptyAttendanceSnapshot = AttendanceSnapshot(
  workPolicy: '기본그룹 (09:00 ~ 18:00)',
  clockInTime: null,
  clockOutTime: null,
  annualLeaveRemaining: 15,
  annualLeaveUsed: 0,
  lateCount: 0,
  overtimeHours: 0,
  weeklyWorkedHours: 0,
  weeklyRequiredHours: 40,
  remainingWorkDays: 5,
  requests: [],
  delegations: [],
);

final approvalAttendanceSeedState = <String, AttendanceSnapshot>{
  'edu_teacher': const AttendanceSnapshot(
    workPolicy: '기본그룹 (09:00 ~ 18:00)',
    clockInTime: '08:57',
    clockOutTime: null,
    annualLeaveRemaining: 10.5,
    annualLeaveUsed: 4.5,
    lateCount: 0,
    overtimeHours: 11,
    weeklyWorkedHours: 32,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [
      AttendanceRequestRecord(
        type: '초과근로 신청서',
        date: '2026-06-29',
        timeRange: '18:00 ~ 21:00',
        status: '결재대기',
        reason: '교육장 실습자료 정리 및 익일 교육 준비',
      ),
      AttendanceRequestRecord(
        type: '연차 신청',
        date: '2026-06-18',
        timeRange: '09:00 ~ 18:00',
        status: '승인완료',
        reason: '개인 일정',
      ),
    ],
    delegations: [
      AttendanceDelegation(
        period: '2026-06-28 ~ 2026-07-03',
        reason: '오지 출장',
        substituteName: '이재오 차장',
        status: '대결 승인 후 원결재자 확인 필요',
      ),
    ],
  ),
  'edu_manager': const AttendanceSnapshot(
    workPolicy: '기본그룹 (09:00 ~ 18:00)',
    clockInTime: '09:03',
    clockOutTime: null,
    annualLeaveRemaining: 12.0,
    annualLeaveUsed: 3.0,
    lateCount: 1,
    overtimeHours: 7,
    weeklyWorkedHours: 29,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [
      AttendanceRequestRecord(
        type: '근무시간 수정 신청서',
        date: '2026-06-11',
        timeRange: '1건 수정',
        status: '승인완료',
        reason: '병원 방문 후 출근',
      ),
    ],
    delegations: [],
  ),
  'lee_jaeo': const AttendanceSnapshot(
    workPolicy: '시차출퇴근 그룹',
    clockInTime: '08:32',
    clockOutTime: null,
    annualLeaveRemaining: 14.0,
    annualLeaveUsed: 2.0,
    lateCount: 0,
    overtimeHours: 6,
    weeklyWorkedHours: 34,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [],
    delegations: [],
  ),
  'kim_kyunyoung': const AttendanceSnapshot(
    workPolicy: '임원 근무제',
    clockInTime: '08:10',
    clockOutTime: null,
    annualLeaveRemaining: 15.0,
    annualLeaveUsed: 1.0,
    lateCount: 0,
    overtimeHours: 3,
    weeklyWorkedHours: 36,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [],
    delegations: [],
  ),
  'jiyun': const AttendanceSnapshot(
    workPolicy: '기본그룹 (09:00 ~ 18:00)',
    clockInTime: '09:00',
    clockOutTime: null,
    annualLeaveRemaining: 9.0,
    annualLeaveUsed: 6.0,
    lateCount: 2,
    overtimeHours: 13,
    weeklyWorkedHours: 28,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [],
    delegations: [],
  ),
  'han_dev': const AttendanceSnapshot(
    workPolicy: '선택 근무제',
    clockInTime: '10:02',
    clockOutTime: null,
    annualLeaveRemaining: 11.0,
    annualLeaveUsed: 5.0,
    lateCount: 0,
    overtimeHours: 18,
    weeklyWorkedHours: 31,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [],
    delegations: [],
  ),
};
