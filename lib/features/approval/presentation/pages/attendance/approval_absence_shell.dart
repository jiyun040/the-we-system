part of 'approval_absence_page.dart';

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
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 2)
          : null,
      body: appState.when(
        data: (value) {
          final user = value.currentUser;
          if (user == null) {
            return const SizedBox.shrink();
          }
          final currentSection = value.isAdminMode
              ? section
              : AttendanceSection.myStatus;

          final attendanceMap = ref.watch(attendanceControllerProvider);
          final snapshot = attendanceMap[user.id] ?? _seedState[user.id]!;
          final companyRows = _buildCompanyRows(value.accounts, attendanceMap);
          final isPhone = MediaQuery.sizeOf(context).width < 520;

          final content = Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 18 : 24,
                  isPhone ? 18 : 22,
                  isPhone ? 18 : 24,
                  24,
                ),
                child: Column(
                  children: [
                    _PageHeader(section: currentSection),
                    const SizedBox(height: 18),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 1180;
                          final controlPanel = _AttendanceControlPanel(
                            user: user,
                            snapshot: snapshot,
                            currentSection: currentSection,
                            currentView: view,
                            showManagementLinks: value.isAdminMode,
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
                            onOpenRequest: (kind) =>
                                _openRequestDialog(context, ref, user, kind),
                          );
                          final sectionContent = _AttendanceSectionContent(
                            section: currentSection,
                            view: view,
                            user: user,
                            snapshot: snapshot,
                            accounts: value.accounts,
                            companyRows: companyRows,
                            onChangeView: (nextView) => _goToSection(
                              context,
                              currentSection,
                              currentView: nextView,
                            ),
                            onOpenRequest: (kind) =>
                                _openRequestDialog(context, ref, user, kind),
                          );

                          if (!currentSection.showsControlPanel) {
                            return SingleChildScrollView(child: sectionContent);
                          }

                          if (stacked) {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  controlPanel,
                                  const SizedBox(height: 16),
                                  sectionContent,
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
                                  child: sectionContent,
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
          );

          if (isPhone) {
            return Row(children: [content]);
          }

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
              content,
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
      showTheWeSnackBar(context, message: '${request.type} 전자결재 상신이 등록되었습니다.');
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.section});

  final AttendanceSection section;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;
    final title = Text(
      section.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: isPhone
          ? TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800)
          : TheWeTextStyle.pageTitle,
    );

    if (!isPhone || section == AttendanceSection.myStatus) {
      return Align(alignment: Alignment.centerLeft, child: title);
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => context.goNamed(AppRouteName.absence),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        Expanded(child: title),
      ],
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
    required this.showManagementLinks,
  });

  final EmployeeAccount user;
  final AttendanceSnapshot snapshot;
  final AttendanceSection currentSection;
  final AttendanceView currentView;
  final ValueChanged<AttendanceSection> onNavigate;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final ValueChanged<AttendanceRequestKind> onOpenRequest;
  final bool showManagementLinks;

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
            if (showManagementLinks) ...[
              AttendanceSection.companyStatus,
              AttendanceSection.workGroup,
              AttendanceSection.leavePolicy,
            ],
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
