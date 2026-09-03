import 'approval_leave_dependencies.dart';
import 'approval_leave_widgets.dart';

class ApprovalLeaveContent extends ConsumerWidget {
  const ApprovalLeaveContent({super.key, required this.state});
  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 520;
    final total = state.totalAnnualLeave.toDouble();
    final used = state.usedAnnualLeave;
    final pending = state.pendingAnnualLeave;
    final remaining = state.remainingAnnualLeave;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('leave-content-scroll'),
        padding: EdgeInsets.fromLTRB(
          mobile ? 18 : 28,
          mobile ? 18 : 24,
          mobile ? 18 : 28,
          mobile ? 18 : 28,
        ),
        child: Align(
          key: const ValueKey('leave-content-top'),
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalLeaveHeader(
                  userName: state.currentUser?.name ?? '',
                  onRequest: () => _showLeaveRequestDialog(context, ref),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: EdgeInsets.all(mobile ? 16 : 24),
                  decoration: approvalLeaveSurfaceDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: TheWeColor.blue300,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '입사일 ${state.currentUser?.hireDate ?? '-'}',
                            style: TheWeTextStyle.subtitle,
                          ),
                          Chip(
                            label: Text(
                              state.servicePeriodLabelFor(state.currentUser),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compactGrid = constraints.maxWidth < 720;
                          final width = compactGrid
                              ? (constraints.maxWidth - 10) / 2
                              : (constraints.maxWidth - 36) / 4;
                          return Wrap(
                            spacing: compactGrid ? 10 : 12,
                            runSpacing: compactGrid ? 10 : 12,
                            children: [
                              ApprovalLeaveMetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveEntitlementLabelFor(
                                  state.currentUser,
                                ),
                                value: approvalLeaveDays(total),
                                color: TheWeColor.blue300,
                              ),
                              ApprovalLeaveMetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveUsedLabelFor(
                                  state.currentUser,
                                ),
                                value: approvalLeaveDays(used),
                                color: TheWeColor.pink,
                              ),
                              ApprovalLeaveMetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveRemainingLabelFor(
                                  state.currentUser,
                                ),
                                value: approvalLeaveDays(remaining),
                                color: TheWeColor.green,
                              ),
                              ApprovalLeaveMetricCard(
                                width: width,
                                compact: compactGrid,
                                label: '승인 대기',
                                value: approvalLeaveDays(pending),
                                color: Colors.orange,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: total == 0
                              ? 0
                              : ((used + pending) / total).clamp(0.0, 1.0),
                          backgroundColor: TheWeColor.surface,
                          color: TheWeColor.blue300,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('휴가 신청 내역', style: TheWeTextStyle.title),
                const SizedBox(height: 12),
                if (state.currentUserLeaveRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: approvalLeaveSurfaceDecoration(),
                    padding: const EdgeInsets.all(48),
                    child: const Center(child: Text('신청 내역이 없습니다.')),
                  )
                else if (mobile)
                  Column(
                    key: const ValueKey('mobile-leave-request-list'),
                    children: [
                      for (final request in state.currentUserLeaveRequests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ApprovalMobileLeaveRequestCard(
                            request: request,
                            onStatusTap: request.status == '승인대기'
                                ? () =>
                                      _showLeaveProgressDialog(context, request)
                                : null,
                          ),
                        ),
                    ],
                  )
                else
                  TheWeDataTable(
                    headers: const ['상태', '휴가 종류', '기간', '사용 일수', '신청 사유'],
                    columnFlexes: const [1.2, 1.15, 2.3, .9, 2.2],
                    minWidth: 940,
                    rows: state.currentUserLeaveRequests
                        .map(
                          (request) => <Widget>[
                            ApprovalLeaveStatusChip(
                              status: request.status,
                              onTap: request.status == '승인대기'
                                  ? () => _showLeaveProgressDialog(
                                      context,
                                      request,
                                    )
                                  : null,
                            ),
                            Text(request.type),
                            Text('${request.startDate} ~ ${request.endDate}'),
                            Text(approvalLeaveDays(request.days)),
                            Text(request.reason),
                          ],
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveRequestDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final reason = TextEditingController();
    final isMonthlyLeave = state.isUnderOneYear(state.currentUser);
    final leaveTypes = isMonthlyLeave
        ? const ['월차', '반차', '경조 휴가', '휴가']
        : const ['연차', '반차', '경조 휴가', '휴가'];
    var type = leaveTypes.first;
    var start = DateTime.now().add(const Duration(days: 1));
    var end = start;
    var halfDay = false;
    var reasonError = '';
    var requestError = '';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final compact = MediaQuery.sizeOf(context).width < 600;
          Future<void> pickDate(bool isStart) async {
            final picked = await showTheWeDatePicker(
              context,
              initialDate: isStart ? start : end,
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 2),
              title: isStart ? '휴가 시작일 선택' : '휴가 종료일 선택',
              dialogKey: const ValueKey('leave-date-picker'),
            );
            if (picked == null) return;
            setDialogState(() {
              requestError = '';
              if (isStart) {
                start = picked;
                if (end.isBefore(start)) end = start;
              } else {
                end = picked;
              }
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 40,
              vertical: 24,
            ),
            title: const Text('휴가 신청서'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '휴가 종류',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TheWeDropdown<String>(
                      value: type,
                      width: double.infinity,
                      items: leaveTypes,
                      labelBuilder: (value) => value,
                      onChanged: (value) => setDialogState(() {
                        type = value ?? leaveTypes.first;
                        halfDay = type == '반차';
                        requestError = '';
                      }),
                    ),
                    if (requestError.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          requestError,
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.danger,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (compact)
                      Column(
                        children: [
                          ApprovalLeaveDateButton(
                            key: const ValueKey('leave-start-date-button'),
                            label: '시작일',
                            date: start,
                            onPressed: () => pickDate(true),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 17,
                              color: TheWeColor.black500,
                            ),
                          ),
                          ApprovalLeaveDateButton(
                            key: const ValueKey('leave-end-date-button'),
                            label: '종료일',
                            date: end,
                            onPressed: halfDay ? null : () => pickDate(false),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ApprovalLeaveDateButton(
                              key: const ValueKey('leave-start-date-button'),
                              date: start,
                              onPressed: () => pickDate(true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('~'),
                          ),
                          Expanded(
                            child: ApprovalLeaveDateButton(
                              key: const ValueKey('leave-end-date-button'),
                              date: end,
                              onPressed: halfDay ? null : () => pickDate(false),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reason,
                      maxLines: 3,
                      onChanged: (_) {
                        if (reasonError.isNotEmpty) {
                          setDialogState(() => reasonError = '');
                        }
                      },
                      decoration: InputDecoration(
                        labelText: '신청 사유 (필수)',
                        hintText: '휴가 사유를 입력하세요.',
                        errorText: reasonError.isEmpty ? null : reasonError,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  if (reason.text.trim().isEmpty) {
                    setDialogState(() => reasonError = '신청 사유를 입력해 주세요.');
                    return;
                  }
                  final requestedDays = halfDay
                      ? .5
                      : end.difference(start).inDays + 1.0;
                  if (requestedDays > state.remainingAnnualLeave) {
                    setDialogState(
                      () => requestError =
                          '${isMonthlyLeave ? '잔여 월차' : '잔여 연차'} ${approvalLeaveDays(state.remainingAnnualLeave)}를 초과했습니다.',
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('신청'),
              ),
            ],
          );
        },
      ),
    );
    if (submitted != true || !context.mounted) return;
    final days = halfDay ? .5 : end.difference(start).inDays + 1.0;
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .requestLeave(
          type: type,
          startDate: DateFormat('yyyy-MM-dd').format(start),
          endDate: DateFormat('yyyy-MM-dd').format(halfDay ? start : end),
          days: days,
          reason: reason.text.trim(),
        );
    showTheWeSnackBar(context, message: '휴가 신청이 등록되었습니다.');
  }

  Future<void> _showLeaveProgressDialog(
    BuildContext context,
    LeaveRequest request,
  ) {
    final legacyApprover = state.accounts
        .where((item) => item.id == 'ceo' || item.position.contains('대표'))
        .firstOrNull;
    final approvalLine = request.approvalLine.isEmpty
        ? [
            LeaveApprovalStep(
              userId: legacyApprover?.id ?? 'ceo',
              name: legacyApprover?.name ?? '-',
              department: legacyApprover?.department ?? '',
              position: legacyApprover?.position ?? '대표',
              status: request.ceoStatus,
            ),
          ]
        : request.approvalLine;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TheWeColor.surfaceAlt,
        title: const Text('결재 진행중'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.type} · ${request.startDate} ~ ${request.endDate}',
                style: TheWeTextStyle.subtitle,
              ),
              const SizedBox(height: 6),
              Text(
                request.reason,
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < approvalLine.length; index++) ...[
                ApprovalLeaveProgressRow(
                  role:
                      '${approvalLine[index].position.isEmpty ? '결재자' : approvalLine[index].position}${index == approvalLine.length - 1 ? ' · 최종 승인' : ''}',
                  name: approvalLine[index].name,
                  status: approvalLine[index].status,
                ),
                if (index != approvalLine.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              Text(
                '신청자의 부서에 설정된 휴가 결재라인 순서대로 전달됩니다.',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
