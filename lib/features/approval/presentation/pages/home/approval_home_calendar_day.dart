import 'approval_home_dependencies.dart';
import 'approval_home_calendar_models.dart';

class ApprovalCalendarDayCard extends StatelessWidget {
  const ApprovalCalendarDayCard({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onEventTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<ApprovalCalendarEvent> events;
  final ValueChanged<ApprovalCalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tooSmallForDetails =
            constraints.maxWidth < 34 || constraints.maxHeight < 42;
        final veryCompact = constraints.maxWidth < 76;
        final textColor = isCurrentMonth
            ? TheWeColor.black900
            : TheWeColor.black500.withValues(alpha: 0.6);
        final dayText = Text(
          '${date.day}',
          style: TheWeTextStyle.caption.copyWith(
            color: isSelected ? TheWeColor.white : textColor,
            fontWeight: FontWeight.w700,
            fontSize: constraints.maxWidth < 34 ? 10 : null,
          ),
        );

        if (tooSmallForDetails) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? TheWeColor.black900
                  : isToday
                  ? const Color(0xFFE7ECFF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: dayText,
          );
        }

        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TheWeColor.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? TheWeColor.black900
                  : TheWeColor.black300.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TheWeColor.black900
                        : isToday
                        ? const Color(0xFFE7ECFF)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: dayText,
                ),
              ),
              const SizedBox(height: 6),
              if (events.isEmpty)
                const Spacer()
              else if (veryCompact)
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: events
                      .take(3)
                      .map(
                        (event) => Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: events
                        .take(2)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: InkWell(
                              onTap: () => onEventTap(event),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: event.color,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TheWeTextStyle.caption.copyWith(
                                        fontSize: 10,
                                        color: TheWeColor.black900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
