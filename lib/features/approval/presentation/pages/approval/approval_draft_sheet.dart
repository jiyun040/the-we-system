import 'approval_draft_dependencies.dart';
import '../../widgets/approval_document_sheet_attachments.dart';
import 'approval_draft_linked_documents.dart';
import 'approval_draft_sheet_fields.dart';
import '../../widgets/approval_document_sheet_tables.dart';
import '../../widgets/approval_material_photos.dart';

class ApprovalEditableDraftSheet extends StatelessWidget {
  const ApprovalEditableDraftSheet({
    super.key,
    required this.document,
    required this.titleController,
    required this.contentController,
    required this.onAddAttachment,
    required this.onDropAttachments,
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
  final Future<void> Function(List<XFile> files) onDropAttachments;
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
                  ApprovalDraftInfoRow(
                    label: '문서번호',
                    value: document.documentNo,
                  ),
                  if (document.documentLayout ==
                      ApprovalDocumentLayout.hospitality)
                    ApprovalDraftManualDateRow(
                      value: document.draftedAt,
                      onChanged: (value) =>
                          onFormFieldChanged('draftedAt', value),
                    )
                  else
                    ApprovalDraftInfoRow(
                      label: '작 성 일',
                      value: document.draftedAt,
                    ),
                  ApprovalDraftInfoRow(
                    label: '작성부서',
                    value: document.department,
                  ),
                  ApprovalDraftInfoRow(label: '작 성 자', value: document.drafter),
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
          if (document.documentLayout == ApprovalDocumentLayout.payroll)
            ApprovalDraftInputRow(label: '제    목', controller: titleController),
          if (document.documentLayout == ApprovalDocumentLayout.basic)
            _BasicContentEditor(controller: contentController)
          else
            _PdfLayoutEditor(
              document: document,
              contentController: contentController,
              onFormFieldChanged: onFormFieldChanged,
              onLineItemChanged: onLineItemChanged,
            ),
          if (isMaterialPurchaseDocument(document))
            ApprovalMaterialPhotoSection(
              document: document,
              onChanged: onFormFieldChanged,
            ),
          const SizedBox(height: 16),
          Text('첨부 / 연결 문서', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          _AttachmentDropArea(
            attachments: document.attachments,
            linkedDocuments: document.linkedDocuments,
            onAddAttachment: onAddAttachment,
            onDropAttachments: onDropAttachments,
            onAddLinkedDocument: onAddLinkedDocument,
            onRemoveAttachment: onRemoveAttachment,
            onRemoveLinkedDocument: onRemoveLinkedDocument,
          ),
        ],
      ),
    );
  }
}

class _AttachmentDropArea extends StatefulWidget {
  const _AttachmentDropArea({
    required this.attachments,
    required this.linkedDocuments,
    required this.onAddAttachment,
    required this.onDropAttachments,
    required this.onAddLinkedDocument,
    required this.onRemoveAttachment,
    required this.onRemoveLinkedDocument,
  });

  final List<ApprovalAttachment> attachments;
  final List<String> linkedDocuments;
  final VoidCallback onAddAttachment;
  final Future<void> Function(List<XFile> files) onDropAttachments;
  final VoidCallback onAddLinkedDocument;
  final ValueChanged<ApprovalAttachment> onRemoveAttachment;
  final ValueChanged<String> onRemoveLinkedDocument;

  @override
  State<_AttachmentDropArea> createState() => _AttachmentDropAreaState();
}

