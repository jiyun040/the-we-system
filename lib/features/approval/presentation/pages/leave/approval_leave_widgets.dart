import 'approval_leave_dependencies.dart';

class ApprovalLeaveHeader extends StatelessWidget {
  const ApprovalLeaveHeader({
    super.key,
    required this.userName,
    required this.onRequest,
  });
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

class ApprovalLeaveMetricCard extends StatelessWidget {
  const ApprovalLeaveMetricCard({
    super.key,
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

class ApprovalLeaveDateButton extends StatelessWidget {
  const ApprovalLeaveDateButton({
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

class ApprovalLeaveStatusChip extends StatelessWidget {
  const ApprovalLeaveStatusChip({super.key, required this.status, this.onTap});
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

class ApprovalMobileLeaveRequestCard extends StatelessWidget {
  const ApprovalMobileLeaveRequestCard({
    super.key,
    required this.request,
    required this.onStatusTap,
  });

  final LeaveRequest request;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: approvalLeaveSurfaceDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            ApprovalLeaveStatusChip(status: request.status, onTap: onStatusTap),
            const Spacer(),
            Text(
              approvalLeaveDays(request.days),
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

class ApprovalLeaveProgressRow extends StatelessWidget {
  const ApprovalLeaveProgressRow({
    super.key,
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

BoxDecoration approvalLeaveSurfaceDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: TheWeColor.black300.withValues(alpha: .25)),
  boxShadow: const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
  ],
);

String approvalLeaveDays(double value) => value == value.roundToDouble()
    ? '${value.toInt()}일'
    : '${value.toStringAsFixed(1)}일';
