import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';
import 'approval_admin_leave_overview.dart';

Future<void> showAdminEmployeeLeaveDirectory(
  BuildContext context,
  ApprovalDashboardState state,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _EmployeeLeaveBrowserDialog(initialState: state),
  );
}

Future<void> showAdminLeaveRequestDirectory(
  BuildContext context,
  ApprovalDashboardState state, {
  required List<LeaveRequest> requests,
  required String title,
  required String emptyMessage,
}) async {
  final mobile = MediaQuery.sizeOf(context).width < 700;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      key: const ValueKey('leave-request-directory-dialog'),
      backgroundColor: TheWeColor.background,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: TheWeTextStyle.title)),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: requests.isEmpty
                    ? Center(child: Text(emptyMessage))
                    : mobile
                    ? ListView.separated(
                        key: const ValueKey('mobile-admin-leave-request-list'),
                        itemCount: requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          final employee = state.accounts
                              .where((account) => account.id == request.userId)
                              .firstOrNull;
                          return _LeaveRequestDirectoryCard(
                            employee: employee,
                            request: request,
                          );
                        },
                      )
                    : SingleChildScrollView(
                        child: TheWeDataTable(
                          headers: const [
                            '이름',
                            '부서',
                            '휴가 종류',
                            '기간',
                            '일수',
                            '신청 사유',
                          ],
                          columnFlexes: const [1.2, 1.5, 1.1, 2.4, .7, 2.2],
                          minWidth: mobile ? 820 : 860,
                          rows: requests.map((request) {
                            final employee = state.accounts
                                .where(
                                  (account) => account.id == request.userId,
                                )
                                .firstOrNull;
                            return <Widget>[
                              Text(employee?.name ?? request.userId),
                              Text(employee?.department ?? '-'),
                              Text(request.type),
                              Text('${request.startDate} ~ ${request.endDate}'),
                              Text(adminLeaveDays(request.days)),
                              Text(request.reason),
                            ];
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LeaveRequestDirectoryCard extends StatelessWidget {
  const _LeaveRequestDirectoryCard({
    required this.employee,
    required this.request,
  });

  final EmployeeAccount? employee;
  final LeaveRequest request;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: adminSurface(),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                employee?.name ?? request.userId,
                style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TheWeColor.blueSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                employee?.department ?? '-',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.blue300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 18, color: Color(0xFFE1E4E8)),
        _AdminLeaveInfoRow(label: '휴가 종류', value: request.type),
        const SizedBox(height: 9),
        _AdminLeaveInfoRow(
          label: '기간',
          value: '${request.startDate} ~ ${request.endDate}',
        ),
        const SizedBox(height: 9),
        _AdminLeaveInfoRow(label: '일수', value: adminLeaveDays(request.days)),
        const SizedBox(height: 9),
        _AdminLeaveInfoRow(label: '신청 사유', value: request.reason, maxLines: 2),
      ],
    ),
  );
}

