part of 'approval_box_page.dart';

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.body,
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final color = switch (text) {
      '완료' => TheWeColor.green,
      '반려' => TheWeColor.pink,
      '작성중' => TheWeColor.black500,
      _ => TheWeColor.blue300,
    };

    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TheWeTextStyle.caption.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
