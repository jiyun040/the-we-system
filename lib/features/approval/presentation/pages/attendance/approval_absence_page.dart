import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/layout.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

part 'approval_absence_shell.dart';
part 'approval_absence_my_status.dart';
part 'approval_absence_management.dart';
part 'approval_absence_leave_policy.dart';
part 'approval_absence_leave_status.dart';
part 'approval_absence_cards.dart';
part 'approval_absence_month_widgets.dart';
part 'approval_absence_tables.dart';
part 'approval_absence_company_table.dart';
part 'approval_absence_request_dialogs.dart';
part 'approval_absence_request_widgets.dart';
part 'approval_absence_seed.dart';

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

final attendanceControllerProvider =
    NotifierProvider<AttendanceController, Map<String, AttendanceSnapshot>>(
      AttendanceController.new,
    );

class AttendanceController extends Notifier<Map<String, AttendanceSnapshot>> {
  @override
  Map<String, AttendanceSnapshot> build() => _seedState;

  void clockIn(String userId) {
    final snapshot = state[userId] ?? _seedState.values.first;
    state = {
      ...state,
      userId: snapshot.copyWith(
        clockInTime: _formatTime(DateTime.now()),
        clearClockOutTime: true,
      ),
    };
  }

  void clockOut(String userId) {
    final snapshot = state[userId] ?? _seedState.values.first;
    state = {
      ...state,
      userId: snapshot.copyWith(clockOutTime: _formatTime(DateTime.now())),
    };
  }

  void addRequest(String userId, AttendanceRequestRecord request) {
    final snapshot = state[userId] ?? _seedState.values.first;
    state = {
      ...state,
      userId: snapshot.copyWith(requests: [request, ...snapshot.requests]),
    };
  }

  void addDelegation(String userId, AttendanceDelegation delegation) {
    final snapshot = state[userId] ?? _seedState.values.first;
    state = {
      ...state,
      userId: snapshot.copyWith(
        delegations: [delegation, ...snapshot.delegations],
      ),
    };
  }
}
