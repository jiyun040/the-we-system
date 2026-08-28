import 'approval_document_sheet_dependencies.dart';

class ApprovalBasicInfoTable extends StatelessWidget {
  const ApprovalBasicInfoTable({super.key, required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return _BorderTable(
      rows: [
        ApprovalTablePair(label: '문서번호', value: document.documentNo),
        ApprovalTablePair(label: '작 성 일', value: document.draftedAt),
        ApprovalTablePair(label: '작성부서', value: document.department),
        ApprovalTablePair(label: '작 성 자', value: document.drafter),
      ],
    );
  }
}

class ApprovalStampTable extends StatelessWidget {
  const ApprovalStampTable({super.key, required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    final visibleSteps = steps.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 480
            ? 480.0
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 42,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: TheWeColor.black300.withValues(alpha: 0.18),
                border: Border.all(color: TheWeColor.black900, width: .6),
              ),
              child: Text(
                '결재 라인',
                style: TheWeTextStyle.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _VerticalCell(label: '결\n재'),
                      ...visibleSteps.map(
                        (step) => Expanded(child: _StampCell(step: step)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    final approved = step.status == '완료';
    final rejected = step.status == '반려';

    return Container(
      height: 126,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TheWeColor.black900),
          right: BorderSide(color: TheWeColor.black900),
          bottom: BorderSide(color: TheWeColor.black900),
        ),
      ),
      child: Column(
        children: [
          _StampText(step.role.isEmpty ? step.type : step.role),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (approved || rejected)
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rejected
                              ? TheWeColor.danger
                              : Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        rejected ? '반려' : '승인',
                        style: TheWeTextStyle.caption.copyWith(
                          color: rejected
                              ? TheWeColor.danger
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      step.name,
                      style: TheWeTextStyle.body.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _StampText(step.approvedAt ?? step.status),
        ],
      ),
    );
  }
}

class _StampText extends StatelessWidget {
  const _StampText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TheWeColor.black900)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.body.copyWith(fontSize: 14),
      ),
    );
  }
}

class _VerticalCell extends StatelessWidget {
  const _VerticalCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.18),
        border: Border.all(color: TheWeColor.black900),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BorderTable extends StatelessWidget {
  const _BorderTable({required this.rows});

  final List<ApprovalTablePair> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) => ApprovalWideRow.fromPair(row)).toList(),
    );
  }
}

class ApprovalWideRow extends StatelessWidget {
  const ApprovalWideRow({super.key, required this.label, required this.value});

  factory ApprovalWideRow.fromPair(ApprovalTablePair pair) {
    return ApprovalWideRow(label: pair.label, value: pair.value);
  }

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: TheWeColor.black900),
          right: BorderSide(color: TheWeColor.black900),
          bottom: BorderSide(color: TheWeColor.black900),
          top: BorderSide(color: TheWeColor.black900),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 82 : 124,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: TheWeColor.black300.withValues(alpha: 0.18),
              border: Border(right: BorderSide(color: TheWeColor.black900)),
            ),
            child: Text(
              label,
              style: TheWeTextStyle.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                value.isEmpty ? '-' : value,
                style: TheWeTextStyle.body.copyWith(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalSectionHeader extends StatelessWidget {
  const ApprovalSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.18),
        border: Border.all(color: TheWeColor.black900, width: .6),
      ),
      child: Text(
        title,
        style: TheWeTextStyle.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ApprovalTablePair {
  const ApprovalTablePair({required this.label, required this.value});

  final String label;
  final String value;
}
