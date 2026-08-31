import 'approval_home_dependencies.dart';
import 'approval_home_calendar_day.dart';
import 'approval_home_calendar_dialog.dart';
import 'approval_home_calendar_models.dart';

class ApprovalHomeCalendarPanel extends StatefulWidget {
  const ApprovalHomeCalendarPanel({super.key});

  @override
  State<ApprovalHomeCalendarPanel> createState() =>
      _ApprovalHomeCalendarPanelState();
}

class _ApprovalHomeCalendarPanelState extends State<ApprovalHomeCalendarPanel> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final Map<DateTime, List<ApprovalCalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = DateUtils.dateOnly(_focusedDay);
    });
  }

  List<ApprovalCalendarEvent> _eventsForDay(DateTime day) {
    return _events[DateUtils.dateOnly(day)] ?? const [];
  }

  Future<void> _openAddEventDialog(DateTime day) async {
    final event = await showDialog<ApprovalCalendarEvent>(
      context: context,
      builder: (context) => ApprovalCalendarEventDialog(date: day),
    );

    if (event == null || !mounted) return;

    setState(() {
      final key = DateUtils.dateOnly(day);
      _events.putIfAbsent(key, () => []).add(event);
      _selectedDay = key;
      _focusedDay = key;
    });
  }

  Future<void> _openEventDetail(
    DateTime day,
    ApprovalCalendarEvent event,
  ) async {
    final action = await showDialog<ApprovalCalendarEventAction>(
      context: context,
      builder: (context) => TheWeModalSurface(
        maxWidth: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TheWeModalAlertIcon(
              icon: Icons.event_note_rounded,
              foregroundColor: TheWeColor.blue300,
              backgroundColor: TheWeColor.blueSurface,
            ),
            const SizedBox(height: 18),
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalCalendarDetailLine(
                  label: '날짜',
                  value: formatApprovalKoreanDate(day),
                ),
                ApprovalCalendarDetailLine(label: '시간', value: event.time),
                ApprovalCalendarDetailLine(label: '장소', value: event.place),
                ApprovalCalendarColorDetailLine(color: event.color),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(ApprovalCalendarEventAction.delete),
                  child: Text(
                    '삭제',
                    style: TheWeTextStyle.body.copyWith(color: TheWeColor.pink),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(ApprovalCalendarEventAction.edit),
                  child: const Text('수정'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: TheWeColor.blue300,
                  ),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == ApprovalCalendarEventAction.delete) {
      setState(() {
        final key = DateUtils.dateOnly(day);
        _events[key]?.remove(event);
        if (_events[key]?.isEmpty ?? false) _events.remove(key);
      });
      return;
    }

    if (action != ApprovalCalendarEventAction.edit) return;

    final edited = await showDialog<ApprovalCalendarEvent>(
      context: context,
      builder: (context) =>
          ApprovalCalendarEventDialog(date: day, initialEvent: event),
    );

    if (edited == null || !mounted) return;

    setState(() {
      final dayEvents = _events[DateUtils.dateOnly(day)];
      final index = dayEvents?.indexOf(event) ?? -1;
      if (index >= 0) dayEvents![index] = edited;
    });
  }

  ApprovalCalendarDayCard _dayCard(
    DateTime day,
    DateTime focusedDay, {
    bool? isCurrentMonth,
    bool? isToday,
    bool? isSelected,
  }) {
    return ApprovalCalendarDayCard(
      date: day,
      isCurrentMonth: isCurrentMonth ?? day.month == focusedDay.month,
      isToday: isToday ?? isSameDay(day, DateTime.now()),
      isSelected: isSelected ?? isSameDay(day, _selectedDay),
      events: _eventsForDay(day),
      onEventTap: (event) => _openEventDetail(day, event),
    );
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final rowHeight = compact ? 56.0 : 72.0;

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
                ApprovalCalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _moveMonth(-1),
                ),
                const SizedBox(width: 8),
                ApprovalCalendarNavButton(
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
            TableCalendar<ApprovalCalendarEvent>(
              key: const Key('approval-month-calendar'),
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
                setState(() {
                  _selectedDay = DateUtils.dateOnly(selectedDay);
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              calendarBuilders: CalendarBuilders<ApprovalCalendarEvent>(
                defaultBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay),
                todayBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay, isSelected: true),
                outsideBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay, isCurrentMonth: false),
                disabledBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay),
                holidayBuilder: (context, day, focusedDay) =>
                    _dayCard(day, focusedDay),
              ),
            ),
            const SizedBox(height: 12),
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
  final List<ApprovalCalendarEvent> events;
  final VoidCallback onAddEvent;
  final ValueChanged<ApprovalCalendarEvent> onEventTap;

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
