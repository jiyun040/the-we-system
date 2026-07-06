part of 'approval_absence_page.dart';

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
        if (constraints.maxWidth < 640) {
          return Column(
            children: rows
                .map(
                  (row) => _MobileDataCard(
                    entries: [
                      MapEntry('사번', row.account.id),
                      MapEntry('사원명', row.account.name),
                      MapEntry('부서명', row.account.department),
                      MapEntry('근무그룹', row.snapshot.workPolicy),
                      MapEntry('출근시간', row.snapshot.clockInTime ?? '-'),
                      MapEntry('퇴근시간', row.snapshot.clockOutTime ?? '-'),
                      MapEntry(
                        '총 근로시간',
                        row.snapshot.clockOutTime == null
                            ? '0h 0m 0s'
                            : '8h 0m 0s',
                      ),
                      MapEntry(
                        '휴가',
                        '${row.snapshot.annualLeaveUsed.toStringAsFixed(1)}일',
                      ),
                      MapEntry(
                        '휴일대체',
                        row.snapshot.delegations.isEmpty ? '-' : '신청중',
                      ),
                      MapEntry('근태이상', row.anomalyLabel),
                    ],
                  ),
                )
                .toList(),
          );
        }

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
