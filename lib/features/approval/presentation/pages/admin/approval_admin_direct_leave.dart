import 'approval_admin_dependencies.dart';

class _AdminDirectLeaveDraft {
  const _AdminDirectLeaveDraft({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
  });

  final String type;
  final String startDate;
  final String endDate;
  final double days;
  final String reason;
}

Future<void> showAdminDirectLeaveDialog(
  BuildContext context,
  WidgetRef ref,
  EmployeeAccount account,
) async {
  final current = ref.read(approvalDashboardControllerProvider).requireValue;
  final isMonthly = current.isUnderOneYear(account);
  final types = isMonthly
      ? const ['월차', '반차', '경조 휴가', '휴가']
      : const ['연차', '반차', '경조 휴가', '휴가'];
  var type = types.first;
  var start = DateTime.now();
  var end = start;
  var reason = '';
  var error = '';

  final draft = await showDialog<_AdminDirectLeaveDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final halfDay = type == '반차';
        final stackDates = MediaQuery.sizeOf(context).width < 600;

        Future<void> pickDate(bool startDate) async {
          final picked = await showTheWeDatePicker(
            context,
            initialDate: startDate ? start : end,
            firstDate: DateTime(2000),
            lastDate: DateTime(DateTime.now().year + 2, 12, 31),
            title: startDate ? '휴가 시작일 선택' : '휴가 종료일 선택',
            dialogKey: const ValueKey('admin-leave-date-picker'),
          );
          if (picked == null) return;
          setDialogState(() {
            error = '';
            if (startDate) {
              start = picked;
              if (end.isBefore(start) || halfDay) end = start;
            } else {
              end = picked;
            }
          });
        }

        return AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text('${account.name} 휴가 직접 등록'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '별도 결재 없이 즉시 승인 완료 처리되며 잔여 휴가에서 차감됩니다.',
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TheWeDropdown<String>(
                    value: type,
                    width: double.infinity,
                    items: types,
                    labelBuilder: (value) => value,
                    onChanged: (value) => setDialogState(() {
                      type = value ?? types.first;
                      if (type == '반차') end = start;
                      error = '';
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (stackDates)
                    Column(
                      key: const ValueKey('admin-direct-leave-date-layout'),
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey(
                              'admin-direct-start-date-button',
                            ),
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              '시작일  ${DateFormat('yyyy-MM-dd').format(start)}',
                              maxLines: 1,
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 17,
                            color: TheWeColor.black500,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('admin-direct-end-date-button'),
                            onPressed: halfDay ? null : () => pickDate(false),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              '종료일  ${DateFormat('yyyy-MM-dd').format(end)}',
                              maxLines: 1,
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      key: const ValueKey('admin-direct-leave-date-layout'),
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey(
                              'admin-direct-start-date-button',
                            ),
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(DateFormat('yyyy-MM-dd').format(start)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('~'),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('admin-direct-end-date-button'),
                            onPressed: halfDay ? null : () => pickDate(false),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(DateFormat('yyyy-MM-dd').format(end)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('admin-direct-leave-reason'),
                    maxLines: 3,
                    onChanged: (value) {
                      reason = value;
                      if (error.isNotEmpty) {
                        setDialogState(() => error = '');
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '관리자 등록 사유 (필수)',
                      hintText: '결재 없이 반영하는 사유를 입력하세요.',
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const ValueKey('admin-direct-leave-submit'),
              onPressed: () {
                final days = halfDay ? .5 : end.difference(start).inDays + 1.0;
                if (reason.trim().isEmpty) {
                  setDialogState(() => error = '관리자 등록 사유를 입력해 주세요.');
                  return;
                }
                if (days > current.remainingAnnualLeaveFor(account)) {
                  setDialogState(
                    () => error =
                        '잔여 휴가 ${adminLeaveDays(current.remainingAnnualLeaveFor(account))}를 초과했습니다.',
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _AdminDirectLeaveDraft(
                    type: type,
                    startDate: DateFormat('yyyy-MM-dd').format(start),
                    endDate: DateFormat(
                      'yyyy-MM-dd',
                    ).format(halfDay ? start : end),
                    days: days,
                    reason: reason.trim(),
                  ),
                );
              },
              child: const Text('즉시 반영'),
            ),
          ],
        );
      },
    ),
  );
  if (draft == null || !context.mounted) return;
  final message = ref
      .read(approvalDashboardControllerProvider.notifier)
      .addLeaveForEmployee(
        userId: account.id,
        type: draft.type,
        startDate: draft.startDate,
        endDate: draft.endDate,
        days: draft.days,
        reason: draft.reason,
      );
  if (!context.mounted) return;
  if (message != null) {
    showTheWeSnackBar(context, message: message, type: TheWeSnackBarType.error);
  } else {
    showTheWeSnackBar(context, message: '${account.name}님의 휴가가 즉시 반영되었습니다.');
  }
}

class AdminEmployeeLeaveMetric extends StatelessWidget {
  const AdminEmployeeLeaveMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(14),
    decoration: adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 5),
        Text(value, style: TheWeTextStyle.subtitle),
      ],
    ),
  );
}

String adminLeaveDays(double value) => value == value.roundToDouble()
    ? '${value.toInt()}일'
    : '${value.toStringAsFixed(1)}일';

class AdminMetric extends StatelessWidget {
  const AdminMetric({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final compact = width < 220;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: width,
          padding: EdgeInsets.all(compact ? 13 : 20),
          decoration: adminSurface(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: TheWeColor.blue300,
                    size: compact ? 22 : 24,
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
              SizedBox(height: compact ? 9 : 16),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                  fontSize: compact ? 12 : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: compact
                    ? TheWeTextStyle.metric.copyWith(fontSize: 24)
                    : TheWeTextStyle.metric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration adminSurface() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: TheWeColor.black300.withValues(alpha: .22)),
  boxShadow: const [
    BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
  ],
);

Widget adminDivider({double height = 1}) => Divider(
  height: height,
  thickness: 1,
  color: TheWeColor.black300.withValues(alpha: .2),
);

Future<String?> requestAdminOtp(BuildContext context) async {
  final controller = TextEditingController();
  final mobile = MediaQuery.sizeOf(context).width < 600;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 22 : 40,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      title: const Text('OTP 2차 인증'),
      content: SizedBox(
        width: mobile ? double.maxFinite : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 OTP 앱에 표시된 6자리 번호를 입력하세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP 인증번호'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('인증'),
        ),
      ],
    ),
  );
}
