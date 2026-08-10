import 'dart:math' as math;

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
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TheWeTextStyle.caption.copyWith(
            color: TheWeColor.black900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _TrendPainter(
              totalCount: totalCount,
              joinerCount: joinerCount,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '기준 인원',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalCount명',
              style: TheWeTextStyle.subtitle.copyWith(color: TheWeColor.green),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.totalCount, required this.joinerCount});

  final int totalCount;
  final int joinerCount;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    final axisStyle = TextStyle(
      color: TheWeColor.black500,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    const leftPadding = 26.0;
    const bottomPadding = 26.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    for (var i = 0; i <= 5; i++) {
      final y = chartHeight * i / 5;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      textPainter
        ..text = TextSpan(text: '${10 - i * 2}', style: axisStyle)
        ..layout(minWidth: 20, maxWidth: 20)
        ..paint(canvas, Offset(0, y - 7));
    }

    final months = ['1월', '3월', '5월', '7월'];
    for (var i = 0; i < months.length; i++) {
      final x = leftPadding + chartWidth * i / (months.length - 1);
      textPainter
        ..text = TextSpan(text: months[i], style: axisStyle)
        ..layout(minWidth: 34, maxWidth: 34)
        ..paint(canvas, Offset(x - 17, chartHeight + 8));
    }

    Path linePath(List<double> values) {
      final maxValue = math.max(10, totalCount + 1).toDouble();
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = leftPadding + chartWidth * i / (values.length - 1);
        final y = chartHeight - (values[i] / maxValue * (chartHeight - 10));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final totalValues = [
      math.max(0, totalCount - 1).toDouble(),
      totalCount.toDouble(),
      math.max(0, totalCount - joinerCount + 1).toDouble(),
      totalCount.toDouble(),
    ];
    final joinValues = [
      0.0,
      math.max(1, joinerCount - 1).toDouble(),
      joinerCount.toDouble(),
      math.max(0, joinerCount - 1).toDouble(),
    ];
    final leaveValues = [0.0, 0.0, 1.0, 0.0];

    void drawLine(Path path, Color color, {double width = 3}) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawLine(linePath(totalValues), TheWeColor.green);
    drawLine(linePath(joinValues), TheWeColor.blue300, width: 2.5);
    drawLine(linePath(leaveValues), TheWeColor.pink, width: 2.5);

    canvas.drawLine(
      Offset(leftPadding, size.height - 4),
      Offset(size.width, size.height - 4),
      Paint()
        ..color = const Color(0xFFE5ECFF)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return totalCount != oldDelegate.totalCount ||
        joinerCount != oldDelegate.joinerCount;
  }
}
