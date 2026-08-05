import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';
import 'package:the_we_system/common/components/the_we_date_picker.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class ApprovalLeavePage extends ConsumerWidget {
  const ApprovalLeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(approvalDashboardControllerProvider);
    return Scaffold(
      backgroundColor: TheWeColor.white,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 3)
          : null,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) =>
            const Center(child: Text('휴가 정보를 불러오지 못했습니다.')),
        data: (state) {
          final dashboard = state.dashboard;
          final sidebar = SideBar(
            frequentForms: dashboard.frequentForms,
            pendingDocument: dashboard.pendingCount,
            receiveDocument: dashboard.receivedCount,
            openPendingDocument: dashboard.referenceCount,
            scheduledDocument: dashboard.scheduledCount,
          );
          final content = _LeaveContent(state: state);
          if (MediaQuery.sizeOf(context).width < 520) return content;
          return Row(
            children: [
              sidebar,
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _LeaveContent extends ConsumerWidget {
  const _LeaveContent({required this.state});
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
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 520 ? 18 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeaveHeader(
                  userName: state.currentUser?.name ?? '',
                  onRequest: () => _showLeaveRequestDialog(context, ref),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: EdgeInsets.all(mobile ? 16 : 24),
                  decoration: _surfaceDecoration(),
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
                              _MetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveEntitlementLabelFor(
                                  state.currentUser,
                                ),
                                value: _days(total),
                                color: TheWeColor.blue300,
                              ),
                              _MetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveUsedLabelFor(
                                  state.currentUser,
                                ),
                                value: _days(used),
                                color: TheWeColor.pink,
                              ),
                              _MetricCard(
                                width: width,
                                compact: compactGrid,
                                label: state.leaveRemainingLabelFor(
                                  state.currentUser,
                                ),
                                value: _days(remaining),
                                color: TheWeColor.green,
                              ),
                              _MetricCard(
                                width: width,
                                compact: compactGrid,
                                label: '승인 대기',
                                value: _days(pending),
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
                    decoration: _surfaceDecoration(),
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
                          child: _MobileLeaveRequestCard(
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
                            _StatusChip(
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
                            Text(_days(request.days)),
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
                          _LeaveDateButton(
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
                          _LeaveDateButton(
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
                            child: _LeaveDateButton(
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
                            child: _LeaveDateButton(
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
                          '${isMonthlyLeave ? '잔여 월차' : '잔여 연차'} ${_days(state.remainingAnnualLeave)}를 초과했습니다.',
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
              _LeaveApprovalProgressRow(
                role: '대표',
                name: '조상훈',
                status: request.ceoStatus,
              ),
              const SizedBox(height: 14),
              Text(
                '신청 즉시 대표 결재함으로 전달됩니다.',
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

class _LeaveHeader extends StatelessWidget {
  const _LeaveHeader({required this.userName, required this.onRequest});
  final String userName;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 520;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('휴가 현황', style: TheWeTextStyle.pageTitle),
        const SizedBox(height: 4),
        Text(
          '$userName님의 연차와 신청 내역을 확인하세요.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
      ],
    );
    final button = FilledButton.icon(
      onPressed: onRequest,
      icon: const Icon(Icons.add),
      label: const Text('휴가 신청'),
      style: FilledButton.styleFrom(backgroundColor: TheWeColor.black900),
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TheWeBackButton(),
              Expanded(child: title),
            ],
          ),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: button),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        button,
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });
  final double width;
  final String label;
  final String value;
  final Color color;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: BoxConstraints(minHeight: compact ? 108 : 0),
    padding: EdgeInsets.all(compact ? 14 : 18),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        SizedBox(height: compact ? 5 : 8),
        Text(
          value,
          style: TheWeTextStyle.metric.copyWith(
            color: color,
            fontSize: compact ? 28 : null,
          ),
        ),
      ],
    ),
  );
}

class _LeaveDateButton extends StatelessWidget {
  const _LeaveDateButton({
    super.key,
    required this.date,
    required this.onPressed,
    this.label,
  });

  final DateTime date;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_outlined),
      label: Text(
        '${label == null ? '' : '$label  '}${DateFormat('yyyy-MM-dd').format(date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.onTap});
  final String status;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = status == '승인완료'
        ? TheWeColor.green
        : status == '반려'
        ? TheWeColor.danger
        : Colors.orange;
    return ActionChip(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: color.withValues(alpha: .1),
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status, style: TheWeTextStyle.caption.copyWith(color: color)),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.chevron_right, size: 15, color: color),
          ],
        ],
      ),
    );
  }
}

class _MobileLeaveRequestCard extends StatelessWidget {
  const _MobileLeaveRequestCard({
    required this.request,
    required this.onStatusTap,
  });

  final LeaveRequest request;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: _surfaceDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            _StatusChip(status: request.status, onTap: onStatusTap),
            const Spacer(),
            Text(
              _days(request.days),
              style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
            ),
          ],
        ),
        const Divider(height: 18, color: Color(0xFFE1E4E8)),
        _MobileLeaveInfoRow(label: '휴가 종류', value: request.type),
        const SizedBox(height: 9),
        _MobileLeaveInfoRow(
          label: '기간',
          value: '${request.startDate} ~ ${request.endDate}',
        ),
        const SizedBox(height: 9),
        _MobileLeaveInfoRow(label: '신청 사유', value: request.reason, maxLines: 2),
      ],
    ),
  );
}

class _MobileLeaveInfoRow extends StatelessWidget {
  const _MobileLeaveInfoRow({
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

class _LeaveApprovalProgressRow extends StatelessWidget {
  const _LeaveApprovalProgressRow({
    required this.role,
    required this.name,
    required this.status,
  });

  final String role;
  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    final completed = status == '완료';
    final active = status == '진행중';
    final rejected = status == '반려';
    final color = rejected
        ? TheWeColor.danger
        : completed
        ? TheWeColor.green
        : active
        ? TheWeColor.blue300
        : TheWeColor.black300;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(
              completed
                  ? Icons.check
                  : rejected
                  ? Icons.close
                  : Icons.hourglass_top,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('$role $name', style: TheWeTextStyle.subtitle)),
          Text(
            status,
            style: TheWeTextStyle.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _surfaceDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: TheWeColor.black300.withValues(alpha: .25)),
  boxShadow: const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
  ],
);

String _days(double value) => value == value.roundToDouble()
    ? '${value.toInt()}일'
    : '${value.toStringAsFixed(1)}일';
