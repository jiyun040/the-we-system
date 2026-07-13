part of 'approval_absence_page.dart';

class _MyAttendanceSection extends StatelessWidget {
  const _MyAttendanceSection({
    required this.view,
    required this.user,
    required this.snapshot,
    required this.onChangeView,
    required this.onOpenRequest,
  });

  final AttendanceView view;
  final EmployeeAccount user;
  final AttendanceSnapshot snapshot;
  final ValueChanged<AttendanceView> onChangeView;
  final ValueChanged<AttendanceRequestKind> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final remainingHours = math.max(
      0,
      snapshot.weeklyRequiredHours - snapshot.weeklyWorkedHours,
    );
    final progress = snapshot.weeklyRequiredHours == 0
        ? 0.0
        : (snapshot.weeklyWorkedHours / snapshot.weeklyRequiredHours).clamp(
            0.0,
            1.0,
          );

    if (view == AttendanceView.monthly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '내 근태현황',
            subtitle: null,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${now.year}년 ${now.month}월',
                      style: TheWeTextStyle.title,
                    ),
                    _ModeToggle(
                      label: '주간',
                      selected: false,
                      onTap: () => onChangeView(AttendanceView.weekly),
                    ),
                    _ModeToggle(
                      label: '월간',
                      selected: true,
                      onTap: () => onChangeView(AttendanceView.monthly),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MonthAttendanceGrid(now: now),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: '승인요청내역',
            subtitle: null,
            child: _RequestTable(requests: snapshot.requests),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: '내 근태현황',
          subtitle: null,
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${_formatDate(weekStart)} ~ ${_formatDate(weekEnd)}',
                    style: TheWeTextStyle.title,
                  ),
                  _ModeToggle(
                    label: '주간',
                    selected: true,
                    onTap: () => onChangeView(AttendanceView.weekly),
                  ),
                  _ModeToggle(
                    label: '월간',
                    selected: false,
                    onTap: () => onChangeView(AttendanceView.monthly),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 900;
                  final summary = _SurfaceCard(
                    color: const Color(0xFFF8FCFE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주간누적 ${snapshot.weeklyWorkedHours.toStringAsFixed(1)}시간',
                          style: TheWeTextStyle.title.copyWith(
                            color: TheWeColor.blue300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: TheWeColor.blue100,
                            color: TheWeColor.blue300,
                          ),
                        ),
                      ],
                    ),
                  );
                  final stats = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricTile(
                        label: '잔여 근무일',
                        value: '${snapshot.remainingWorkDays}일/5일',
                        accent: TheWeColor.green,
                      ),
                      _MetricTile(
                        label: '잔여 근로시간',
                        value: '${remainingHours.toStringAsFixed(1)}h',
                        accent: TheWeColor.blue300,
                      ),
                      _MetricTile(
                        label: '총 근로시간',
                        value: snapshot.clockOutTime == null
                            ? '0h 00m'
                            : '8h 00m',
                        accent: TheWeColor.black900,
                      ),
                      _MetricTile(
                        label: '휴가',
                        value:
                            '${snapshot.annualLeaveUsed.toStringAsFixed(1)}일',
                        accent: TheWeColor.pink,
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      children: [summary, const SizedBox(height: 14), stats],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: summary),
                      const SizedBox(width: 14),
                      Expanded(flex: 7, child: stats),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '주간 근무 타임라인',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    label: '근무시작',
                    value: snapshot.clockInTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  _MetricTile(
                    label: '근무종료',
                    value: snapshot.clockOutTime ?? '-',
                    accent: TheWeColor.black900,
                  ),
                  _MetricTile(
                    label: '총 근로시간',
                    value: snapshot.clockOutTime == null
                        ? '0h 0m 0s'
                        : '8h 0m 0s',
                    accent: TheWeColor.blue300,
                  ),
                  _MetricTile(
                    label: '승인요청내역',
                    value: '${snapshot.requests.length}건',
                    accent: TheWeColor.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WeekStrip(now: now),
              const SizedBox(height: 16),
              _TimelineChart(
                clockInTime: snapshot.clockInTime,
                clockOutTime: snapshot.clockOutTime,
                requestCount: snapshot.requests.length,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LegendDot(label: '정상', color: const Color(0xFF9CA3AF)),
                  _LegendDot(label: '근태이상', color: TheWeColor.pink),
                  _LegendDot(label: '수정', color: const Color(0xFF8B5CF6)),
                  TextButton.icon(
                    onPressed: () =>
                        onOpenRequest(AttendanceRequestKind.workTimeCorrection),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: Text(
                      '근무시간 수정 신청',
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.blue300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '승인요청내역',
          subtitle: null,
          child: _RequestTable(requests: snapshot.requests),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '근무상태 변경 이력',
          subtitle: null,
          child: snapshot.delegations.isEmpty
              ? Text(
                  '등록된 근무상태 변경 이력이 없습니다.',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                )
              : Column(
                  children: snapshot.delegations
                      .map((item) => _DelegationItem(item: item))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _CompanyAttendanceSection extends StatefulWidget {
  const _CompanyAttendanceSection({required this.rows});

  final List<_CompanyAttendanceRowData> rows;

  @override
  State<_CompanyAttendanceSection> createState() =>
      _CompanyAttendanceSectionState();
}

class _CompanyAttendanceSectionState extends State<_CompanyAttendanceSection> {
  DateTime _focusedDate = DateTime(2026, 6, 29);
  DateTime _periodStart = DateTime(2026, 6, 1);
  DateTime _periodEnd = DateTime(2026, 6, 30);
  bool _periodMode = false;
  String _employmentStatus = '재직';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
              builder: (context) => _MobileDateRangeSheet(
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
      return '${_formatDate(_periodStart)} ~ ${_formatDate(_periodEnd)}';
    }

    return _formatDate(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleRows = widget.rows.where((row) {
      if (_employmentStatus != '재직') {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return row.account.id.toLowerCase().contains(normalizedQuery) ||
          row.account.name.toLowerCase().contains(normalizedQuery) ||
          row.account.department.toLowerCase().contains(normalizedQuery);
    }).toList();
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
        _SectionCard(
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
                      _ModeToggle(
                        label: '일자별',
                        selected: !_periodMode,
                        onTap: () => _setPeriodMode(false),
                      ),
                      const SizedBox(width: 8),
                      _ModeToggle(
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
                      _StatusMetricCard(
                        title: '정상',
                        value: '$normalCount명',
                        caption: '전체 ${widget.rows.length}명 기준',
                        accent: TheWeColor.green,
                      ),
                      _StatusMetricCard(
                        title: '지각',
                        value: '$lateCount명',
                        caption: '시간 및 기록 이상',
                        accent: TheWeColor.pink,
                      ),
                      _StatusMetricCard(
                        title: '조퇴',
                        value: '0명',
                        caption: '현재 집계 없음',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '휴게시간 부족',
                        value: '0명',
                        caption: '정상 기준 충족',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '종일근무상태',
                        value:
                            '${widget.rows.where((row) => row.snapshot.isClockedIn).length}명',
                        caption: '근무중 직원',
                        accent: TheWeColor.black900,
                      ),
                      _StatusMetricCard(
                        title: '휴가 중 출근',
                        value: '0명',
                        caption: '이상 케이스',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
                        title: '퇴근 누락',
                        value: '$missingClockOutCount명',
                        caption: '퇴근 미체크',
                        accent: const Color(0xFFF97316),
                      ),
                      _StatusMetricCard(
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
        _SectionCard(
          title: '직원 목록',
          subtitle: null,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 520;
                  final filter = SizedBox(
                    width: stacked ? double.infinity : 140,
                    child: TheWeDropdown<String>(
                      value: _employmentStatus,
                      items: const ['재직', '휴직', '퇴사'],
                      labelBuilder: (value) => value,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _employmentStatus = value);
                        }
                      },
                    ),
                  );
                  final search = CustomTextFormField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: '부서, 사번, 이름을 검색하세요.',
                      prefixIcon: Icon(Icons.search),
                    ),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filter,
                        const SizedBox(height: 10),
                        search,
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
                      filter,
                      const SizedBox(width: 12),
                      Expanded(child: search),
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
              _CompanyAttendanceTable(rows: visibleRows),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileDateRangeSheet extends StatefulWidget {
  const _MobileDateRangeSheet({
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_MobileDateRangeSheet> createState() => _MobileDateRangeSheetState();
}

class _MobileDateRangeSheetState extends State<_MobileDateRangeSheet> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _focusedMonth;
  bool _editingStart = true;

  @override
  void initState() {
    super.initState();
    _start = _dateOnly(widget.initialStart);
    _end = _dateOnly(widget.initialEnd);
    _focusedMonth = DateTime(_start.year, _start.month);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _selectDay(DateTime day) {
    setState(() {
      if (_editingStart) {
        _start = day;
        if (_end.isBefore(_start)) {
          _end = day;
        }
        _editingStart = false;
        return;
      }

      if (day.isBefore(_start)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _moveMonth(int direction) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + direction,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: TheWeColor.black300.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text('조회 기간 선택', style: TheWeTextStyle.title),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateRangeField(
                      label: '시작일',
                      date: _start,
                      selected: _editingStart,
                      onTap: () => setState(() => _editingStart = true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: TheWeColor.black500,
                    ),
                  ),
                  Expanded(
                    child: _DateRangeField(
                      label: '종료일',
                      date: _end,
                      selected: !_editingStart,
                      onTap: () => setState(() => _editingStart = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _moveMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.subtitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _moveMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Row(
                children: weekDays
                    .map(
                      (label) => Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TheWeTextStyle.caption.copyWith(
                            color: label == '일' || label == '토'
                                ? TheWeColor.pink
                                : TheWeColor.black500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final dayNumber = index - startOffset + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final day = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month,
                      dayNumber,
                    );
                    final selected =
                        _sameDay(day, _start) || _sameDay(day, _end);
                    final inRange = !day.isBefore(_start) && !day.isAfter(_end);

                    return InkWell(
                      onTap: () => _selectDay(day),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? TheWeColor.blue300
                              : inRange
                              ? TheWeColor.blue100.withValues(alpha: 0.55)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$dayNumber',
                          style: TheWeTextStyle.body.copyWith(
                            color: selected
                                ? Colors.white
                                : TheWeColor.black900,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: _start, end: _end)),
                      style: FilledButton.styleFrom(
                        backgroundColor: TheWeColor.blue300,
                      ),
                      child: const Text('적용'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TheWeColor.blueSurface : TheWeColor.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? TheWeColor.blue300
                : TheWeColor.black300.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 3),
            Text(_formatDate(date), style: TheWeTextStyle.body),
          ],
        ),
      ),
    );
  }
}
