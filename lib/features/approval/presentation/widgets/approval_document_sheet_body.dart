import 'approval_document_sheet_dependencies.dart';
import 'approval_document_sheet_tables.dart';

class ApprovalPdfDocumentBody extends StatelessWidget {
  const ApprovalPdfDocumentBody({super.key, required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    if (document.documentLayout == 'payroll') {
      return Column(
        children: [
          _ReadOnlyWideRow(
            label: '참    조',
            value: document.formFields['reference'] ?? '-',
          ),
          ApprovalSectionHeader(title: '상 세 내 용'),
          _ReadOnlyContent(content: document.content, minHeight: 330),
        ],
      );
    }

    final columns = _columnsFor(document.documentLayout);
    final columnFlex = columns.fold<int>(0, (sum, column) => sum + column.$3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyWideRow(
          label: '비    고',
          value: document.formFields['note'] ?? '-',
          labelFlex: columns.first.$3,
          valueFlex: columnFlex - columns.first.$3,
        ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < 720 ? 720 : constraints.maxWidth,
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columns
                          .map(
                            (column) => Expanded(
                              flex: column.$3,
                              child: _ReadOnlyTableCell(
                                text: column.$2,
                                header: true,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ...List.generate(document.lineItems.length, (index) {
                    final item = document.lineItems[index];
                    return IntrinsicHeight(
                      key: ValueKey('submitted-document-line-$index'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: columns
                            .map(
                              (column) => Expanded(
                                flex: column.$3,
                                child: _ReadOnlyTableCell(
                                  text: _displayLineItemValue(
                                    column.$1,
                                    item[column.$1] ?? '',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                  _totalRow(
                    columns: columns,
                    value: _totalAmount(document.lineItems),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '위 금액을 청구하오니 결재하여 주시기 바랍니다.',
          textAlign: TextAlign.center,
          style: TheWeTextStyle.body,
        ),
        const SizedBox(height: 24),
        Text(
          '우리기술 주식회사',
          textAlign: TextAlign.center,
          style: TheWeTextStyle.subtitle,
        ),
      ],
    );
  }

  Widget _totalRow({
    required List<(String, String, int)> columns,
    required String value,
  }) {
    final columnFlex = columns.fold<int>(0, (sum, column) => sum + column.$3);
    final valueFlex = columns.last.$3;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: columnFlex - valueFlex,
            child: const _ReadOnlyTableCell(text: '합    계', header: true),
          ),
          Expanded(
            flex: valueFlex,
            child: _ReadOnlyTableCell(text: value, header: true),
          ),
        ],
      ),
    );
  }

  List<(String, String, int)> _columnsFor(String layout) => switch (layout) {
    'hospitality' => const [
      ('date', '결 제 일', 2),
      ('customer', '이용 가맹점명', 3),
      ('place', '접 대 처', 3),
      ('attendees', '참 석 인 원', 4),
      ('amount', '금 액', 2),
    ],
    'purchase' => const [
      ('date', '날 짜', 2),
      ('item', '내 용', 3),
      ('quantity', '수 량', 2),
      ('amount', '금 액', 2),
      ('total', '합계금액', 2),
      ('remark', '비 고', 3),
    ],
    _ => const [
      ('date', '입 금 일', 2),
      ('item', '항 목', 3),
      ('purpose', '적 요', 6),
      ('amount', '금 액', 2),
    ],
  };

  String _totalAmount(List<Map<String, String>> items) {
    final total = calculateApprovalLineItemsTotal(items);
    return total.isEmpty ? '-' : '${formatApprovalAmount(total)}원';
  }

  String _displayLineItemValue(String key, String value) {
    if (key == 'amount' || key == 'total') {
      return formatApprovalAmount(value);
    }
    return value;
  }
}

class _ReadOnlyContent extends StatelessWidget {
  const _ReadOnlyContent({required this.content, required this.minHeight});

  final String content;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight),
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
    child: Text(
      content.isEmpty ? '-' : content,
      style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.7),
    ),
  );
}

class _ReadOnlyWideRow extends StatelessWidget {
  const _ReadOnlyWideRow({
    required this.label,
    required this.value,
    this.labelFlex,
    this.valueFlex,
  });

  final String label;
  final String value;
  final int? labelFlex;
  final int? valueFlex;

  @override
  Widget build(BuildContext context) {
    final resolvedLabelFlex = labelFlex;
    final resolvedValueFlex = valueFlex;
    if (resolvedLabelFlex != null && resolvedValueFlex != null) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: resolvedLabelFlex,
              child: _ReadOnlyTableCell(text: label, header: true),
            ),
            Expanded(
              flex: resolvedValueFlex,
              child: _ReadOnlyTableCell(text: value),
            ),
          ],
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 110,
            child: _ReadOnlyTableCell(text: label, header: true),
          ),
          Expanded(child: _ReadOnlyTableCell(text: value)),
        ],
      ),
    );
  }
}

class _ReadOnlyTableCell extends StatelessWidget {
  const _ReadOnlyTableCell({required this.text, this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
    decoration: BoxDecoration(
      color: header
          ? TheWeColor.black300.withValues(alpha: .14)
          : TheWeColor.white,
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TheWeTextStyle.body.copyWith(
        fontSize: 14,
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}
