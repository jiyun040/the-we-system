part of 'approval_draft_page.dart';

class _EditableDraftSheet extends StatelessWidget {
  const _EditableDraftSheet({
    required this.document,
    required this.titleController,
    required this.contentController,
    required this.onAddAttachment,
    required this.onAddLinkedDocument,
    required this.onRemoveLinkedDocument,
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
                if (document.linkedDocuments.isEmpty)
                  Text('첨부된 문서가 없습니다.', style: TheWeTextStyle.body)
                else
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
                              hintText: column.$1 == 'date' ? 'YYYY-MM-DD' : '',
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
        const SizedBox(height: 12),
        const _PdfSectionHeader('지 시 사 항 / 상세 설명'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: TheWeColor.black900),
          ),
          child: CustomTextFormField(
            controller: contentController,
            minLines: 4,
            maxLines: 8,
            style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.65),
            decoration: const InputDecoration(
              hintText: '문서 하단에 표시할 설명을 입력하세요.',
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
