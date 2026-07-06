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
  bool _periodMode = false;

  void _moveDate(int direction) {
    setState(() {
      _focusedDate = _periodMode
          ? DateTime(_focusedDate.year, _focusedDate.month + direction)
          : _focusedDate.add(Duration(days: direction));
    });
  }

  String get _dateLabel {
    if (_periodMode) {
      final firstDay = DateTime(_focusedDate.year, _focusedDate.month);
      final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
      return '${_formatDate(firstDay)} ~ ${_formatDate(lastDay)}';
    }

    return _formatDate(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
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
              Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _moveDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(_dateLabel, style: TheWeTextStyle.title),
                  IconButton(
                    onPressed: () => _moveDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  _ModeToggle(
                    label: '일자별',
                    selected: !_periodMode,
                    onTap: () => setState(() => _periodMode = false),
                  ),
                  _ModeToggle(
                    label: '기간별',
                    selected: _periodMode,
                    onTap: () => setState(() => _periodMode = true),
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
                    child: DropdownButtonFormField<String>(
                      initialValue: '재직',
                      items: const [
                        DropdownMenuItem(value: '재직', child: Text('재직')),
                        DropdownMenuItem(value: '휴직', child: Text('휴직')),
                        DropdownMenuItem(value: '퇴사', child: Text('퇴사')),
                      ],
                      onChanged: (_) {},
                    ),
                  );
                  final search = const TextField(
                    decoration: InputDecoration(
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
              _CompanyAttendanceTable(rows: widget.rows),
            ],
          ),
        ),
      ],
    );
  }
}
