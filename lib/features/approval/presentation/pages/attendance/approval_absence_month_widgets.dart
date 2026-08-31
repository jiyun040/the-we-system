import 'approval_absence_dependencies.dart';
import 'approval_absence_company_table.dart';

class _MonthScheduleTag extends StatelessWidget {
  const _MonthScheduleTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TheWeTextStyle.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalMonthAttendanceGrid extends StatelessWidget {
  const ApprovalMonthAttendanceGrid({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final firstDay = DateTime(now.year, now.month, 1);
    final startOffset = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: startOffset));
    final cells = List.generate(
      42,
      (index) => startDate.add(Duration(days: index)),
    );

    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    const holidays = {6: '현충일'};

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                ),
              )
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: compact ? 5 : 10,
            crossAxisSpacing: compact ? 4 : 10,
            childAspectRatio: compact ? 0.62 : 0.95,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            final isCurrentMonth = date.month == now.month;
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isWeekend =
                date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday;
            final holiday = isCurrentMonth ? holidays[date.day] : null;
            final scheduleColor = holiday != null
                ? TheWeColor.pink
                : date.weekday == DateTime.sunday
                ? const Color(0xFF60A5FA)
                : date.weekday == DateTime.saturday
                ? const Color(0xFF93C5FD)
                : const Color(0xFF34D399);

            return Container(
              padding: EdgeInsets.all(compact ? 3 : 12),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? TheWeColor.blue300
                      : TheWeColor.black300.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: compact ? 27 : 30,
                      height: compact ? 27 : 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? TheWeColor.black900
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TheWeTextStyle.body.copyWith(
                          color: isToday
                              ? Colors.white
                              : !isCurrentMonth
                              ? TheWeColor.black500.withValues(alpha: 0.5)
                              : isWeekend || holiday != null
                              ? TheWeColor.pink
                              : TheWeColor.black900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 10),
                  if (compact)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: scheduleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  else if (holiday != null)
                    _MonthScheduleTag(label: holiday, color: TheWeColor.pink)
                  else if (date.weekday == DateTime.sunday)
                    _MonthScheduleTag(
                      label: '휴일',
                      color: const Color(0xFF60A5FA),
                    )
                  else if (date.weekday == DateTime.saturday)
                    _MonthScheduleTag(
                      label: '휴무',
                      color: const Color(0xFF93C5FD),
                    )
                  else
                    _MonthScheduleTag(
                      label: '정상근무',
                      color: const Color(0xFF34D399),
                    ),
                ],
              ),
            );
          },
        ),
        if (compact) ...[
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              ApprovalLegendDot(label: '정상근무', color: Color(0xFF34D399)),
              ApprovalLegendDot(label: '휴일', color: Color(0xFF60A5FA)),
              ApprovalLegendDot(label: '휴무', color: Color(0xFF93C5FD)),
              ApprovalLegendDot(label: '공휴일', color: TheWeColor.pink),
            ],
          ),
        ],
      ],
    );
  }
}

class ApprovalTimelineChart extends StatelessWidget {
  const ApprovalTimelineChart({
    super.key,
    required this.clockInTime,
    required this.clockOutTime,
    required this.requestCount,
  });

  final String? clockInTime;
  final String? clockOutTime;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final hourLabels = compact
        ? const [0, 4, 8, 12, 16, 20, 23]
        : List.generate(24, (index) => index);

    return Column(
      children: [
        Row(
          children: hourLabels
              .map(
                (hour) => Expanded(
                  child: Text(
                    hour.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TheWeColor.black300.withValues(alpha: 0.16),
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: List.generate(
                  24,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF93C5FD)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 26,
                child: Text(
                  '근무시작 ${clockInTime ?? '-'}',
                  style: TheWeTextStyle.caption,
                ),
              ),
              Positioned(
                right: 24,
                top: 26,
                child: Text(
                  '근무종료 ${clockOutTime ?? '-'}',
                  style: TheWeTextStyle.caption,
                ),
              ),
              Positioned(
                left: 24,
                bottom: 14,
                child: Text(
                  '상세 근로시간  소정 0h / 초과 $requestCount건',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ApprovalStatusMetricCard extends StatelessWidget {
  const ApprovalStatusMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
    this.width,
  });

  final String title;
  final String value;
  final String caption;
  final Color accent;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final card = Container(
      width: width,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? TheWeTextStyle.caption : TheWeTextStyle.body)
                .copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? TheWeTextStyle.title : TheWeTextStyle.pageTitle)
                .copyWith(color: accent),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            caption,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}
