part of 'approval_absence_page.dart';

class _OvertimeDateTimeRow extends StatelessWidget {
  const _OvertimeDateTimeRow({
    required this.label,
    required this.date,
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  final String label;
  final String date;
  final int hour;
  final int minute;
  final ValueChanged<int?> onHourChanged;
  final ValueChanged<int?> onMinuteChanged;

  Future<void> _pickTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      helpText: '$label 시간 선택',
      cancelText: '취소',
      confirmText: '선택',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected == null) {
      return;
    }
    onHourChanged(selected.hour);
    onMinuteChanged(selected.minute);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final timeField = _TimePickerField(
          hour: hour,
          minute: minute,
          onTap: () => _pickTime(context),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TheWeTextStyle.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 3, child: _InlineBox(text: date)),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: timeField),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: 132,
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
            Expanded(child: _InlineBox(text: date)),
            const SizedBox(width: 10),
            SizedBox(width: 140, child: timeField),
          ],
        );
      },
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  final int hour;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TheWeColor.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: TheWeColor.black300.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: TheWeColor.blue300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  time,
                  maxLines: 1,
                  style: TheWeTextStyle.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.caption),
        const SizedBox(height: 6),
        Text(value, style: TheWeTextStyle.subtitle),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < 520;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TheWeTextStyle.body),
                const SizedBox(height: 8),
                child,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(label, style: TheWeTextStyle.body),
                ),
                Expanded(child: child),
              ],
            ),
    );
  }
}

class _InlineBox extends StatelessWidget {
  const _InlineBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TheWeColor.black300),
      ),
      child: Text(text, style: TheWeTextStyle.body),
    );
  }
}
