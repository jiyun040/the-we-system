import 'approval_home_dependencies.dart';
import 'approval_home_calendar_day.dart';
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
      events: const [],
      onEventTap: (_) {},
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
              eventLoader: (_) => const [],
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
            Text(
              '${_selectedDay.month}월 ${_selectedDay.day}일 일정',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '등록된 일정이 없습니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ],
        );
      },
    );
  }
}
