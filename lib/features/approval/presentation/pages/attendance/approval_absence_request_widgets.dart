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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final timeControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeDropdown(
              value: hour,
              values: List.generate(24, (index) => index),
              onChanged: onHourChanged,
            ),
            const SizedBox(width: 8),
            const Text(':'),
            const SizedBox(width: 8),
            _TimeDropdown(
              value: minute,
              values: const [0, 30],
              onChanged: onMinuteChanged,
            ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TheWeTextStyle.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _InlineBox(text: date)),
                  const SizedBox(width: 8),
                  timeControls,
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
            timeControls,
          ],
        );
      },
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  const _TimeDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final int value;
  final List<int> values;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return SizedBox(
      width: compact ? 64 : 88,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item.toString().padLeft(2, '0')),
              ),
            )
            .toList(),
        onChanged: onChanged,
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
