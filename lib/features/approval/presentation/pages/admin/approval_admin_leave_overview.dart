import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminEmployeeLeaveOverviewDialog extends StatelessWidget {
  const AdminEmployeeLeaveOverviewDialog({
    super.key,
    required this.state,
    required this.account,
    required this.onBack,
    required this.onDirectLeave,
  });

  final ApprovalDashboardState state;
  final EmployeeAccount account;
  final VoidCallback onBack;
  final VoidCallback onDirectLeave;

  @override
  Widget build(BuildContext context) {
    final requests = state.leaveRequestsFor(account.id);
    final total = state.totalAnnualLeaveFor(account);
    final used = state.usedAnnualLeaveFor(account.id);
    final pending = state.pendingAnnualLeaveFor(account.id);
    final remaining = state.remainingAnnualLeaveFor(account);
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      backgroundColor: TheWeColor.background,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 760),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('employee-leave-back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new),
                    tooltip: '전체 직원으로 돌아가기',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${account.name} 휴가 현황',
                          style: TheWeTextStyle.title,
                        ),
                        Text(
                          '${account.department} · ${account.position} · 입사일 ${account.hireDate}',
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: mobile ? double.infinity : null,
                child: FilledButton.icon(
                  key: const ValueKey('admin-direct-leave-button'),
                  onPressed: onDirectLeave,
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('휴가 직접 등록'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminEmployeeLeaveMetric(
                    label: state.leaveEntitlementLabelFor(account),
                    value: adminLeaveDays(total),
                  ),
                  AdminEmployeeLeaveMetric(
                    label: state.leaveUsedLabelFor(account),
                    value: adminLeaveDays(used),
                  ),
                  AdminEmployeeLeaveMetric(
                    label: state.leaveRemainingLabelFor(account),
                    value: adminLeaveDays(remaining),
                  ),
                  AdminEmployeeLeaveMetric(
                    label: '승인 대기',
                    value: adminLeaveDays(pending),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('휴가 신청 내역', style: TheWeTextStyle.subtitle),
              const SizedBox(height: 10),
              Expanded(
                child: requests.isEmpty
                    ? const Center(child: Text('휴가 신청 내역이 없습니다.'))
                    : ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: adminSurface(),
                            child: mobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              request.directEntry
                                                  ? '관리자 등록'
                                                  : request.status,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(adminLeaveDays(request.days)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        request.type,
                                        key: ValueKey(
                                          'employee-leave-type-${request.id}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${request.startDate} ~ ${request.endDate}',
                                        key: ValueKey(
                                          'employee-leave-date-${request.id}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TheWeTextStyle.caption.copyWith(
                                          color: TheWeColor.black500,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${request.reason}${request.directEntry ? ' · 등록자 ${request.registeredBy}' : ''}',
                                        key: ValueKey(
                                          'employee-leave-reason-${request.id}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TheWeTextStyle.caption.copyWith(
                                          color: TheWeColor.black500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          request.directEntry
                                              ? '관리자 등록'
                                              : request.status,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${request.type} · ${request.startDate} ~ ${request.endDate}\n${request.reason}${request.directEntry ? ' · 등록자 ${request.registeredBy}' : ''}',
                                        ),
                                      ),
                                      Text(adminLeaveDays(request.days)),
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
