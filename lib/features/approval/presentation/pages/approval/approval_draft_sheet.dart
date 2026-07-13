part of 'approval_draft_page.dart';

class _EditableDraftSheet extends StatelessWidget {
  const _EditableDraftSheet({
    required this.document,
    required this.titleController,
    required this.contentController,
    required this.onAddAttachment,
    required this.onAddLinkedDocument,
    required this.onRemoveLinkedDocument,
  });

  final ApprovalDocument document;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onAddAttachment;
  final VoidCallback onAddLinkedDocument;
  final ValueChanged<String> onRemoveLinkedDocument;

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
                children: [
                  Text('결재 라인', style: TheWeTextStyle.subtitle),
                  const SizedBox(height: 8),
                  ApprovalStampTable(steps: document.steps),
                ],
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
          Container(
            height: 36,
            alignment: Alignment.center,
            color: TheWeColor.black300.withValues(alpha: 0.18),
            child: Text(
              '상 세 내 용',
              style: TheWeTextStyle.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: TheWeColor.black900),
            ),
            child: CustomTextFormField(
              controller: contentController,
              minLines: 14,
              maxLines: 18,
              decoration: const InputDecoration(
                hintText: '결재 내용을 양식 안에 직접 입력하세요.',
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
