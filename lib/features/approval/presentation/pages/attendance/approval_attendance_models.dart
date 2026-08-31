enum AttendanceSection {
  myStatus,
  companyStatus,
  workGroup,
  compensatoryLeave,
  holidayReplacement,
  leavePolicy,
  leavePromotion,
  retiredLeave,
}

extension AttendanceSectionX on AttendanceSection {
  String get key => switch (this) {
    AttendanceSection.myStatus => 'my-status',
    AttendanceSection.companyStatus => 'company-status',
    AttendanceSection.workGroup => 'work-group',
    AttendanceSection.compensatoryLeave => 'compensatory-leave',
    AttendanceSection.holidayReplacement => 'holiday-replacement',
    AttendanceSection.leavePolicy => 'leave-policy',
    AttendanceSection.leavePromotion => 'leave-promotion',
    AttendanceSection.retiredLeave => 'retired-leave',
  };

  String get title => switch (this) {
    AttendanceSection.myStatus => '내 근태현황',
    AttendanceSection.companyStatus => '전사 근태현황',
    AttendanceSection.workGroup => '근무그룹 관리',
    AttendanceSection.compensatoryLeave => '보상휴가 관리',
    AttendanceSection.holidayReplacement => '휴일대체 관리',
    AttendanceSection.leavePolicy => '연차정책 관리',
    AttendanceSection.leavePromotion => '연차촉진 현황',
    AttendanceSection.retiredLeave => '퇴사자 연차관리',
  };

  bool get showsControlPanel => switch (this) {
    AttendanceSection.myStatus => true,
    AttendanceSection.companyStatus => false,
    AttendanceSection.workGroup ||
    AttendanceSection.compensatoryLeave ||
    AttendanceSection.holidayReplacement ||
    AttendanceSection.leavePolicy ||
    AttendanceSection.leavePromotion ||
    AttendanceSection.retiredLeave => false,
  };

  static AttendanceSection fromKey(String? value) {
    return AttendanceSection.values.firstWhere(
      (section) => section.key == value,
      orElse: () => AttendanceSection.myStatus,
    );
  }
}

enum AttendanceRequestKind { overtime, workTimeCorrection }

enum AttendanceView { weekly, monthly }

extension AttendanceViewX on AttendanceView {
  String get key => switch (this) {
    AttendanceView.weekly => 'weekly',
    AttendanceView.monthly => 'monthly',
  };

  static AttendanceView fromKey(String? value) {
    return AttendanceView.values.firstWhere(
      (item) => item.key == value,
      orElse: () => AttendanceView.weekly,
    );
  }
}

class AttendanceRequestRecord {
  const AttendanceRequestRecord({
    required this.type,
    required this.date,
    required this.timeRange,
    required this.status,
    required this.reason,
  });

  final String type;
  final String date;
  final String timeRange;
  final String status;
  final String reason;
}

class AttendanceDelegation {
  const AttendanceDelegation({
    required this.period,
    required this.reason,
    required this.substituteName,
    required this.status,
  });

  final String period;
  final String reason;
  final String substituteName;
  final String status;
}

class AttendanceSnapshot {
  const AttendanceSnapshot({
    required this.workPolicy,
    required this.clockInTime,
    required this.clockOutTime,
    required this.annualLeaveRemaining,
    required this.annualLeaveUsed,
    required this.lateCount,
    required this.overtimeHours,
    required this.weeklyWorkedHours,
    required this.weeklyRequiredHours,
    required this.remainingWorkDays,
    required this.requests,
    required this.delegations,
  });

  final String workPolicy;
  final String? clockInTime;
  final String? clockOutTime;
  final double annualLeaveRemaining;
  final double annualLeaveUsed;
  final int lateCount;
  final int overtimeHours;
  final double weeklyWorkedHours;
  final double weeklyRequiredHours;
  final int remainingWorkDays;
  final List<AttendanceRequestRecord> requests;
  final List<AttendanceDelegation> delegations;

  AttendanceSnapshot copyWith({
    String? workPolicy,
    String? clockInTime,
    bool clearClockInTime = false,
    String? clockOutTime,
    bool clearClockOutTime = false,
    double? annualLeaveRemaining,
    double? annualLeaveUsed,
    int? lateCount,
    int? overtimeHours,
    double? weeklyWorkedHours,
    double? weeklyRequiredHours,
    int? remainingWorkDays,
    List<AttendanceRequestRecord>? requests,
    List<AttendanceDelegation>? delegations,
  }) {
    return AttendanceSnapshot(
      workPolicy: workPolicy ?? this.workPolicy,
      clockInTime: clearClockInTime ? null : (clockInTime ?? this.clockInTime),
      clockOutTime: clearClockOutTime
          ? null
          : (clockOutTime ?? this.clockOutTime),
      annualLeaveRemaining: annualLeaveRemaining ?? this.annualLeaveRemaining,
      annualLeaveUsed: annualLeaveUsed ?? this.annualLeaveUsed,
      lateCount: lateCount ?? this.lateCount,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      weeklyWorkedHours: weeklyWorkedHours ?? this.weeklyWorkedHours,
      weeklyRequiredHours: weeklyRequiredHours ?? this.weeklyRequiredHours,
      remainingWorkDays: remainingWorkDays ?? this.remainingWorkDays,
      requests: requests ?? this.requests,
      delegations: delegations ?? this.delegations,
    );
  }

  bool get isClockedIn => clockInTime != null;
}
