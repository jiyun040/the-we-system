import 'approval_box_dependencies.dart';

class ApprovalDocumentTableText extends StatelessWidget {
  const ApprovalDocumentTableText(this.text, {super.key});

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

class ApprovalUrgentChip extends StatelessWidget {
  const ApprovalUrgentChip({super.key});

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

class ApprovalDocumentStatusChip extends StatelessWidget {
  const ApprovalDocumentStatusChip(this.text, {super.key});

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
