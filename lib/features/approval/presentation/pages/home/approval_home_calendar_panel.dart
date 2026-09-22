import 'approval_home_dependencies.dart';
import 'approval_home_calendar_day.dart';
import 'approval_home_calendar_dialog.dart';
import 'approval_home_calendar_models.dart';
import 'package:the_we_system/core/network/dio_provider.dart';

class ApprovalHomeCalendarPanel extends ConsumerStatefulWidget {
  const ApprovalHomeCalendarPanel({super.key});

  @override
  ConsumerState<ApprovalHomeCalendarPanel> createState() =>
      _ApprovalHomeCalendarPanelState();
}

class _ApprovalHomeCalendarPanelState
    extends ConsumerState<ApprovalHomeCalendarPanel> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final Map<DateTime, List<ApprovalCalendarEvent>> _events = {};
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final response = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/calendar/events');
      final rows = response.data?['events'] as List<dynamic>? ?? const [];
      if (!mounted) return;
      setState(() {
        _events.clear();
        for (final row in rows) {
          if (row is! Map) continue;
          final data = Map<String, dynamic>.from(row);
          final start = DateTime.tryParse(data['date']?.toString() ?? '');
          if (start == null) continue;
          final event = ApprovalCalendarEvent.fromJson(data);
          final end = event.endDate ?? start;
          for (
            var day = DateUtils.dateOnly(start);
            !day.isAfter(end);
            day = day.add(const Duration(days: 1))
          ) {
            _events.putIfAbsent(day, () => []).add(event);
          }
        }
        _loadError = null;
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = '공유 일정을 불러오지 못했습니다.');
    }
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

    try {
      await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/calendar/events',
            data: {
              'date': day.toIso8601String().substring(0, 10),
              'title': event.title,
              'time': event.time,
              'place': event.place,
              'colorKey': event.colorKey,
            },
          );
      await _loadEvents();
      if (mounted) {
        setState(() {
          _selectedDay = DateUtils.dateOnly(day);
          _focusedDay = DateUtils.dateOnly(day);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = '일정을 저장하지 못했습니다.');
    }
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
                ApprovalCalendarDetailLine(label: '작성자', value: event.authorName),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (event.kind == 'schedule' && _canEdit(event))
                  OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(ApprovalCalendarEventAction.delete),
                    child: Text(
                      '삭제',
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.pink,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                if (event.kind == 'schedule' && _canEdit(event))
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
      try {
        await ref
            .read(dioProvider)
            .delete<void>('/calendar/events/${event.id}');
        await _loadEvents();
      } catch (_) {
        if (mounted) setState(() => _loadError = '일정을 삭제하지 못했습니다.');
      }
      return;
    }

    if (action != ApprovalCalendarEventAction.edit) return;

    final edited = await showDialog<ApprovalCalendarEvent>(
      context: context,
      builder: (context) =>
          ApprovalCalendarEventDialog(date: day, initialEvent: event),
    );

    if (edited == null || !mounted) return;

    try {
      await ref
          .read(dioProvider)
          .patch<Map<String, dynamic>>(
            '/calendar/events/${event.id}',
            data: {
              'title': edited.title,
              'time': edited.time,
              'place': edited.place,
              'colorKey': edited.colorKey,
            },
          );
      await _loadEvents();
    } catch (_) {
      if (mounted) setState(() => _loadError = '일정을 수정하지 못했습니다.');
    }
  }

  bool _canEdit(ApprovalCalendarEvent event) {
    final user = ref
        .read(approvalDashboardControllerProvider)
        .asData
        ?.value
        .currentUser;
    return event.authorId == user?.id ||
        user?.isAdmin == true ||
        user?.isSystemAdministrator == true;
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
            Text('공유 캘린더', style: TheWeTextStyle.title),
            if (_loadError != null)
              Text(
                _loadError!,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.danger,
                ),
              ),
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
                    Text(event.authorName, style: TheWeTextStyle.caption),
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
