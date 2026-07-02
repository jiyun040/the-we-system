import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

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

class ApprovalAbsencePage extends ConsumerWidget {
  const ApprovalAbsencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = GoRouterState.of(context);
    final section = AttendanceSectionX.fromKey(
      routeState.uri.queryParameters['section'],
    );
    final view = AttendanceViewX.fromKey(
      routeState.uri.queryParameters['view'],
    );
    final appState = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: appState.when(
        data: (value) {
          final user = value.currentUser;
          if (user == null) {
            return const SizedBox.shrink();
          }

          final attendanceMap = ref.watch(attendanceControllerProvider);
          final snapshot = attendanceMap[user.id] ?? _seedState[user.id]!;
          final companyRows = _buildCompanyRows(value.accounts, attendanceMap);

          return Row(
            children: [
              SideBar(
                frequentForms: value.dashboard.frequentForms,
                pendingDocument: value.dashboard.pendingCount,
                receiveDocument: value.dashboard.receivedCount,
                openPendingDocument: value.dashboard.referenceCount,
                scheduledDocument: value.dashboard.scheduledCount,
              ),
              VerticalDivider(
                width: 1,
                color: TheWeColor.black300.withValues(alpha: 0.32),
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                    child: Column(
                      children: [
                        _PageHeader(section: section),
                        const SizedBox(height: 18),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 1180;
                              final controlPanel = _AttendanceControlPanel(
                                user: user,
                                snapshot: snapshot,
                                currentSection: section,
                                currentView: view,
                                onNavigate: (nextSection) => _goToSection(
                                  context,
                                  nextSection,
                                  currentView: view,
                                ),
                                onClockIn: () => ref
                                    .read(attendanceControllerProvider.notifier)
                                    .clockIn(user.id),
                                onClockOut: () => ref
                                    .read(attendanceControllerProvider.notifier)
                                    .clockOut(user.id),
                                onOpenRequest: (kind) => _openRequestDialog(
                                  context,
                                  ref,
                                  user,
                                  kind,
                                ),
                              );
                              final content = _AttendanceSectionContent(
                                section: section,
                                view: view,
                                user: user,
                                snapshot: snapshot,
                                accounts: value.accounts,
                                companyRows: companyRows,
                                onChangeView: (nextView) => _goToSection(
                                  context,
                                  section,
                                  currentView: nextView,
                                ),
                                onOpenRequest: (kind) => _openRequestDialog(
                                  context,
                                  ref,
                                  user,
                                  kind,
                                ),
                              );

                              if (!section.showsControlPanel) {
                                return SingleChildScrollView(child: content);
                              }

                              if (stacked) {
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      controlPanel,
                                      const SizedBox(height: 16),
                                      content,
                                    ],
                                  ),
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 290,
                                    child: SingleChildScrollView(
                                      child: controlPanel,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: content,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Text('근태 화면을 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: TheWeColor.blue300)),
      ),
    );
  }

  static void _goToSection(
    BuildContext context,
    AttendanceSection section, {
    AttendanceView currentView = AttendanceView.weekly,
  }) {
    context.goNamed(
      AppRouteName.absence,
      queryParameters: {
        'section': section.key,
        if (section == AttendanceSection.myStatus) 'view': currentView.key,
      },
    );
  }

  static Future<void> _openRequestDialog(
    BuildContext context,
    WidgetRef ref,
    EmployeeAccount user,
    AttendanceRequestKind kind,
  ) async {
    final request = await showDialog<AttendanceRequestRecord>(
      context: context,
      builder: (context) => switch (kind) {
        AttendanceRequestKind.overtime => const _OvertimeRequestDialog(),
        AttendanceRequestKind.workTimeCorrection =>
          const _WorkTimeCorrectionDialog(),
      },
    );
    if (request == null) {
      return;
    }

    ref
        .read(attendanceControllerProvider.notifier)
        .addRequest(user.id, request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.type} 전자결재 상신이 등록되었습니다.')),
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.section});

  final AttendanceSection section;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(section.title, style: TheWeTextStyle.pageTitle),
    );
  }
}

class _AttendanceControlPanel extends StatelessWidget {
  const _AttendanceControlPanel({
    required this.user,
    required this.snapshot,
    required this.currentSection,
    required this.currentView,
    required this.onNavigate,
    required this.onClockIn,
    required this.onClockOut,
    required this.onOpenRequest,
  });

  final EmployeeAccount user;
  final AttendanceSnapshot snapshot;
  final AttendanceSection currentSection;
  final AttendanceView currentView;
  final ValueChanged<AttendanceSection> onNavigate;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final ValueChanged<AttendanceRequestKind> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final remainingHours = math.max(
      0,
      snapshot.weeklyRequiredHours - snapshot.weeklyWorkedHours,
    );

    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('근태', style: TheWeTextStyle.pageTitle),
          const SizedBox(height: 16),
          PopupMenuButton<AttendanceRequestKind>(
            onSelected: onOpenRequest,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AttendanceRequestKind.overtime,
                child: Text('초과근로 신청서'),
              ),
              PopupMenuItem(
                value: AttendanceRequestKind.workTimeCorrection,
                child: Text('근무시간 수정 신청서'),
              ),
            ],
            child: Container(
              width: double.infinity,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TheWeColor.black300),
              ),
              child: Row(
                children: [
                  Text('신청서 작성', style: TheWeTextStyle.subtitle),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _formatKoreanDateTime(DateTime.now()),
            style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  (snapshot.isClockedIn
                          ? TheWeColor.green
                          : TheWeColor.black500)
                      .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              snapshot.isClockedIn ? '근무중' : '출근전',
              style: TheWeTextStyle.caption.copyWith(
                color: snapshot.isClockedIn
                    ? TheWeColor.green
                    : TheWeColor.black500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PrimaryStatusBox(
                  label: '출근 시간',
                  value: snapshot.clockInTime ?? '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryStatusBox(
                  label: '퇴근 시간',
                  value: snapshot.clockOutTime ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: snapshot.isClockedIn ? null : onClockIn,
                  child: const Text('출근하기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: snapshot.isClockedIn ? onClockOut : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: TheWeColor.black900,
                  ),
                  child: const Text('퇴근하기'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) {
                final title = snapshot.isClockedIn ? '근무상태 변경' : '근태체크 불가';
                final message = snapshot.isClockedIn
                    ? '근무상태 변경은 전자결재 상신 후 반영됩니다.'
                    : '출근시간이 체크되지 않았습니다.';
                return AlertDialog(
                  backgroundColor: TheWeColor.white,
                  surfaceTintColor: TheWeColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Text(title, style: TheWeTextStyle.title),
                  content: Text(message, style: TheWeTextStyle.body),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: TheWeColor.blue300,
                      ),
                      child: const Text('확인'),
                    ),
                  ],
                );
              },
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('근무상태변경'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: TheWeColor.black300.withValues(alpha: 0.24)),
          const SizedBox(height: 14),
          Text('빠른 현황', style: TheWeTextStyle.section),
          const SizedBox(height: 10),
          _QuickMetric(
            label: '기본그룹',
            value: snapshot.workPolicy,
            accent: TheWeColor.blue300,
          ),
          _QuickMetric(
            label: '주간 누적',
            value:
                '${(currentView == AttendanceView.weekly ? snapshot.weeklyWorkedHours : snapshot.weeklyWorkedHours * 4).toStringAsFixed(1)}h',
            accent: TheWeColor.green,
          ),
          _QuickMetric(
            label: '잔여 근로시간',
            value: '${remainingHours.toStringAsFixed(1)}h',
            accent: TheWeColor.black900,
          ),
          _QuickMetric(
            label: '잔여 근무일',
            value: '${snapshot.remainingWorkDays}일',
            accent: TheWeColor.blue300,
          ),
          const SizedBox(height: 18),
          Text('바로가기', style: TheWeTextStyle.section),
          const SizedBox(height: 8),
          ...[
            AttendanceSection.myStatus,
            AttendanceSection.companyStatus,
            AttendanceSection.workGroup,
            AttendanceSection.leavePolicy,
          ].map(
            (section) => _QuickLinkTile(
              label: section.title,
              selected: currentSection == section,
              onTap: () => onNavigate(section),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSectionContent extends StatelessWidget {
  const _AttendanceSectionContent({
    required this.section,
    required this.view,
    required this.user,
    required this.snapshot,
    required this.accounts,
    required this.companyRows,
    required this.onChangeView,
    required this.onOpenRequest,
  });

  final AttendanceSection section;
  final AttendanceView view;
  final EmployeeAccount user;
  final AttendanceSnapshot snapshot;
  final List<EmployeeAccount> accounts;
  final List<_CompanyAttendanceRowData> companyRows;
  final ValueChanged<AttendanceView> onChangeView;
  final ValueChanged<AttendanceRequestKind> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      AttendanceSection.myStatus => _MyAttendanceSection(
        view: view,
        user: user,
        snapshot: snapshot,
        onChangeView: onChangeView,
        onOpenRequest: onOpenRequest,
      ),
      AttendanceSection.companyStatus => _CompanyAttendanceSection(
        rows: companyRows,
      ),
      AttendanceSection.workGroup => const _WorkGroupManagementSection(),
      AttendanceSection.compensatoryLeave => const _CompensatoryLeaveSection(),
      AttendanceSection.holidayReplacement =>
        const _HolidayReplacementSection(),
      AttendanceSection.leavePolicy => _LeavePolicySection(accounts: accounts),
      AttendanceSection.leavePromotion => const _LeavePromotionSection(),
      AttendanceSection.retiredLeave => const _RetiredLeaveSection(),
    };
  }
}

class _MyAttendanceSection extends StatelessWidget {
  const _MyAttendanceSection({
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
          _SectionCard(
            title: '내 근태현황',
            subtitle: null,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${now.year}년 ${now.month}월',
                      style: TheWeTextStyle.pageTitle,
                    ),
                    const Spacer(),
                    _ModeToggle(
                      label: '주간',
                      selected: false,
                      onTap: () => onChangeView(AttendanceView.weekly),
                    ),
                    const SizedBox(width: 8),
                    _ModeToggle(
                      label: '월간',
                      selected: true,
                      onTap: () => onChangeView(AttendanceView.monthly),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MonthAttendanceGrid(now: now),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: '승인요청내역',
            subtitle: null,
            child: _RequestTable(requests: snapshot.requests),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: '내 근태현황',
          subtitle: null,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${_formatDate(weekStart)} ~ ${_formatDate(weekEnd)}',
                    style: TheWeTextStyle.title,
                  ),
                  const Spacer(),
                  _ModeToggle(
                    label: '주간',
                    selected: true,
                    onTap: () => onChangeView(AttendanceView.weekly),
                  ),
                  const SizedBox(width: 8),
                  _ModeToggle(
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
                  final summary = _SurfaceCard(
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
                      _MetricTile(
                        label: '잔여 근무일',
                        value: '${snapshot.remainingWorkDays}일/5일',
                        accent: TheWeColor.green,
                      ),
                      _MetricTile(
                        label: '잔여 근로시간',
                        value: '${remainingHours.toStringAsFixed(1)}h',
                        accent: TheWeColor.blue300,
                      ),
                      _MetricTile(
                        label: '총 근로시간',
                        value: snapshot.clockOutTime == null
                            ? '0h 00m'
                            : '8h 00m',
                        accent: TheWeColor.black900,
                      ),
                      _MetricTile(
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
        _SectionCard(
          title: '주간 근무 타임라인',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    label: '근무시작',
                    value: snapshot.clockInTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  _MetricTile(
                    label: '근무종료',
                    value: snapshot.clockOutTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  _MetricTile(
                    label: '총 근로시간',
                    value: snapshot.clockOutTime == null
                        ? '0h 0m 0s'
                        : '8h 0m 0s',
                    accent: TheWeColor.blue300,
                  ),
                  _MetricTile(
                    label: '승인요청내역',
                    value: '${snapshot.requests.length}건',
                    accent: TheWeColor.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WeekStrip(now: now),
              const SizedBox(height: 16),
              _TimelineChart(
                clockInTime: snapshot.clockInTime,
                clockOutTime: snapshot.clockOutTime,
                requestCount: snapshot.requests.length,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _LegendDot(label: '정상', color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 12),
                  _LegendDot(label: '근태이상', color: TheWeColor.pink),
                  const SizedBox(width: 12),
                  _LegendDot(label: '수정', color: const Color(0xFF8B5CF6)),
                  const Spacer(),
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
        _SectionCard(
          title: '승인요청내역',
          subtitle: null,
          child: _RequestTable(requests: snapshot.requests),
        ),
        const SizedBox(height: 18),
        _SectionCard(
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
                      .map((item) => _DelegationItem(item: item))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _CompanyAttendanceSection extends StatefulWidget {
  const _CompanyAttendanceSection({required this.rows});

  final List<_CompanyAttendanceRowData> rows;

  @override
  State<_CompanyAttendanceSection> createState() =>
      _CompanyAttendanceSectionState();
}

class _CompanyAttendanceSectionState extends State<_CompanyAttendanceSection> {
  DateTime _focusedDate = DateTime(2026, 6, 29);
  bool _periodMode = false;

  void _moveDate(int direction) {
    setState(() {
      _focusedDate = _periodMode
          ? DateTime(_focusedDate.year, _focusedDate.month + direction)
          : _focusedDate.add(Duration(days: direction));
    });
  }

  String get _dateLabel {
    if (_periodMode) {
      final firstDay = DateTime(_focusedDate.year, _focusedDate.month);
      final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
      return '${_formatDate(firstDay)} ~ ${_formatDate(lastDay)}';
    }

    return _formatDate(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    final normalCount = widget.rows
        .where((row) => row.stateLabel == '정상')
        .length;
    final lateCount = widget.rows.where((row) => row.stateLabel == '지각').length;
    final pendingOvertimeCount = widget.rows
        .where((row) => row.anomalyLabel == '미승인 초과근무')
        .length;
    final missingClockOutCount = widget.rows
        .where(
          (row) =>
              row.snapshot.clockInTime != null &&
              row.snapshot.clockOutTime == null,
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: '전사 근태현황',
          subtitle: null,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _moveDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  Text(_dateLabel, style: TheWeTextStyle.pageTitle),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _moveDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const Spacer(),
                  _ModeToggle(
                    label: '일자별',
                    selected: !_periodMode,
                    onTap: () => setState(() => _periodMode = false),
                  ),
                  const SizedBox(width: 8),
                  _ModeToggle(
                    label: '기간별',
                    selected: _periodMode,
                    onTap: () => setState(() => _periodMode = true),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 860 ? 2 : 4;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.65,
                    children: [
                      _StatusMetricCard(
                        title: '정상',
                        value: '$normalCount명',
                        caption: '전체 ${widget.rows.length}명 기준',
                        accent: TheWeColor.green,
                      ),
                      _StatusMetricCard(
                        title: '지각',
                        value: '$lateCount명',
                        caption: '시간 및 기록 이상',
                        accent: TheWeColor.pink,
                      ),
                      _StatusMetricCard(
                        title: '조퇴',
                        value: '0명',
                        caption: '현재 집계 없음',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '휴게시간 부족',
                        value: '0명',
                        caption: '정상 기준 충족',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '종일근무상태',
                        value:
                            '${widget.rows.where((row) => row.snapshot.isClockedIn).length}명',
                        caption: '근무중 직원',
                        accent: TheWeColor.black900,
                      ),
                      _StatusMetricCard(
                        title: '휴가 중 출근',
                        value: '0명',
                        caption: '이상 케이스',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '퇴근 누락',
                        value: '$missingClockOutCount명',
                        caption: '퇴근 미체크',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '미승인 초과근무',
                        value: '$pendingOvertimeCount명',
                        caption: '결재 대기',
                        accent: TheWeColor.pink,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '직원 목록',
          subtitle: null,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: '재직',
                      items: const [
                        DropdownMenuItem(value: '재직', child: Text('재직')),
                        DropdownMenuItem(value: '휴직', child: Text('휴직')),
                        DropdownMenuItem(value: '퇴사', child: Text('퇴사')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '부서, 사번, 이름을 검색하세요.',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('엑셀 다운로드'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CompanyAttendanceTable(rows: widget.rows),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkGroupManagementSection extends StatefulWidget {
  const _WorkGroupManagementSection();

  @override
  State<_WorkGroupManagementSection> createState() =>
      _WorkGroupManagementSectionState();
}

class _WorkGroupManagementSectionState
    extends State<_WorkGroupManagementSection> {
  final List<_ManagementGroupCardData> _cards = const [
    _ManagementGroupCardData(
      badge: '기본',
      title: '기본그룹',
      rows: [
        '근로시간  09:00 ~ 18:00 (8h)',
        '근무요일  월, 화, 수, 목, 금',
        '주휴일  일',
        '근무지  웹 서비스',
        '적용멤버  9명',
      ],
    ),
    _ManagementGroupCardData(
      badge: '고정근로',
      title: '시차출퇴근 그룹',
      rows: [
        '근로시간  08:00 ~ 17:00 (8h)',
        '근무요일  월, 화, 수, 목, 금',
        '주휴일  일',
        '근무지  사내 근무',
        '적용멤버  2명',
      ],
    ),
  ].toList();

  Future<void> _addGroup() async {
    final nameController = TextEditingController(
      text: '신규 근무그룹 ${_cards.length + 1}',
    );
    final timeController = TextEditingController(text: '10:00 ~ 19:00 (8h)');

    final result = await showDialog<_ManagementGroupCardData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무그룹 추가'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '근무그룹명'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: '근로시간'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final title = nameController.text.trim().isEmpty
                  ? '신규 근무그룹 ${_cards.length + 1}'
                  : nameController.text.trim();
              final time = timeController.text.trim().isEmpty
                  ? '10:00 ~ 19:00 (8h)'
                  : timeController.text.trim();
              Navigator.of(context).pop(
                _ManagementGroupCardData(
                  badge: '신규',
                  title: title,
                  rows: [
                    '근로시간  $time',
                    '근무요일  월, 화, 수, 목, 금',
                    '주휴일  일',
                    '근무지  웹 서비스',
                    '적용멤버  0명',
                  ],
                ),
              );
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    nameController.dispose();
    timeController.dispose();

    if (result == null) {
      return;
    }

    setState(() => _cards.add(result));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: '근무그룹 관리',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final singleColumn = constraints.maxWidth < 980;
              final widgets = [
                ..._cards.map((card) => _ManagementGroupCard(data: card)),
                _AddManagementCard(title: '근무그룹 추가하기', onTap: _addGroup),
              ];

              if (singleColumn) {
                return Column(
                  children:
                      widgets
                          .expand(
                            (widget) => [widget, const SizedBox(height: 12)],
                          )
                          .toList()
                        ..removeLast(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < widgets.length; index++) ...[
                    Expanded(child: widgets[index]),
                    if (index != widgets.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompensatoryLeaveSection extends StatefulWidget {
  const _CompensatoryLeaveSection();

  @override
  State<_CompensatoryLeaveSection> createState() =>
      _CompensatoryLeaveSectionState();
}

class _CompensatoryLeaveSectionState extends State<_CompensatoryLeaveSection> {
  bool _showGrantTarget = true;

  @override
  Widget build(BuildContext context) {
    final headers = _showGrantTarget
        ? const [
            _TableHeader('사번', flex: 2),
            _TableHeader('사원명', flex: 2),
            _TableHeader('부서명', flex: 2),
            _TableHeader('근무그룹', flex: 2),
            _TableHeader('총 초과근로', flex: 2),
            _TableHeader('부여가능시간', flex: 2),
            _TableHeader('부여시간', flex: 2),
            _TableHeader('수당지급', flex: 2),
          ]
        : const [
            _TableHeader('부여일', flex: 2),
            _TableHeader('사원명', flex: 2),
            _TableHeader('부서명', flex: 2),
            _TableHeader('부여시간', flex: 2),
            _TableHeader('사용기한', flex: 2),
            _TableHeader('상태', flex: 2),
            _TableHeader('처리자', flex: 2),
          ];
    final rows = _showGrantTarget
        ? const [
            ['A-204', '김현정', '교육', '기본그룹', '12h', '8h', '4h', '대기'],
            ['A-318', '이재오', '영업', '시차출퇴근', '7h', '5h', '2h', '완료'],
          ]
        : const [
            ['2026-06-20', '김현정', '교육', '4h', '2026-12-31', '부여완료', '관리자'],
            ['2026-06-18', '이재오', '영업', '2h', '2026-12-31', '수당지급', '관리자'],
          ];

    return _SectionCard(
      title: '보상휴가 관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureActionRow(actions: ['보상휴가 부여', '수당지급 취소', '사용기한 변경']),
          const SizedBox(height: 16),
          Row(
            children: [
              _TabPill(
                label: '부여 대상',
                selected: _showGrantTarget,
                onTap: () => setState(() => _showGrantTarget = true),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: '부여 내역',
                selected: !_showGrantTarget,
                onTap: () => setState(() => _showGrantTarget = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '부서, 사번, 이름을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('엑셀 다운로드'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(headers: headers, rows: rows),
        ],
      ),
    );
  }
}

class _FeatureActionRow extends StatelessWidget {
  const _FeatureActionRow({required this.actions, this.onAction});

  final List<String> actions;
  final ValueChanged<String>? onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: actions
          .map(
            (action) => FilledButton.icon(
              onPressed: () => onAction?.call(action),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: TheWeColor.blue300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
              label: Text(action),
            ),
          )
          .toList(),
    );
  }
}

class _HolidayReplacementSection extends StatefulWidget {
  const _HolidayReplacementSection();

  @override
  State<_HolidayReplacementSection> createState() =>
      _HolidayReplacementSectionState();
}

class _HolidayReplacementSectionState
    extends State<_HolidayReplacementSection> {
  final List<List<String>> _rows = [
    [
      '승인대기',
      '김효민',
      'M-002',
      '회계',
      '기본그룹',
      '2026-06-06',
      '2026-06-08',
      '전사 행사 대응',
    ],
    ['완료', '한지운', 'D-014', '개발', '선택근무', '2026-06-13', '2026-06-15', '시스템 점검'],
  ];

  Future<void> _registerReplacement() async {
    final nameController = TextEditingController(text: '신규직원');
    final holidayController = TextEditingController(text: '2026-06-29');
    final replacementController = TextEditingController(text: '2026-06-30');
    final reasonController = TextEditingController(text: '휴일 근무 대체');

    final row = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴일대체 등록'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '사원명'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holidayController,
                decoration: const InputDecoration(labelText: '선택 휴일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replacementController,
                decoration: const InputDecoration(labelText: '대체일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: '신청사유'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop([
              '승인대기',
              nameController.text.trim().isEmpty
                  ? '신규직원'
                  : nameController.text.trim(),
              'NEW',
              '공유',
              '기본그룹',
              holidayController.text.trim().isEmpty
                  ? '2026-06-29'
                  : holidayController.text.trim(),
              replacementController.text.trim().isEmpty
                  ? '2026-06-30'
                  : replacementController.text.trim(),
              reasonController.text.trim().isEmpty
                  ? '휴일 근무 대체'
                  : reasonController.text.trim(),
            ]),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    nameController.dispose();
    holidayController.dispose();
    replacementController.dispose();
    reasonController.dispose();

    if (row == null) {
      return;
    }

    setState(() => _rows.insert(0, row));
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '휴일대체 관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureActionRow(
            actions: const ['휴일대체 등록', '휴일대체일 변경', '임직원 신청현황'],
            onAction: (action) {
              if (action == '휴일대체 등록') {
                _registerReplacement();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '부서, 사번, 이름을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _registerReplacement,
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: TheWeColor.blue300,
                ),
                label: const Text('휴일대체 등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(
            headers: const [
              _TableHeader('상태', flex: 2),
              _TableHeader('사원명', flex: 2),
              _TableHeader('사번', flex: 2),
              _TableHeader('부서', flex: 2),
              _TableHeader('근무그룹명', flex: 2),
              _TableHeader('선택 휴일', flex: 2),
              _TableHeader('대체일', flex: 2),
              _TableHeader('신청사유', flex: 3),
            ],
            rows: _rows,
          ),
        ],
      ),
    );
  }
}

class _LeavePolicySection extends StatelessWidget {
  const _LeavePolicySection({required this.accounts});

  final List<EmployeeAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _LeavePolicyCardData(
        id: 'default',
        badge: '기본 정책',
        title: '기본 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '연차 초과 사용 불가'],
        defaultDepartment: '회계',
      ),
      _LeavePolicyCardData(
        id: 'exception',
        badge: '예외 정책',
        title: '연차 미발생 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '연차 초과 사용 불가'],
        defaultDepartment: '교육',
      ),
      _LeavePolicyCardData(
        id: 'limited',
        badge: '제한 정책',
        title: '휴가 제한 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '특정 기간 제한 적용'],
        defaultDepartment: '개발',
      ),
    ];

    return _SectionCard(
      title: '연차정책 관리',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 980;
          final widgets = cards
              .map(
                (card) => _LeavePolicyGroupCard(data: card, accounts: accounts),
              )
              .toList();

          if (singleColumn) {
            return Column(
              children: [
                for (var index = 0; index < widgets.length; index++) ...[
                  widgets[index],
                  if (index != widgets.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < widgets.length; index++) ...[
                Expanded(child: widgets[index]),
                if (index != widgets.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LeavePolicyCardData {
  const _LeavePolicyCardData({
    required this.id,
    required this.badge,
    required this.title,
    required this.lines,
    required this.defaultDepartment,
  });

  final String id;
  final String badge;
  final String title;
  final List<String> lines;
  final String defaultDepartment;
}

class _LeavePolicyGroupCard extends StatefulWidget {
  const _LeavePolicyGroupCard({required this.data, required this.accounts});

  final _LeavePolicyCardData data;
  final List<EmployeeAccount> accounts;

  @override
  State<_LeavePolicyGroupCard> createState() => _LeavePolicyGroupCardState();
}

class _LeavePolicyGroupCardState extends State<_LeavePolicyGroupCard> {
  late List<EmployeeAccount> _selectedAccounts;

  @override
  void initState() {
    super.initState();
    _selectedAccounts = widget.accounts
        .where((item) => item.department == widget.data.defaultDepartment)
        .take(3)
        .toList();
  }

  Future<void> _openPicker() async {
    final result = await showDialog<List<EmployeeAccount>>(
      context: context,
      builder: (context) => _LeavePolicyMemberDialog(
        accounts: widget.accounts,
        initialSelected: _selectedAccounts,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedAccounts = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TheWeColor.blue100.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(widget.data.badge, style: TheWeTextStyle.caption),
          ),
          const SizedBox(height: 18),
          Text(widget.data.title, style: TheWeTextStyle.title),
          const SizedBox(height: 14),
          ...widget.data.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TheWeColor.black300.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: TheWeColor.blue300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '적용 인원',
                      style: TheWeTextStyle.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_selectedAccounts.length}명',
                    style: TheWeTextStyle.subtitle.copyWith(
                      color: TheWeColor.blue300,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: TheWeColor.black500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeavePolicyMemberDialog extends StatefulWidget {
  const _LeavePolicyMemberDialog({
    required this.accounts,
    required this.initialSelected,
  });

  final List<EmployeeAccount> accounts;
  final List<EmployeeAccount> initialSelected;

  @override
  State<_LeavePolicyMemberDialog> createState() =>
      _LeavePolicyMemberDialogState();
}

class _LeavePolicyMemberDialogState extends State<_LeavePolicyMemberDialog> {
  late final List<String> _departments;
  late Set<String> _selectedIds;
  late String _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _departments =
        widget.accounts.map((item) => item.department).toSet().toList()..sort();
    _selectedDepartment = _departments.isEmpty ? '' : _departments.first;
    _selectedIds = widget.initialSelected.map((item) => item.id).toSet();
  }

  void _selectAll() {
    setState(() {
      _selectedIds = widget.accounts.map((item) => item.id).toSet();
    });
  }

  void _clearAll() {
    setState(_selectedIds.clear);
  }

  void _selectDepartment() {
    setState(() {
      _selectedIds = _visibleAccounts
          .where((item) => item.department == _selectedDepartment)
          .map((item) => item.id)
          .toSet();
    });
  }

  List<EmployeeAccount> get _visibleAccounts {
    if (_selectedDepartment.isEmpty) {
      return widget.accounts;
    }

    return widget.accounts
        .where((item) => item.department == _selectedDepartment)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccounts = widget.accounts
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    final visibleAccounts = _visibleAccounts;

    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      title: Text('적용 인원 선택', style: TheWeTextStyle.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('전체 선택'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('전체 삭제'),
                  ),
                  Container(
                    width: 150,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: TheWeColor.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: TheWeColor.black300.withValues(alpha: 0.35),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment.isEmpty
                            ? null
                            : _selectedDepartment,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: TheWeColor.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: TheWeTextStyle.body,
                        items: _departments
                            .map(
                              (department) => DropdownMenuItem(
                                value: department,
                                child: Text(department),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _selectedDepartment = value);
                        },
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _departments.isEmpty ? null : _selectDepartment,
                    icon: const Icon(Icons.business_outlined, size: 18),
                    style: FilledButton.styleFrom(
                      backgroundColor: TheWeColor.blue300,
                      foregroundColor: Colors.white,
                    ),
                    label: const Text('해당 부서만 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$_selectedDepartment 직원 목록',
                style: TheWeTextStyle.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleAccounts
                    .map(
                      (account) => FilterChip(
                        selected: _selectedIds.contains(account.id),
                        label: Text(
                          '${account.name} · ${account.department} · ${account.position}',
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedIds.add(account.id);
                            } else {
                              _selectedIds.remove(account.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text(
                '선택된 인원 ${selectedAccounts.length}명',
                style: TheWeTextStyle.body.copyWith(
                  color: TheWeColor.blue300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selectedAccounts),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('적용'),
        ),
      ],
    );
  }
}

class _LeavePromotionSection extends StatelessWidget {
  const _LeavePromotionSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '연차촉진 현황',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureActionRow(
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
              _StatusMetricCard(
                title: '전체',
                value: '0명',
                caption: '촉진대상자',
                accent: TheWeColor.black900,
                width: 180,
              ),
              _StatusMetricCard(
                title: '매칭',
                value: '0명',
                caption: '진행중',
                accent: TheWeColor.black500,
                width: 150,
              ),
              _StatusMetricCard(
                title: '1차 촉진',
                value: '0명',
                caption: '1차 진행',
                accent: TheWeColor.green,
                width: 150,
              ),
              _StatusMetricCard(
                title: '미회송',
                value: '0명',
                caption: '응답대기',
                accent: Color(0xFF8B5CF6),
                width: 150,
              ),
              _StatusMetricCard(
                title: '제출완료',
                value: '0명',
                caption: '문서 완료',
                accent: Color(0xFF10B981),
                width: 150,
              ),
              _StatusMetricCard(
                title: '통보완료',
                value: '0명',
                caption: '알림 완료',
                accent: Color(0xFF22C55E),
                width: 150,
              ),
              _StatusMetricCard(
                title: '확인완료',
                value: '0명',
                caption: '확인 처리',
                accent: TheWeColor.black500,
                width: 150,
              ),
              _StatusMetricCard(
                title: '무효불가',
                value: '0명',
                caption: '예외 대상',
                accent: TheWeColor.pink,
                width: 150,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(
            headers: const [
              _TableHeader('상태', flex: 2),
              _TableHeader('사원명', flex: 2),
              _TableHeader('입사일', flex: 2),
              _TableHeader('촉진구분', flex: 2),
              _TableHeader('촉진연차', flex: 2),
              _TableHeader('촉진기간', flex: 2),
              _TableHeader('1차 촉진일시', flex: 2),
              _TableHeader('제출기한', flex: 2),
              _TableHeader('파일 수신일시', flex: 2),
              _TableHeader('작성내역', flex: 2),
            ],
            rows: const [],
            emptyMessage: '촉진 대상자가 없습니다.',
          ),
        ],
      ),
    );
  }
}

class _RetiredLeaveSection extends StatelessWidget {
  const _RetiredLeaveSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '퇴사자 연차관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureActionRow(
            actions: ['퇴사자 연차정산', '연차 정산 조정', '연도별 퇴사자 관리'],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '사번, 이름을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('엑셀 다운로드'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(
            headers: const [
              _TableHeader('사번', flex: 2),
              _TableHeader('사원명', flex: 2),
              _TableHeader('부서명', flex: 2),
              _TableHeader('입사일', flex: 2),
              _TableHeader('퇴사일', flex: 2),
              _TableHeader('입사일 기준 연차수', flex: 2),
              _TableHeader('회계연도 기준 연차수', flex: 2),
              _TableHeader('사용 연차수', flex: 2),
              _TableHeader('미사용 연차수', flex: 2),
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? TheWeColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TheWeTextStyle.title),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PrimaryStatusBox extends StatelessWidget {
  const _PrimaryStatusBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 6),
          Text(value, style: TheWeTextStyle.subtitle),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
            ),
          ),
          Text(
            value,
            style: TheWeTextStyle.body.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? TheWeColor.blue100.withValues(alpha: 0.45)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TheWeTextStyle.body.copyWith(
                  color: selected ? TheWeColor.blue300 : TheWeColor.black900,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: selected ? TheWeColor.blue300 : TheWeColor.black500,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TheWeColor.black300 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TheWeTextStyle.body.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 8),
          Text(value, style: TheWeTextStyle.subtitle.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final isToday = date.day == now.day && date.month == now.month;
        final isWeekend = index >= 5;

        return Expanded(
          child: Column(
            children: [
              Text(
                labels[index],
                style: TheWeTextStyle.body.copyWith(
                  color: isWeekend ? TheWeColor.pink : TheWeColor.black900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? TheWeColor.black900
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${date.day}',
                  style: TheWeTextStyle.body.copyWith(
                    color: isToday ? Colors.white : TheWeColor.black900,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MonthScheduleTag extends StatelessWidget {
  const _MonthScheduleTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TheWeTextStyle.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthAttendanceGrid extends StatelessWidget {
  const _MonthAttendanceGrid({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(now.year, now.month, 1);
    final startOffset = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: startOffset));
    final cells = List.generate(
      42,
      (index) => startDate.add(Duration(days: index)),
    );

    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    const holidays = {6: '현충일'};

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.caption.copyWith(
                        color: label == '일' || label == '토'
                            ? TheWeColor.pink
                            : TheWeColor.black500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            final isCurrentMonth = date.month == now.month;
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isWeekend =
                date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday;
            final holiday = isCurrentMonth ? holidays[date.day] : null;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? TheWeColor.blue300
                      : TheWeColor.black300.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? TheWeColor.black900
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TheWeTextStyle.body.copyWith(
                          color: isToday
                              ? Colors.white
                              : !isCurrentMonth
                              ? TheWeColor.black500.withValues(alpha: 0.5)
                              : isWeekend || holiday != null
                              ? TheWeColor.pink
                              : TheWeColor.black900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (holiday != null)
                    _MonthScheduleTag(label: holiday, color: TheWeColor.pink)
                  else if (date.weekday == DateTime.sunday)
                    _MonthScheduleTag(
                      label: '휴일',
                      color: const Color(0xFF60A5FA),
                    )
                  else if (date.weekday == DateTime.saturday)
                    _MonthScheduleTag(
                      label: '휴무',
                      color: const Color(0xFF93C5FD),
                    )
                  else
                    _MonthScheduleTag(
                      label: '정상근무',
                      color: const Color(0xFF34D399),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimelineChart extends StatelessWidget {
  const _TimelineChart({
    required this.clockInTime,
    required this.clockOutTime,
    required this.requestCount,
  });

  final String? clockInTime;
  final String? clockOutTime;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            24,
            (index) => Expanded(
              child: Text(
                index.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TheWeColor.black300.withValues(alpha: 0.16),
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: List.generate(
                  24,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF93C5FD)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 26,
                child: Text(
                  '근무시작 ${clockInTime ?? '-'}',
                  style: TheWeTextStyle.caption,
                ),
              ),
              Positioned(
                right: 24,
                top: 26,
                child: Text(
                  '근무종료 ${clockOutTime ?? '-'}',
                  style: TheWeTextStyle.caption,
                ),
              ),
              Positioned(
                left: 24,
                bottom: 14,
                child: Text(
                  '상세 근로시간  소정 0h / 초과 $requestCount건',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusMetricCard extends StatelessWidget {
  const _StatusMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
    this.width,
  });

  final String title;
  final String value;
  final String caption;
  final Color accent;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TheWeTextStyle.body.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(value, style: TheWeTextStyle.pageTitle.copyWith(color: accent)),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TheWeColor.black300 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TheWeTextStyle.body.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ManagementGroupCardData {
  const _ManagementGroupCardData({
    required this.badge,
    required this.title,
    required this.rows,
  });

  final String badge;
  final String title;
  final List<String> rows;
}

class _ManagementGroupCard extends StatelessWidget {
  const _ManagementGroupCard({required this.data});

  final _ManagementGroupCardData data;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TheWeColor.blue100.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(data.badge, style: TheWeTextStyle.caption),
          ),
          const SizedBox(height: 18),
          Text(data.title, style: TheWeTextStyle.title),
          const SizedBox(height: 14),
          ...data.rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                row,
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddManagementCard extends StatelessWidget {
  const _AddManagementCard({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: TheWeColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TheWeColor.black300.withValues(alpha: 0.18),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: TheWeColor.black300.withValues(alpha: 0.4),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TheWeTextStyle.title,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader {
  const _TableHeader(this.label, {this.flex = 2});

  final String label;
  final int flex;
}

class _GenericTable extends StatelessWidget {
  const _GenericTable({
    required this.headers,
    required this.rows,
    this.emptyMessage = '목록이 없습니다.',
  });

  final List<_TableHeader> headers;
  final List<List<String>> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final minimumWidth = headers.fold<double>(
      0,
      (sum, item) => sum + (item.flex * 110),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, minimumWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: headers
                        .map(
                          (header) => _TableCell(
                            header.label,
                            flex: header.flex,
                            header: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (rows.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (row) => Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var index = 0; index < headers.length; index++)
                            _TableCell(row[index], flex: headers[index].flex),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTable extends StatelessWidget {
  const _RequestTable({required this.requests});

  final List<AttendanceRequestRecord> requests;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: TheWeColor.black300.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: const [
                      _TableCell('신청유형', flex: 2, header: true),
                      _TableCell('신청일', flex: 2, header: true),
                      _TableCell('시간', flex: 2, header: true),
                      _TableCell('사유', flex: 5, header: true),
                      _TableCell('상태', flex: 2, header: true),
                    ],
                  ),
                ),
                if (requests.isEmpty)
                  Container(
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Text(
                      '목록이 없습니다.',
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  )
                else
                  ...requests.map(
                    (item) => Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _TableCell(item.type, flex: 2),
                          _TableCell(item.date, flex: 2),
                          _TableCell(item.timeRange, flex: 2),
                          _TableCell(item.reason, flex: 5),
                          _StatusBadgeCell(item.status, flex: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompanyAttendanceRowData {
  const _CompanyAttendanceRowData({
    required this.account,
    required this.snapshot,
    required this.stateLabel,
    required this.anomalyLabel,
  });

  final EmployeeAccount account;
  final AttendanceSnapshot snapshot;
  final String stateLabel;
  final String anomalyLabel;
}

class _CompanyAttendanceTable extends StatelessWidget {
  const _CompanyAttendanceTable({required this.rows});

  final List<_CompanyAttendanceRowData> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 1080
            ? 1080.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: const [
                      _TableCell('사번', flex: 2, header: true),
                      _TableCell('사원명', flex: 2, header: true),
                      _TableCell('부서명', flex: 2, header: true),
                      _TableCell('근무그룹형', flex: 2, header: true),
                      _TableCell('출근시간', flex: 2, header: true),
                      _TableCell('퇴근시간', flex: 2, header: true),
                      _TableCell('총 근로시간', flex: 2, header: true),
                      _TableCell('휴가', flex: 2, header: true),
                      _TableCell('휴일대체', flex: 2, header: true),
                      _TableCell('근태이상', flex: 2, header: true),
                    ],
                  ),
                ),
                ...rows.map(
                  (row) => Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TableCell(row.account.id, flex: 2),
                        _TableCell(row.account.name, flex: 2),
                        _TableCell(row.account.department, flex: 2),
                        _TableCell(row.snapshot.workPolicy, flex: 2),
                        _TableCell(row.snapshot.clockInTime ?? '-', flex: 2),
                        _TableCell(row.snapshot.clockOutTime ?? '-', flex: 2),
                        _TableCell(
                          row.snapshot.clockOutTime == null
                              ? '0h 0m 0s'
                              : '8h 0m 0s',
                          flex: 2,
                        ),
                        _TableCell(
                          '${row.snapshot.annualLeaveUsed.toStringAsFixed(1)}일',
                          flex: 2,
                        ),
                        _TableCell(
                          row.snapshot.delegations.isEmpty ? '-' : '신청중',
                          flex: 2,
                        ),
                        _StatusBadgeCell(row.anomalyLabel, flex: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {required this.flex, this.header = false});

  final String text;
  final int flex;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (header ? TheWeTextStyle.caption : TheWeTextStyle.body).copyWith(
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
          color: header ? TheWeColor.black500 : TheWeColor.black900,
        ),
      ),
    );
  }
}

class _StatusBadgeCell extends StatelessWidget {
  const _StatusBadgeCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final color = text.contains('반려') || text.contains('지각')
        ? TheWeColor.pink
        : text.contains('완료') || text.contains('정상') || text.contains('승인')
        ? TheWeColor.green
        : TheWeColor.blue300;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TheWeTextStyle.caption.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _DelegationItem extends StatelessWidget {
  const _DelegationItem({required this.item});

  final AttendanceDelegation item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.period, style: TheWeTextStyle.subtitle),
          const SizedBox(height: 6),
          Text(item.reason, style: TheWeTextStyle.body),
          const SizedBox(height: 4),
          Text('대결자: ${item.substituteName}', style: TheWeTextStyle.caption),
          const SizedBox(height: 4),
          Text(
            item.status,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.pink),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TheWeTextStyle.caption),
      ],
    );
  }
}

class _OvertimeRequestDialog extends StatefulWidget {
  const _OvertimeRequestDialog();

  @override
  State<_OvertimeRequestDialog> createState() => _OvertimeRequestDialogState();
}

class _OvertimeRequestDialogState extends State<_OvertimeRequestDialog> {
  final reasonController = TextEditingController();
  final String checkDate = _formatDate(DateTime.now());
  final String startDate = _formatDate(DateTime.now());
  final String endDate = _formatDate(DateTime.now());
  int startHour = 18;
  int startMinute = 0;
  int endHour = 21;
  int endMinute = 0;

  DateTime get _startDateTime => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    startHour,
    startMinute,
  );

  DateTime get _endDateTime => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    endHour,
    endMinute,
  );

  bool get _invalidTime => !_endDateTime.isAfter(_startDateTime);

  String get _durationLabel {
    if (_invalidTime) {
      return '0h 0m';
    }
    final duration = _endDateTime.difference(_startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      title: Row(
        children: [
          Text('초과근로 신청', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
              label: '출근체크일',
              child: _InlineBox(text: checkDate),
            ),
            _DialogField(
              label: '초과근로신청',
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 132,
                        child: Text(
                          '초과근로발생시작일',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(child: _InlineBox(text: startDate)),
                      const SizedBox(width: 10),
                      _TimeDropdown(
                        value: startHour,
                        values: List.generate(24, (index) => index),
                        onChanged: (value) =>
                            setState(() => startHour = value ?? startHour),
                      ),
                      const SizedBox(width: 8),
                      const Text(':'),
                      const SizedBox(width: 8),
                      _TimeDropdown(
                        value: startMinute,
                        values: const [0, 30],
                        onChanged: (value) =>
                            setState(() => startMinute = value ?? startMinute),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(
                        width: 132,
                        child: Text(
                          '초과근로발생종료일',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(child: _InlineBox(text: endDate)),
                      const SizedBox(width: 10),
                      _TimeDropdown(
                        value: endHour,
                        values: List.generate(24, (index) => index),
                        onChanged: (value) =>
                            setState(() => endHour = value ?? endHour),
                      ),
                      const SizedBox(width: 8),
                      const Text(':'),
                      const SizedBox(width: 8),
                      _TimeDropdown(
                        value: endMinute,
                        values: const [0, 30],
                        onChanged: (value) =>
                            setState(() => endMinute = value ?? endMinute),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _SmallStat(label: '초과근로시간', value: _durationLabel),
                const _SmallStat(label: '잔여 초과근로시간', value: '12h 0m'),
                _SmallStat(label: '신청 후 초과근로시간', value: _durationLabel),
              ],
            ),
            if (_invalidTime) ...[
              const SizedBox(height: 14),
              Text(
                '신청 시간이 잘못되었습니다.',
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.pink),
              ),
            ],
            const SizedBox(height: 18),
            _DialogField(
              label: '신청사유',
              child: CustomTextFormField(
                controller: reasonController,
                minLines: 4,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '신청 사유를 입력하세요.'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _invalidTime
              ? null
              : () => Navigator.of(context).pop(
                  AttendanceRequestRecord(
                    type: '초과근로 신청서',
                    date: checkDate,
                    timeRange:
                        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} ~ ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                    status: '결재대기',
                    reason: reasonController.text.trim().isEmpty
                        ? '초과근무 사유 미입력'
                        : reasonController.text.trim(),
                  ),
                ),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('전자결재 상신'),
        ),
      ],
    );
  }
}

class _WorkTimeCorrectionDialog extends StatefulWidget {
  const _WorkTimeCorrectionDialog();

  @override
  State<_WorkTimeCorrectionDialog> createState() =>
      _WorkTimeCorrectionDialogState();
}

class _WorkTimeCorrectionDialogState extends State<_WorkTimeCorrectionDialog> {
  final reasonController = TextEditingController();
  final String selectedDate = _formatDate(DateTime.now());
  final List<String> corrections = [];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctedHours = corrections.length * 2;

    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      title: Row(
        children: [
          Text('근무시간수정 신청', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
              label: '수정 신청일',
              child: _InlineBox(text: selectedDate),
            ),
            _DialogField(
              label: '근무시간 수정',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(
                          () => corrections.add(
                            '$selectedDate 09:00 ~ 11:00 근무시간 추가',
                          ),
                        ),
                        child: const Text('추가'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: corrections.isEmpty
                            ? null
                            : () => setState(() => corrections.removeLast()),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: corrections.isEmpty
                        ? Text(
                            '타임라인 내역이 없습니다.',
                            style: TheWeTextStyle.body.copyWith(
                              color: TheWeColor.black500,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: corrections
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      item,
                                      style: TheWeTextStyle.body,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                const _SmallStat(label: '신청일 근로시간', value: '0h'),
                _SmallStat(label: '수정 후 근로시간', value: '${correctedHours}h'),
                _SmallStat(label: '주간 총 근로시간', value: '${correctedHours}h'),
              ],
            ),
            const SizedBox(height: 18),
            _DialogField(
              label: '신청사유',
              child: CustomTextFormField(
                controller: reasonController,
                minLines: 4,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '신청 사유를 입력하세요.'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AttendanceRequestRecord(
              type: '근무시간 수정 신청서',
              date: selectedDate,
              timeRange: corrections.isEmpty
                  ? '타임라인 없음'
                  : '${corrections.length}건 수정',
              status: '결재대기',
              reason: reasonController.text.trim().isEmpty
                  ? '근무시간 수정 사유 미입력'
                  : reasonController.text.trim(),
            ),
          ),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('전자결재 상신'),
        ),
      ],
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  const _TimeDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final int value;
  final List<int> values;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item.toString().padLeft(2, '0')),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.caption),
        const SizedBox(height: 6),
        Text(value, style: TheWeTextStyle.subtitle),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TheWeTextStyle.body)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _InlineBox extends StatelessWidget {
  const _InlineBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TheWeColor.black300),
      ),
      child: Text(text, style: TheWeTextStyle.body),
    );
  }
}

List<_CompanyAttendanceRowData> _buildCompanyRows(
  List<EmployeeAccount> accounts,
  Map<String, AttendanceSnapshot> attendanceMap,
) {
  return accounts.map((account) {
    final snapshot = attendanceMap[account.id] ?? _seedState[account.id]!;
    final hasPendingOvertime = snapshot.requests.any(
      (item) => item.type.contains('초과근로') && item.status.contains('결재대기'),
    );
    final stateLabel = snapshot.lateCount > 0 ? '지각' : '정상';
    final anomalyLabel = hasPendingOvertime
        ? '미승인 초과근무'
        : snapshot.lateCount > 0
        ? '지각'
        : '정상';

    return _CompanyAttendanceRowData(
      account: account,
      snapshot: snapshot,
      stateLabel: stateLabel,
      anomalyLabel: anomalyLabel,
    );
  }).toList();
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDate(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}

String _formatKoreanDateTime(DateTime time) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '${time.year}년 $month월 $day일 (${weekdays[time.weekday - 1]}) $hour:$minute:$second';
}

final _seedState = <String, AttendanceSnapshot>{
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
  'admin_master': const AttendanceSnapshot(
    workPolicy: '관리자 근무제',
    clockInTime: '08:40',
    clockOutTime: null,
    annualLeaveRemaining: 15.0,
    annualLeaveUsed: 0.0,
    lateCount: 0,
    overtimeHours: 2,
    weeklyWorkedHours: 38,
    weeklyRequiredHours: 40,
    remainingWorkDays: 2,
    requests: [],
    delegations: [],
  ),
};
