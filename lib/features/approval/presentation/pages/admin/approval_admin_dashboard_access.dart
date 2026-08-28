import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';
import 'approval_admin_leave_management.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLeaves = state.pendingLeaveRequests;
    final approvedLeaves = state.unacknowledgedApprovedLeaveRequests;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final currentUser = state.currentUser;
    final isLeaveDecisionAccount =
        currentUser?.id == 'ceo' ||
        currentUser?.position.contains('대표') == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회사 운영 현황',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        SizedBox(height: mobile ? 12 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 600
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: mobile ? 10 : 12,
              runSpacing: mobile ? 10 : 12,
              children: [
                AdminMetric(
                  width: width,
                  icon: Icons.people_outline,
                  label: '전체 직원',
                  value: '${state.accounts.length}명',
                  onTap: () => showAdminEmployeeLeaveDirectory(context, state),
                ),
                AdminMetric(
                  width: width,
                  icon: Icons.beach_access_outlined,
                  label: '휴가 승인 대기',
                  value: '${pendingLeaves.length}건',
                  onTap: () => showAdminLeaveRequestDirectory(
                    context,
                    state,
                    requests: pendingLeaves,
                    title: '휴가 승인 대기',
                    emptyMessage: '승인 대기 중인 휴가가 없습니다.',
                  ),
                ),
                AdminMetric(
                  width: width,
                  icon: Icons.task_alt_outlined,
                  label: '휴가 승인',
                  value: '${approvedLeaves.length}건',
                  onTap: () => showAdminApprovedLeaveDirectory(
                    context,
                    ref,
                    state,
                    approvedLeaves,
                  ),
                ),
                AdminMetric(
                  width: width,
                  icon: Icons.account_tree_outlined,
                  label: '부서',
                  value: '${state.departments.length}개',
                  onTap: () => showAdminDepartmentDirectory(context, state),
                ),
              ],
            );
          },
        ),
        SizedBox(height: mobile ? 22 : 28),
        Text(
          '휴가 승인 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 12),
        if (pendingLeaves.isEmpty)
          Container(
            width: double.infinity,
            decoration: adminSurface(),
            padding: EdgeInsets.all(mobile ? 22 : 40),
            child: const Center(child: Text('승인 대기 중인 휴가가 없습니다.')),
          )
        else if (mobile)
          ...pendingLeaves.map((request) {
            final employee = state.accounts
                .where((item) => item.id == request.userId)
                .firstOrNull;
            return _PendingLeaveCard(
              employee: employee,
              request: request,
              showDetails: isLeaveDecisionAccount,
              canAct: state.canActOnLeave(request),
              onReject: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .actOnLeave(request.id, approve: false),
              onApprove: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .actOnLeave(request.id, approve: true),
            );
          })
        else if (!isLeaveDecisionAccount)
          TheWeDataTable(
            headers: const ['신청 직원', '결재 상태'],
            columnFlexes: const [1.8, 1.2],
            minWidth: 620,
            rows: pendingLeaves.map((request) {
              final employee = state.accounts
                  .where((item) => item.id == request.userId)
                  .firstOrNull;
              return <Widget>[
                Text(
                  '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                  textAlign: TextAlign.center,
                ),
                const Text('대표 결재 진행중'),
              ];
            }).toList(),
          )
        else
          TheWeDataTable(
            headers: const ['직원', '종류', '기간', '일수', '처리'],
            columnFlexes: const [1.8, 1.05, 2.2, .7, 1.35],
            minWidth: 980,
            rows: pendingLeaves.map((request) {
              final employee = state.accounts
                  .where((item) => item.id == request.userId)
                  .firstOrNull;
              return <Widget>[
                Text(
                  '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                ),
                Text(request.type),
                Text('${request.startDate} ~ ${request.endDate}'),
                Text('${request.days}일'),
                state.canActOnLeave(request)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .actOnLeave(request.id, approve: false),
                            child: const Text('반려'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .actOnLeave(request.id, approve: true),
                            child: const Text('승인'),
                          ),
                        ],
                      )
                    : const Text('다음 결재 대기'),
              ];
            }).toList(),
          ),
      ],
    );
  }
}

class _PendingLeaveCard extends StatelessWidget {
  const _PendingLeaveCard({
    required this.employee,
    required this.request,
    required this.showDetails,
    required this.canAct,
    required this.onReject,
    required this.onApprove,
  });

  final EmployeeAccount? employee;
  final LeaveRequest request;
  final bool showDetails;
  final bool canAct;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
              ),
            ),
            if (showDetails)
              Chip(
                label: Text(request.type),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          showDetails
              ? '${request.startDate} ~ ${request.endDate} · ${request.days}일'
              : '대표 결재 진행중',
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        if (canAct) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('반려'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  child: const Text('승인'),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
