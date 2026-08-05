part of 'approval_draft_page.dart';

class _EditableDraftSheet extends StatelessWidget {
  const _EditableDraftSheet({
    required this.document,
    required this.titleController,
    required this.contentController,
    required this.onAddAttachment,
    required this.onAddLinkedDocument,
    required this.onRemoveLinkedDocument,
    required this.onRemoveAttachment,
    required this.departmentVisible,
    required this.onDepartmentVisibilityChanged,
    required this.onFormFieldChanged,
    required this.onLineItemChanged,
  });

  final ApprovalDocument document;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onAddAttachment;
  final VoidCallback onAddLinkedDocument;
  final ValueChanged<String> onRemoveLinkedDocument;
  final ValueChanged<ApprovalAttachment> onRemoveAttachment;
  final bool departmentVisible;
  final ValueChanged<bool> onDepartmentVisibilityChanged;
  final void Function(String key, String value) onFormFieldChanged;
  final void Function(int index, String key, String value) onLineItemChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      constraints: const BoxConstraints(maxWidth: 980),
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        border: Border.all(color: TheWeColor.black900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            document.form.contains('휴가') ? '휴 가 신 청' : '기 안 용 지',
            textAlign: TextAlign.center,
            style: TheWeTextStyle.pageTitle.copyWith(
              fontSize: compact ? 24 : 32,
              letterSpacing: compact ? 3 : 6,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final info = Column(
                children: [
                  _DraftInfoRow(label: '기 안 자', value: document.drafter),
                  _DraftInfoRow(label: '부    서', value: document.department),
                  if (document.documentLayout ==
                      ApprovalDocumentLayout.hospitality)
                    _DraftManualDateRow(
                      value: document.draftedAt,
                      onChanged: (value) =>
                          onFormFieldChanged('draftedAt', value),
                    )
                  else
                    _DraftInfoRow(label: '기 안 일', value: document.draftedAt),
                  _DraftInfoRow(
                    label: '수    신',
                    value: document.receivers.join(', '),
                  ),
                  _DraftInfoRow(
                    label: '참    조',
                    value: document.references.join(', '),
                  ),
                ],
              );
              final line = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ApprovalStampTable(steps: document.steps)],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 16), line],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: info),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: line),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _DraftInputRow(label: '제    목', controller: titleController),
          if (document.documentLayout == ApprovalDocumentLayout.basic)
            _BasicContentEditor(controller: contentController)
          else
            _PdfLayoutEditor(
              document: document,
              contentController: contentController,
              onFormFieldChanged: onFormFieldChanged,
              onLineItemChanged: onLineItemChanged,
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: departmentVisible
                  ? TheWeColor.blueSurface
                  : TheWeColor.dangerSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: departmentVisible
                    ? TheWeColor.blue300.withValues(alpha: .35)
                    : TheWeColor.danger.withValues(alpha: .35),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: departmentVisible,
                onChanged: onDepartmentVisibilityChanged,
                title: Text('부서 문서함 열람 허용', style: TheWeTextStyle.subtitle),
                subtitle: Text(
                  departmentVisible
                      ? '기본값 · 같은 부서 구성원이 문서를 열람할 수 있습니다.'
                      : '보안 문서 · 기안자와 결재자만 열람할 수 있습니다.',
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('첨부 / 연결 문서', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: TheWeColor.black300.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFFBFCFE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onAddAttachment,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('파일 첨부'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onAddLinkedDocument,
                      icon: const Icon(Icons.link_outlined, size: 18),
                      label: const Text('연결 문서'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (document.attachments.isEmpty &&
                    document.linkedDocuments.isEmpty)
                  Text('첨부된 문서가 없습니다.', style: TheWeTextStyle.body)
                else ...[
                  if (document.attachments.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: document.attachments
                          .map(
                            (attachment) => InputChip(
                              avatar: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: Text(
                                attachment.name,
                                style: TheWeTextStyle.caption,
                              ),
                              onDeleted: () => onRemoveAttachment(attachment),
                            ),
                          )
                          .toList(),
                    ),
                  if (document.attachments.isNotEmpty &&
                      document.linkedDocuments.isNotEmpty)
                    const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: document.linkedDocuments
                        .map(
                          (item) => InputChip(
                            label: Text(item, style: TheWeTextStyle.caption),
                            onDeleted: () => onRemoveLinkedDocument(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicContentEditor extends StatelessWidget {
  const _BasicContentEditor({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _PdfSectionHeader('상 세 내 용'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: TheWeColor.black900),
        ),
        child: CustomTextFormField(
          controller: controller,
          minLines: 14,
          maxLines: 18,
          style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.65),
          decoration: const InputDecoration(
            hintText: '결재 내용을 양식 안에 직접 입력하세요.',
            fillColor: TheWeColor.white,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    ],
  );
}

class _PdfLayoutEditor extends StatelessWidget {
  const _PdfLayoutEditor({
    required this.document,
    required this.contentController,
    required this.onFormFieldChanged,
    required this.onLineItemChanged,
  });

  final ApprovalDocument document;
  final TextEditingController contentController;
  final void Function(String key, String value) onFormFieldChanged;
  final void Function(int index, String key, String value) onLineItemChanged;

  @override
  Widget build(BuildContext context) {
    if (document.documentLayout == ApprovalDocumentLayout.payroll) {
      return Column(
        children: [
          _PdfWideInput(
            label: '참    조',
            value: document.formFields['reference'] ?? '',
            onChanged: (value) => onFormFieldChanged('reference', value),
          ),
          const _PdfSectionHeader('상 세 내 용'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: TheWeColor.black900),
            ),
            child: CustomTextFormField(
              controller: contentController,
              minLines: 10,
              maxLines: 16,
              style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.65),
              decoration: const InputDecoration(
                hintText: '급여대장 인가 내용과 지급 기준을 입력하세요.',
                fillColor: TheWeColor.white,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      );
    }

    final columns = _columnsFor(document.documentLayout);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PdfWideInput(
          label: '비    고',
          value: document.formFields['note'] ?? '',
          onChanged: (value) => onFormFieldChanged('note', value),
        ),
        if (MediaQuery.sizeOf(context).width < 600) ...[
          const SizedBox(height: 10),
          ...List.generate(document.lineItems.length, (index) {
            final item = document.lineItems[index];
            return _MobileLineItemEditor(
              index: index,
              columns: columns,
              item: item,
              onChanged: (key, value) => onLineItemChanged(index, key, value),
            );
          }),
          _MobileLineItemTotal(value: _totalAmount(document.lineItems)),
        ] else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 820,
              child: Column(
                children: [
                  Row(
                    children: columns
                        .map(
                          (column) => Expanded(
                            flex: column.$3,
                            child: _PdfTableCell(text: column.$2, header: true),
                          ),
                        )
                        .toList(),
                  ),
                  ...List.generate(document.lineItems.length, (index) {
                    final item = document.lineItems[index];
                    return Row(
                      children: columns
                          .map(
                            (column) => Expanded(
                              flex: column.$3,
                              child: _PdfInputCell(
                                key: ValueKey(
                                  'document-line-$index-${column.$1}',
                                ),
                                value: item[column.$1] ?? '',
                                hintText: column.$1 == 'date'
                                    ? 'YYYY-MM-DD'
                                    : '',
                                onChanged: (value) =>
                                    onLineItemChanged(index, column.$1, value),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }),
                  Row(
                    children: [
                      const Expanded(
                        flex: 8,
                        child: _PdfTableCell(text: '합    계', header: true),
                      ),
                      Expanded(
                        flex: 2,
                        child: _PdfTableCell(
                          text: _totalAmount(document.lineItems),
                          header: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<(String, String, int)> _columnsFor(String layout) => switch (layout) {
    ApprovalDocumentLayout.hospitality => const [
      ('date', '결 제 일', 2),
      ('customer', '이용 가맹점명', 3),
      ('place', '접 대 처', 3),
      ('attendees', '참 석 인 원', 4),
      ('amount', '금 액', 2),
    ],
    ApprovalDocumentLayout.purchase => const [
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
    final sum = items.fold<int>(0, (total, item) {
      final raw = (item['total'] ?? item['amount'] ?? '').replaceAll(',', '');
      return total + (int.tryParse(raw) ?? 0);
    });
    return sum == 0 ? '' : '${sum.toString()}원';
  }
}

class _DraftManualDateRow extends StatelessWidget {
  const _DraftManualDateRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(
        width: 104,
        child: _PdfTableCell(text: '기 안 일', header: true),
      ),
      Expanded(
        child: SizedBox(
          height: 48,
          child: TextFormField(
            key: const ValueKey('hospitality-drafted-at'),
            initialValue: value,
            onChanged: onChanged,
            keyboardType: TextInputType.datetime,
            style: TheWeTextStyle.body.copyWith(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      ),
    ],
  );
}

class _MobileLineItemEditor extends StatelessWidget {
  const _MobileLineItemEditor({
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
            initialValue: item[column.$1] ?? '',
            onChanged: (value) => onChanged(column.$1, value),
            keyboardType: column.$1 == 'amount' || column.$1 == 'total'
                ? TextInputType.number
                : TextInputType.text,
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

class _MobileLineItemTotal extends StatelessWidget {
  const _MobileLineItemTotal({required this.value});

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

class _PdfWideInput extends StatelessWidget {
  const _PdfWideInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 110, child: _PdfTableCell(text: label, header: true)),
      Expanded(
        child: _PdfInputCell(value: value, onChanged: onChanged),
      ),
    ],
  );
}

class _PdfSectionHeader extends StatelessWidget {
  const _PdfSectionHeader(this.title);

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

class _PdfTableCell extends StatelessWidget {
  const _PdfTableCell({required this.text, this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
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

class _PdfInputCell extends StatelessWidget {
  const _PdfInputCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = '',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: TheWeColor.white,
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    child: TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: TheWeTextStyle.body.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
      ),
    ),
  );
}
