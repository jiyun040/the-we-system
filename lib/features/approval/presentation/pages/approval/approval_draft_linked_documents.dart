part of 'approval_draft_page.dart';

class _LinkedDocumentDialog extends StatefulWidget {
  const _LinkedDocumentDialog({required this.documents});

  final List<ApprovalDocument> documents;

  @override
  State<_LinkedDocumentDialog> createState() => _LinkedDocumentDialogState();
}

class _LinkedDocumentDialogState extends State<_LinkedDocumentDialog> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    return TheWeModalSurface(
      maxWidth: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '연결 문서 선택',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 540,
            height: 360,
            child: widget.documents.isEmpty
                ? Center(
                    child: Text(
                      '연결할 수 있는 문서가 없습니다.',
                      style: TheWeTextStyle.body,
                    ),
                  )
                : ListView.separated(
                    itemCount: widget.documents.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: TheWeColor.black300.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final document = widget.documents[index];
                      final selected = selectedId == document.id;
                      return InkWell(
                        onTap: () => setState(() => selectedId = document.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? TheWeColor.blue300
                                    : TheWeColor.black500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document.title,
                                      style: TheWeTextStyle.body,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${document.documentNo} · ${document.form}',
                                      style: TheWeTextStyle.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: '추가',
            secondaryLabel: '취소',
            primaryColor: TheWeColor.green,
            onSecondaryPressed: () => Navigator.of(context).pop(),
            onPrimaryPressed: selectedId == null
                ? null
                : () {
                    final document = widget.documents
                        .where((item) => item.id == selectedId)
                        .first;
                    Navigator.of(
                      context,
                    ).pop('[연결] ${document.documentNo} ${document.title}');
                  },
          ),
        ],
      ),
    );
  }
}

class _DraftInfoRow extends StatelessWidget {
  const _DraftInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
      child: Row(
        children: [
          Container(
            width: compact ? 82 : 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: TheWeColor.black300.withValues(alpha: 0.18),
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(value, style: TheWeTextStyle.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftInputRow extends StatelessWidget {
  const _DraftInputRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
      child: Row(
        children: [
          Container(
            width: compact ? 82 : 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: TheWeColor.black300.withValues(alpha: 0.18),
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: CustomTextFormField(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}
