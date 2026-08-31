import 'approval_absence_dependencies.dart';
import 'approval_absence_seed.dart';

class ApprovalMobileDateRangeSheet extends StatefulWidget {
  const ApprovalMobileDateRangeSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<ApprovalMobileDateRangeSheet> createState() =>
      _MobileDateRangeSheetState();
}

class _MobileDateRangeSheetState extends State<ApprovalMobileDateRangeSheet> {
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
            Text(formatApprovalDate(date), style: TheWeTextStyle.body),
          ],
        ),
      ),
    );
  }
}
