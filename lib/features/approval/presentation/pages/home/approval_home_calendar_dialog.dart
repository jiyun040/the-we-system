part of 'approval_home_page.dart';

class _CalendarEventDialog extends StatefulWidget {
  const _CalendarEventDialog({required this.date, this.initialEvent});

  final DateTime date;
  final _PortalCalendarEvent? initialEvent;

  @override
  State<_CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<_CalendarEventDialog> {
  final titleController = TextEditingController();
  final placeController = TextEditingController();
  String colorKey = 'blue';
  int hour = 9;
  int minute = 0;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    if (initialEvent == null) {
      return;
    }

    titleController.text = initialEvent.title;
    placeController.text = initialEvent.place == '장소 미정'
        ? ''
        : initialEvent.place;
    colorKey = initialEvent.colorKey;
    final parts = initialEvent.time.split(':');
    if (parts.length == 2) {
      hour = int.tryParse(parts.first) ?? 9;
      minute = int.tryParse(parts.last) ?? 0;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;

    return TheWeModalSurface(
      maxWidth: 480,
      width: isPhone ? screen.width - 40 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title:
                '${_formatKoreanDate(widget.date)} 일정 ${widget.initialEvent == null ? '추가' : '수정'}',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isPhone ? screen.width - 96 : 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarTextField(
                    label: '일정 이름',
                    controller: titleController,
                  ),
                  TheWeGaps.verticalLg,
                  Text('시간', style: TheWeTextStyle.body),
                  TheWeGaps.verticalSm,
                  _CalendarTimeSelector(
                    hour: hour,
                    minute: minute,
                    onChanged: (nextHour, nextMinute) {
                      setState(() {
                        hour = nextHour;
                        minute = nextMinute;
                      });
                    },
                  ),
                  TheWeGaps.verticalLg,
                  _CalendarTextField(label: '장소', controller: placeController),
                  TheWeGaps.verticalLg,
                  Text('색상', style: TheWeTextStyle.body),
                  TheWeGaps.verticalSm,
                  Wrap(
                    spacing: 12,
                    children: ['blue', 'orange', 'pink']
                        .map(
                          (item) => _CalendarColorChoice(
                            color: _calendarColor(item),
                            selected: colorKey == item,
                            onTap: () => setState(() => colorKey = item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: widget.initialEvent == null ? '추가' : '수정',
            secondaryLabel: '취소',
            primaryColor: TheWeColor.blue300,
            onSecondaryPressed: () => Navigator.of(context).pop(),
            onPrimaryPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                _PortalCalendarEvent(
                  title: title,
                  time:
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  place: placeController.text.trim().isEmpty
                      ? '장소 미정'
                      : placeController.text.trim(),
                  colorKey: colorKey,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarTimeSelector extends StatelessWidget {
  const _CalendarTimeSelector({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _TimeWheelColumn(
              value: hour,
              max: 23,
              onChanged: (value) => onChanged(value, minute),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              ':',
              style: TheWeTextStyle.pageTitle.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Expanded(
            child: _TimeWheelColumn(
              value: minute,
              max: 59,
              onChanged: (value) => onChanged(hour, value),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeWheelColumn extends StatefulWidget {
  const _TimeWheelColumn({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeWheelColumn> createState() => _TimeWheelColumnState();
}

class _TimeWheelColumnState extends State<_TimeWheelColumn> {
  late final FixedExtentScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = FixedExtentScrollController(initialItem: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TimeWheelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && controller.hasClients) {
      controller.animateToItem(
        widget.value,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: TheWeColor.white,
              borderRadius: BorderRadius.circular(TheWeRadius.xl),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 48,
            diameterRatio: 1.45,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.42,
            onSelectedItemChanged: widget.onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.max + 1,
              builder: (context, index) {
                final selected = index == widget.value;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style:
                        (selected
                                ? TheWeTextStyle.pageTitle
                                : TheWeTextStyle.title)
                            .copyWith(
                              color: selected
                                  ? TheWeColor.black900
                                  : TheWeColor.black500,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarColorChoice extends StatelessWidget {
  const _CalendarColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? color
                : TheWeColor.black300.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _CalendarTextField extends StatelessWidget {
  const _CalendarTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.body),
        const SizedBox(height: 8),
        CustomTextFormField(controller: controller),
      ],
    );
  }
}

class _CalendarDetailLine extends StatelessWidget {
  const _CalendarDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TheWeTextStyle.body)),
        ],
      ),
    );
  }
}

class _CalendarColorDetailLine extends StatelessWidget {
  const _CalendarColorDetailLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '색상',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

Color _calendarColor(String colorKey) {
  return switch (colorKey) {
    'blue' => TheWeColor.blue300,
    'orange' => const Color(0xFFF59E0B),
    'pink' => TheWeColor.pink,
    _ => TheWeColor.blue300,
  };
}

String _formatKoreanDate(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}
