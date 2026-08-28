import 'approval_home_dependencies.dart';

class ApprovalHeadcountLegend extends StatelessWidget {
  const ApprovalHeadcountLegend({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 10, color: color),
      const SizedBox(width: 6),
      Text(label, style: TheWeTextStyle.caption),
    ],
  );
}

class ApprovalHomeTrendChart extends StatelessWidget {
  const ApprovalHomeTrendChart({
    super.key,
    required this.totalCount,
    required this.joinerCount,
  });

  final int totalCount;
  final int joinerCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeadcountMetric(label: '현재 재직', value: totalCount),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HeadcountMetric(label: '이번 달 입사', value: joinerCount),
        ),
      ],
    );
  }
}

class _HeadcountMetric extends StatelessWidget {
  const _HeadcountMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: TheWeColor.blueSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.caption),
        const SizedBox(height: 8),
        Text('$value명', style: TheWeTextStyle.pageTitle),
      ],
    ),
  );
}
