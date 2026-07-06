part of 'approval_absence_page.dart';

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = TheWeInsets.panel,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? TheWeColor.white,
        borderRadius: BorderRadius.circular(TheWeRadius.card),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TheWeTextStyle.title),
          TheWeGaps.verticalXxl,
          child,
        ],
      ),
    );
  }
}

class _PrimaryStatusBox extends StatelessWidget {
  const _PrimaryStatusBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TheWeInsets.card,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TheWeRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          TheWeGaps.verticalXs,
          Text(value, style: TheWeTextStyle.subtitle),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TheWeSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
            ),
          ),
          Text(
            value,
            style: TheWeTextStyle.body.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TheWeRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: TheWeSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? TheWeColor.blue100.withValues(alpha: 0.45)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(TheWeRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TheWeTextStyle.body.copyWith(
                  color: selected ? TheWeColor.blue300 : TheWeColor.black900,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: selected ? TheWeColor.blue300 : TheWeColor.black500,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TheWeColor.black300 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TheWeTextStyle.body.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 136 : 170),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 8),
          Text(value, style: TheWeTextStyle.subtitle.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final isToday = date.day == now.day && date.month == now.month;
        final isWeekend = index >= 5;

        return Expanded(
          child: Column(
            children: [
              Text(
                labels[index],
                style: TheWeTextStyle.body.copyWith(
                  color: isWeekend ? TheWeColor.pink : TheWeColor.black900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? TheWeColor.black900
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${date.day}',
                  style: TheWeTextStyle.body.copyWith(
                    color: isToday ? Colors.white : TheWeColor.black900,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
