import 'approval_absence_dependencies.dart';
import 'approval_absence_cards.dart';
import 'approval_absence_company_table.dart';
import 'approval_absence_date_range.dart';
import 'approval_absence_month_widgets.dart';
import 'approval_absence_seed.dart';

enum _AttendanceDirectoryMode { all, department }

class ApprovalCompanyAttendanceSection extends StatefulWidget {
  const ApprovalCompanyAttendanceSection({super.key, required this.rows});

  final List<ApprovalCompanyAttendanceRowData> rows;

  @override
  State<ApprovalCompanyAttendanceSection> createState() =>
      _CompanyAttendanceSectionState();
}

class _CompanyAttendanceSectionState
    extends State<ApprovalCompanyAttendanceSection> {
  DateTime _focusedDate = DateTime(2026, 6, 29);
  DateTime _periodStart = DateTime(2026, 6, 1);
  DateTime _periodEnd = DateTime(2026, 6, 30);
  bool _periodMode = false;
  _AttendanceDirectoryMode _directoryMode = _AttendanceDirectoryMode.all;
  String? _department;

  Widget _directoryChip({
    required Key key,
    required String label,
    required _AttendanceDirectoryMode mode,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: _directoryMode == mode,
      onSelected: (_) => setState(() => _directoryMode = mode),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _moveDate(int direction) {
    setState(() {
      if (_periodMode) {
        final dayCount = _periodEnd.difference(_periodStart).inDays + 1;
        final offset = Duration(days: dayCount * direction);
        _periodStart = _periodStart.add(offset);
        _periodEnd = _periodEnd.add(offset);
      } else {
        _focusedDate = _focusedDate.add(Duration(days: direction));
      }
    });
  }

  Future<void> _pickDate() async {
    if (_periodMode) {
      final isPhone = MediaQuery.sizeOf(context).width < 520;
      final range = isPhone
          ? await showModalBottomSheet<DateTimeRange>(
              context: context,
              isScrollControlled: true,
              backgroundColor: TheWeColor.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (context) => ApprovalMobileDateRangeSheet(
                initialStart: _periodStart,
                initialEnd: _periodEnd,
              ),
            )
          : await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              initialDateRange: DateTimeRange(
                start: _periodStart,
                end: _periodEnd,
              ),
              helpText: '조회 기간 선택',
            );
      if (range != null && mounted) {
        setState(() {
          _periodStart = range.start;
          _periodEnd = range.end;
        });
      }
      return;
    }

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _focusedDate,
      helpText: '조회 일자 선택',
    );
    if (date != null && mounted) {
      setState(() => _focusedDate = date);
    }
  }

  Future<void> _setPeriodMode(bool periodMode) async {
    setState(() => _periodMode = periodMode);
    if (periodMode) {
      await _pickDate();
    }
  }

  String get _dateLabel {
    if (_periodMode) {
      return '${formatApprovalDate(_periodStart)} ~ ${formatApprovalDate(_periodEnd)}';
    }

    return formatApprovalDate(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        widget.rows
            .map((row) => row.account.department.trim())
            .where((department) => department.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final selectedDepartment = departments.contains(_department)
        ? _department
        : departments.firstOrNull;
    final visibleRows =
        widget.rows
            .where(
              (row) =>
                  _directoryMode == _AttendanceDirectoryMode.all ||
                  row.account.department.trim() == selectedDepartment,
            )
            .toList()
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a.account.hireDate);
            final bDate = DateTime.tryParse(b.account.hireDate);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            final dateComparison = aDate.compareTo(bDate);
            return dateComparison == 0
                ? a.account.name.compareTo(b.account.name)
                : dateComparison;
          });
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
        ApprovalAttendanceSectionCard(
          title: '전사 근태현황',
          subtitle: null,
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _moveDate(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _dateLabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TheWeTextStyle.title,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _moveDate(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ApprovalModeToggle(
                        label: '일자별',
                        selected: !_periodMode,
                        onTap: () => _setPeriodMode(false),
                      ),
                      const SizedBox(width: 8),
                      ApprovalModeToggle(
                        label: '기간별',
                        selected: _periodMode,
                        onTap: () => _setPeriodMode(true),
                      ),
                    ],
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
                    childAspectRatio: constraints.maxWidth < 520 ? 1.08 : 1.65,
                    children: [
                      ApprovalStatusMetricCard(
                        title: '정상',
                        value: '$normalCount명',
                        caption: '전체 ${widget.rows.length}명 기준',
                        accent: TheWeColor.green,
                      ),
                      ApprovalStatusMetricCard(
                        title: '지각',
                        value: '$lateCount명',
                        caption: '시간 및 기록 이상',
                        accent: TheWeColor.pink,
                      ),
                      ApprovalStatusMetricCard(
                        title: '조퇴',
                        value: '0명',
                        caption: '현재 집계 없음',
                        accent: const Color(0xFFF97316),
                      ),
                      ApprovalStatusMetricCard(
                        title: '휴게시간 부족',
                        value: '0명',
                        caption: '정상 기준 충족',
                        accent: const Color(0xFFF97316),
                      ),
                      ApprovalStatusMetricCard(
                        title: '종일근무상태',
                        value:
                            '${widget.rows.where((row) => row.snapshot.isClockedIn).length}명',
                        caption: '근무중 직원',
                        accent: TheWeColor.black900,
                      ),
                      ApprovalStatusMetricCard(
                        title: '휴가 중 출근',
                        value: '0명',
                        caption: '이상 케이스',
                        accent: const Color(0xFFF97316),
                      ),
                      ApprovalStatusMetricCard(
                        title: '퇴근 누락',
                        value: '$missingClockOutCount명',
                        caption: '퇴근 미체크',
                        accent: const Color(0xFFF97316),
                      ),
                      ApprovalStatusMetricCard(
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
        ApprovalAttendanceSectionCard(
          title: '직원 목록',
          subtitle: null,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 520;
                  final filter = SizedBox(
                    width: stacked ? double.infinity : 140,
                    child: Wrap(
                      key: const ValueKey('attendance-directory-filter'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _directoryChip(
                          key: const ValueKey('attendance-filter-all'),
                          label: '전체',
                          mode: _AttendanceDirectoryMode.all,
                        ),
                        _directoryChip(
                          key: const ValueKey('attendance-filter-department'),
                          label: '부서별',
                          mode: _AttendanceDirectoryMode.department,
                        ),
                        if (_directoryMode ==
                            _AttendanceDirectoryMode.department)
                          TheWeDropdown<String>(
                            key: const ValueKey('attendance-department-filter'),
                            width: 180,
                            value: selectedDepartment,
                            items: departments,
                            labelBuilder: (value) => value,
                            onChanged: (value) =>
                                setState(() => _department = value),
                          ),
                      ],
                    ),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filter,
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('엑셀 다운로드'),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: filter),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('엑셀 다운로드'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ApprovalCompanyAttendanceTable(rows: visibleRows),
            ],
          ),
        ),
      ],
    );
  }
}