class _AdminLeaveInfoRow extends StatelessWidget {
  const _AdminLeaveInfoRow({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 72,
        child: Text(
          label,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

Future<void> showAdminApprovedLeaveDirectory(
  BuildContext context,
  WidgetRef ref,
  ApprovalDashboardState state,
  List<LeaveRequest> requests,
) async {
  await showAdminLeaveRequestDirectory(
    context,
    state,
    requests: requests,
    title: '휴가 승인 내역',
    emptyMessage: '새로 승인된 휴가가 없습니다.',
  );
  if (requests.isEmpty) return;
  ref
      .read(approvalDashboardControllerProvider.notifier)
      .acknowledgeApprovedLeaves(requests.map((request) => request.id));
}

Future<void> showAdminDepartmentDirectory(
  BuildContext context,
  ApprovalDashboardState state,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _DepartmentDirectoryDialog(state: state),
  );
}

class _DepartmentDirectoryDialog extends StatefulWidget {
  const _DepartmentDirectoryDialog({required this.state});

  final ApprovalDashboardState state;

  @override
  State<_DepartmentDirectoryDialog> createState() =>
      _DepartmentDirectoryDialogState();
}

class _DepartmentDirectoryDialogState
    extends State<_DepartmentDirectoryDialog> {
  final Map<String, ExpansibleController> controllers = {};

  ExpansibleController controllerFor(String department) =>
      controllers.putIfAbsent(department, ExpansibleController.new);

  void handleExpansion(String department, bool expanded) {
    if (!expanded) return;
    for (final entry in controllers.entries) {
      if (entry.key != department && entry.value.isExpanded) {
        entry.value.collapse();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      backgroundColor: TheWeColor.background,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 700),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('부서 현황', style: TheWeTextStyle.title)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: state.departments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final department = state.departments[index];
                    final members = state.accounts
                        .where((account) => account.department == department)
                        .toList();
                    return Container(
                      decoration: adminSurface(),
                      child: ExpansionTile(
                        key: ValueKey('department-directory-$department'),
                        controller: controllerFor(department),
                        onExpansionChanged: (expanded) =>
                            handleExpansion(department, expanded),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(department, style: TheWeTextStyle.subtitle),
                        subtitle: Text('${members.length}명'),
                        children: [
                          for (final member in members)
                            ListTile(
                              dense: mobile,
                              title: Text(member.name),
                              subtitle: Text(
                                '${member.position} · ${member.id}',
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeLeaveBrowserDialog extends ConsumerStatefulWidget {
  const _EmployeeLeaveBrowserDialog({required this.initialState});

  final ApprovalDashboardState initialState;

  @override
  ConsumerState<_EmployeeLeaveBrowserDialog> createState() =>
      _EmployeeLeaveBrowserDialogState();
}

class _EmployeeLeaveBrowserDialogState
    extends ConsumerState<_EmployeeLeaveBrowserDialog> {
  EmployeeAccount? selected;

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(approvalDashboardControllerProvider).asData?.value ??
        widget.initialState;
    final account = selected;
    if (account == null) {
      return _EmployeeLeaveDirectoryDialog(
        state: state,
        onSelected: (value) => setState(() => selected = value),
      );
    }
    return AdminEmployeeLeaveOverviewDialog(
      state: state,
      account: account,
      onBack: () => setState(() => selected = null),
      onDirectLeave: () => showAdminDirectLeaveDialog(context, ref, account),
    );
  }
}

class _EmployeeLeaveDirectoryDialog extends StatelessWidget {
  const _EmployeeLeaveDirectoryDialog({
    required this.state,
    required this.onSelected,
  });

  final ApprovalDashboardState state;
  final ValueChanged<EmployeeAccount> onSelected;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      backgroundColor: TheWeColor.surfaceAlt,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('전체 직원 연차 현황', style: TheWeTextStyle.title),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: mobile
                    ? ListView.separated(
                        itemCount: state.accounts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final account = state.accounts[index];
                          return ListTile(
                            tileColor: TheWeColor.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: TheWeColor.black300.withValues(
                                  alpha: .25,
                                ),
                              ),
                            ),
                            title: Text(account.name),
                            subtitle: Text(
                              '${account.position} · ${account.department}',
                            ),
                            trailing: Text(
                              '${state.isUnderOneYear(account) ? '월차' : '연차'} 잔여 ${adminLeaveDays(state.remainingAnnualLeaveFor(account))}',
                            ),
                            onTap: () => onSelected(account),
                          );
                        },
                      )
                    : TheWeDataTable(
                        headers: const ['이름', '직급', '부서', '연차 현황'],
                        columnFlexes: const [1.4, 1.1, 1.5, 2.4],
                        minWidth: 860,
                        rows: state.accounts.map((account) {
                          final total = state.totalAnnualLeaveFor(account);
                          final used = state.usedAnnualLeaveFor(account.id);
                          final pending = state.pendingAnnualLeaveFor(
                            account.id,
                          );
                          return <Widget>[
                            TextButton(
                              onPressed: () => onSelected(account),
                              child: Text(account.name),
                            ),
                            Text(account.position),
                            Text(account.department),
                            Text(
                              '${state.isUnderOneYear(account) ? '월차' : '연차'} $total일 · 사용 ${adminLeaveDays(used)} · 대기 ${adminLeaveDays(pending)} · 잔여 ${adminLeaveDays(state.remainingAnnualLeaveFor(account))}',
                              textAlign: TextAlign.center,
                            ),
                          ];
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
