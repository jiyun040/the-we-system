import 'approval_draft_dependencies.dart';

class ApprovalDraftManualDateRow extends StatelessWidget {
  const ApprovalDraftManualDateRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(
        width: 104,
        child: ApprovalPdfTableCell(text: '기 안 일', header: true),
      ),
      Expanded(
        child: SizedBox(
          height: 48,
          child: TextFormField(
            key: const ValueKey('hospitality-drafted-at'),
            initialValue: value,
            onChanged: onChanged,
            keyboardType: TextInputType.datetime,
            inputFormatters: const [ApprovalDateInputFormatter()],
            style: TheWeTextStyle.body.copyWith(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    ],
  );
}

class ApprovalMobileLineItemEditor extends StatelessWidget {
  const ApprovalMobileLineItemEditor({
    super.key,
    required this.index,
    required this.columns,
    required this.item,
    required this.onChanged,
  });

  final int index;
  final List<(String, String, int)> columns;
  final Map<String, String> item;
  final void Function(String key, String value) onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TheWeColor.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TheWeColor.black300.withValues(alpha: .45)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${index + 1}번 항목', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 10),
        for (final column in columns) ...[
          Text(column.$2, style: TheWeTextStyle.caption),
          const SizedBox(height: 5),
          TextFormField(
            key: ValueKey('mobile-document-line-$index-${column.$1}'),
            initialValue: column.$1 == 'amount' || column.$1 == 'total'
                ? formatApprovalAmount(item[column.$1] ?? '')
                : item[column.$1] ?? '',
            onChanged: (value) => onChanged(column.$1, value),
            keyboardType:
                column.$1 == 'amount' ||
                    column.$1 == 'total' ||
                    column.$1 == 'quantity'
                ? TextInputType.number
                : column.$1 == 'date'
                ? TextInputType.datetime
                : TextInputType.multiline,
            inputFormatters: [
              if (column.$1 == 'date') const ApprovalDateInputFormatter(),
              if (column.$1 == 'amount' || column.$1 == 'total')
                ApprovalAmountInputFormatter(),
              if (column.$1 == 'quantity') const ApprovalDigitsInputFormatter(),
            ],
            minLines: 1,
            maxLines: null,
            decoration: InputDecoration(
              hintText: column.$1 == 'date' ? 'YYYY-MM-DD' : '',
              isDense: true,
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    ),
  );
}

class ApprovalMobileLineItemTotal extends StatelessWidget {
  const ApprovalMobileLineItemTotal({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: TheWeColor.blueSurface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Text('합계', style: TheWeTextStyle.subtitle),
        const Spacer(),
        Text(value.isEmpty ? '-' : value, style: TheWeTextStyle.subtitle),
      ],
    ),
  );
}

class ApprovalPdfWideInput extends StatelessWidget {
  const ApprovalPdfWideInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.labelFlex,
    this.valueFlex,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
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
              child: ApprovalPdfTableCell(text: label, header: true),
            ),
            Expanded(
              flex: resolvedValueFlex,
              child: ApprovalPdfInputCell(value: value, onChanged: onChanged),
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
            child: ApprovalPdfTableCell(text: label, header: true),
          ),
          Expanded(
            child: ApprovalPdfInputCell(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class ApprovalPdfSectionHeader extends StatelessWidget {
  const ApprovalPdfSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: TheWeColor.black300.withValues(alpha: 0.18),
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    child: Text(
      title,
      style: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class ApprovalPdfTableCell extends StatelessWidget {
  const ApprovalPdfTableCell({
    super.key,
    required this.text,
    this.header = false,
  });

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: header
          ? TheWeColor.black300.withValues(alpha: .14)
          : TheWeColor.white,
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6),
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

class ApprovalPdfInputCell extends StatelessWidget {
  const ApprovalPdfInputCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = '',
    this.isDate = false,
    this.isAmount = false,
    this.isQuantity = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool isDate;
  final bool isAmount;
  final bool isQuantity;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    decoration: BoxDecoration(
      color: TheWeColor.white,
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    child: TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType: isAmount || isQuantity
          ? TextInputType.number
          : isDate
          ? TextInputType.datetime
          : TextInputType.multiline,
      inputFormatters: [
        if (isDate) const ApprovalDateInputFormatter(),
        if (isAmount) ApprovalAmountInputFormatter(),
        if (isQuantity) const ApprovalDigitsInputFormatter(),
      ],
      minLines: 1,
      maxLines: null,
      style: TheWeTextStyle.body.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintText.isEmpty
            ? null
            : TheWeTextStyle.caption.copyWith(
                fontSize: 13,
                color: TheWeColor.black300,
              ),
        isDense: true,
        filled: false,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
      ),
    ),
  );
}
