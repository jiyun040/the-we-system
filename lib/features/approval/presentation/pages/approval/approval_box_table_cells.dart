part of 'approval_box_page.dart';

class _DocumentTableText extends StatelessWidget {
  const _DocumentTableText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: TheWeTextStyle.body,
  );
}

class _UrgentChip extends StatelessWidget {
  const _UrgentChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: TheWeColor.dangerSurface,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '긴급',
      textAlign: TextAlign.center,
      style: TheWeTextStyle.caption.copyWith(color: TheWeColor.danger),
    ),
  );
}

class _DocumentStatusChip extends StatelessWidget {
  const _DocumentStatusChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = switch (text) {
      '완료' => TheWeColor.green,
      '반려' => TheWeColor.pink,
      '작성중' || '임시저장' => TheWeColor.black500,
      _ => TheWeColor.blue300,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