class _AttachmentDropAreaState extends State<_AttachmentDropArea> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      key: const ValueKey('approval-attachment-drop-target'),
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() => _dragging = false);
        await widget.onDropAttachments(details.files);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _dragging
                ? TheWeColor.blue300
                : TheWeColor.black300.withValues(alpha: 0.5),
            width: _dragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _dragging ? TheWeColor.blueSurface : const Color(0xFFFBFCFE),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onAddAttachment,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('파일 첨부'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onAddLinkedDocument,
                  icon: const Icon(Icons.link_outlined, size: 18),
                  label: const Text('연결 문서'),
                ),
                Text(
                  _dragging ? '여기에 놓으면 파일이 첨부됩니다.' : '파일을 이 영역으로 드래그해도 됩니다.',
                  style: TheWeTextStyle.caption.copyWith(
                    color: _dragging ? TheWeColor.blue300 : TheWeColor.black500,
                    fontWeight: _dragging ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.attachments.isEmpty && widget.linkedDocuments.isEmpty)
              Text('첨부된 문서가 없습니다.', style: TheWeTextStyle.body)
            else ...[
              if (widget.attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.attachments
                      .map(
                        (attachment) => InputChip(
                          avatar: const Icon(
                            Icons.attach_file_outlined,
                            size: 18,
                          ),
                          label: Text(
                            attachment.name,
                            style: TheWeTextStyle.caption,
                          ),
                          onPressed: () => showApprovalAttachmentPreview(
                            context,
                            attachment,
                          ),
                          tooltip: '미리보기',
                          onDeleted: () =>
                              widget.onRemoveAttachment(attachment),
                        ),
                      )
                      .toList(),
                ),
              if (widget.attachments.isNotEmpty &&
                  widget.linkedDocuments.isNotEmpty)
                const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.linkedDocuments
                    .map(
                      (item) => InputChip(
                        label: Text(item, style: TheWeTextStyle.caption),
                        onDeleted: () => widget.onRemoveLinkedDocument(item),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
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
      const ApprovalPdfSectionHeader('상 세 내 용'),
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
          ApprovalPdfWideInput(
            label: '참    조',
            value: document.formFields['reference'] ?? '',
            onChanged: (value) => onFormFieldChanged('reference', value),
          ),
          const ApprovalPdfSectionHeader('상 세 내 용'),
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
    final columnFlex = columns.fold<int>(0, (sum, column) => sum + column.$3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApprovalPdfWideInput(
          label: '비    고',
          value: document.formFields['note'] ?? '',
          onChanged: (value) => onFormFieldChanged('note', value),
          labelFlex: columns.first.$3,
          valueFlex: columnFlex - columns.first.$3,
        ),
        if (MediaQuery.sizeOf(context).width < 600) ...[
          const SizedBox(height: 10),
          ...List.generate(document.lineItems.length, (index) {
            final item = document.lineItems[index];
            return ApprovalMobileLineItemEditor(
              index: index,
              columns: columns,
              item: item,
              onChanged: (key, value) => onLineItemChanged(index, key, value),
            );
          }),
          ApprovalMobileLineItemTotal(value: _totalAmount(document.lineItems)),
        ] else
          Column(
            children: [
              Row(
                children: columns
                    .map(
                      (column) => Expanded(
                        flex: column.$3,
                        child: ApprovalPdfTableCell(
                          text: column.$2,
                          header: true,
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...List.generate(document.lineItems.length, (index) {
                final item = document.lineItems[index];
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: columns
                        .map(
                          (column) => Expanded(
                            flex: column.$3,
                            child: ApprovalPdfInputCell(
                              key: ValueKey(
                                'document-line-$index-${column.$1}',
                              ),
                              value:
                                  column.$1 == 'amount' || column.$1 == 'total'
                                  ? formatApprovalAmount(item[column.$1] ?? '')
                                  : item[column.$1] ?? '',
                              hintText: column.$1 == 'date' ? 'YYYY-MM-DD' : '',
                              isDate: column.$1 == 'date',
                              isAmount:
                                  column.$1 == 'amount' || column.$1 == 'total',
                              isQuantity: column.$1 == 'quantity',
                              onChanged: (value) =>
                                  onLineItemChanged(index, column.$1, value),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }),
              _desktopTotalRow(
                columns: columns,
                value: _totalAmount(document.lineItems),
              ),
            ],
          ),
      ],
    );
  }

  Widget _desktopTotalRow({
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
            child: const ApprovalPdfTableCell(text: '합    계', header: true),
          ),
          Expanded(
            flex: valueFlex,
            child: ApprovalPdfTableCell(text: value, header: true),
          ),
        ],
      ),
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
    final total = calculateApprovalLineItemsTotal(items);
    return total.isEmpty ? '' : '${formatApprovalAmount(total)}원';
  }
}
