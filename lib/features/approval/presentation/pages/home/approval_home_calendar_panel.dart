part of 'approval_home_page.dart';

class _PortalCalendarPanel extends StatefulWidget {
  const _PortalCalendarPanel();

  @override
  State<_PortalCalendarPanel> createState() => _PortalCalendarPanelState();
}

class _PortalCalendarPanelState extends State<_PortalCalendarPanel> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late final Map<DateTime, List<_PortalCalendarEvent>> _events;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateUtils.dateOnly(now);
    _selectedDay = DateUtils.dateOnly(now);
    _events = _seedEvents(now);
  }

  Map<DateTime, List<_PortalCalendarEvent>> _seedEvents(DateTime baseDate) {
    final year = baseDate.year;
    final month = baseDate.month;

    return {
      DateTime(year, month, 3): const [
        _PortalCalendarEvent(
          title: '세무 마감',
          time: '09:00',
          place: '회계팀',
          colorKey: 'blue',
        ),
      ],
      DateTime(year, month, 5): const [
        _PortalCalendarEvent(
          title: '주간 보고',
          time: '10:00',
          place: '회의실 A',
          colorKey: 'orange',
        ),
      ],
      DateTime(year, month, 8): const [
        _PortalCalendarEvent(
          title: '근태 점검',
          time: '14:00',
          place: '인사팀',
          colorKey: 'pink',
        ),
      ],
      DateTime(year, month, 14): const [
        _PortalCalendarEvent(
          title: '부서 회의',
          time: '09:30',
          place: '회의실 B',
          colorKey: 'blue',
        ),
        _PortalCalendarEvent(
          title: '문서 검수',
          time: '16:00',
          place: '전자결재',
          colorKey: 'orange',
        ),
      ],
      DateTime(year, month, 27): const [
        _PortalCalendarEvent(
          title: '교육 일정',
          time: '13:00',
          place: '교육장',
          colorKey: 'pink',
        ),
      ],
    };
  }

  List<_PortalCalendarEvent> _eventsForDay(DateTime day) {
    return _events[DateUtils.dateOnly(day)] ?? const [];
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = DateUtils.dateOnly(_focusedDay);
    });
  }

  Future<void> _openAddEventDialog(DateTime day) async {
    final event = await showDialog<_PortalCalendarEvent>(
      context: context,
      builder: (context) => _CalendarEventDialog(date: day),
    );

    if (event == null) {
      return;
    }

    setState(() {
      final key = DateUtils.dateOnly(day);
      _events.putIfAbsent(key, () => []).add(event);
      _selectedDay = key;
      _focusedDay = key;
    });
  }

  Future<void> _openEventDetail(
    DateTime day,
    _PortalCalendarEvent event,
  ) async {
    final action = await showDialog<_CalendarEventAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(event.title, style: TheWeTextStyle.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarDetailLine(label: '날짜', value: _formatKoreanDate(day)),
            _CalendarDetailLine(label: '시간', value: event.time),
            _CalendarDetailLine(label: '장소', value: event.place),
            _CalendarColorDetailLine(color: event.color),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_CalendarEventAction.delete),
            child: Text(
              '삭제',
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.pink),
            ),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pop(_CalendarEventAction.edit),
            child: const Text('수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
            child: const Text('닫기'),
          ),
        ],
      ),
    );

    if (action == _CalendarEventAction.delete) {
      setState(() {
        final key = DateUtils.dateOnly(day);
        _events[key]?.remove(event);
      });
      return;
    }

    if (action != _CalendarEventAction.edit) {
      return;
    }

    if (!mounted) {
      return;
    }

    final edited = await showDialog<_PortalCalendarEvent>(
      context: context,
      builder: (context) =>
          _CalendarEventDialog(date: day, initialEvent: event),
    );

    if (edited == null || !mounted) {
      return;
    }

    setState(() {
      final key = DateUtils.dateOnly(day);
      final dayEvents = _events[key];
      if (dayEvents == null) {
        return;
      }
      final index = dayEvents.indexOf(event);
      if (index == -1) {
        return;
      }
      dayEvents[index] = edited;
    });
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final rowHeight = compact ? 64.0 : 88.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('캘린더', style: TheWeTextStyle.title),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_focusedDay.year}년 ${_focusedDay.month}월',
                    style: TheWeTextStyle.title.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _moveMonth(-1),
                ),
                const SizedBox(width: 8),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _moveMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TheWeTextStyle.caption.copyWith(
                            color: label == '일'
                                ? TheWeColor.pink
                                : TheWeColor.black500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            TableCalendar<_PortalCalendarEvent>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              rowHeight: rowHeight,
              availableGestures: AvailableGestures.none,
              headerVisible: false,
              daysOfWeekVisible: false,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: _eventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                markerSize: 0,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                final day = DateUtils.dateOnly(selectedDay);
                setState(() {
                  _selectedDay = day;
                  _focusedDay = focusedDay;
                });
                if (!compact) {
                  _openAddEventDialog(day);
                }
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              calendarBuilders: CalendarBuilders<_PortalCalendarEvent>(
                defaultBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                todayBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: true,
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                selectedBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                outsideBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: false,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                disabledBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                holidayBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SelectedDayEvents(
              date: _selectedDay,
              events: _eventsForDay(_selectedDay),
              onAddEvent: () => _openAddEventDialog(_selectedDay),
              onEventTap: (event) => _openEventDetail(_selectedDay, event),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedDayEvents extends StatelessWidget {
  const _SelectedDayEvents({
    required this.date,
    required this.events,
    required this.onAddEvent,
    required this.onEventTap,
  });

  final DateTime date;
  final List<_PortalCalendarEvent> events;
  final VoidCallback onAddEvent;
  final ValueChanged<_PortalCalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Expanded(
          child: Text(
            '${date.month}월 ${date.day}일 일정',
            style: TheWeTextStyle.caption.copyWith(
              color: TheWeColor.black500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAddEvent,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('일정 추가'),
        ),
      ],
    );

    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Text(
            '등록된 일정이 없습니다.',
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onEventTap(event),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 28,
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TheWeTextStyle.body,
                      ),
                    ),
                    Text(event.time, style: TheWeTextStyle.caption),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
