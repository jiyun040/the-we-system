import 'approval_dialog_dependencies.dart';

class ApprovalLargeDialog extends StatelessWidget {
  const ApprovalLargeDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
  });

  final String title;
  final Widget child;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return TheWeModalSurface(
      maxWidth: 920,
      child: SizedBox(
        width: 860,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: title,
              onClose: () => Navigator.of(context).pop(),
            ),
            TheWeGaps.verticalSection,
            child,
            TheWeGaps.verticalXxl,
            TheWeModalActions(
              primaryLabel: actions.firstWhere(
                (action) => action == '확인',
                orElse: () => actions.first,
              ),
              secondaryLabel: actions.contains('취소') ? '취소' : null,
              primaryColor: TheWeColor.blue300,
              onPrimaryPressed: () => Navigator.of(context).pop(),
              onSecondaryPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovalTreePanel extends StatelessWidget {
  const ApprovalTreePanel({
    super.key,
    required this.searchHint,
    required this.nodes,
    this.selectedIndex = 0,
  });

  final String searchHint;
  final List<String> nodes;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Container(
      height: 460,
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: CustomTextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: searchHint,
                suffixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                final node = nodes[index];
                final selected = index == selectedIndex;
                final isGroup = !node.startsWith('  ');

                return Container(
                  color: selected
                      ? TheWeColor.blue100.withValues(alpha: 0.6)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGroup
                            ? Icons.folder_outlined
                            : Icons.description_outlined,
                        size: 17,
                        color: TheWeColor.black500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          node.trim(),
                          style: TheWeTextStyle.body.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalDetailBox extends StatelessWidget {
  const ApprovalDetailBox({
    super.key,
    required this.title,
    required this.rows,
    this.topAction,
  });

  final String title;
  final List<(String, String)> rows;
  final String? topAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: TheWeColor.black300.withValues(alpha: 0.15),
            child: Text(title, style: TheWeTextStyle.body),
          ),
          if (topAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: Text(topAction!),
              ),
            ),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(row.$1, style: TheWeTextStyle.body),
                  ),
                  Expanded(child: Text(row.$2, style: TheWeTextStyle.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalDocumentPickerTable extends StatelessWidget {
  const ApprovalDocumentPickerTable({
    super.key,
    required this.title,
    required this.documents,
  });

  final String title;
  final List<String> documents;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Container(
      height: 460,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Column(
        children: [
          CustomTextFormField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '검색',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: ['결재양식', '제목', '기안자', '결재일']
                .map(
                  (header) => Expanded(
                    child: Text(
                      header,
                      style: TheWeTextStyle.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(),
          ...documents.map(
            (document) => CheckboxListTile(
              value: false,
              onChanged: (_) {},
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(document, style: TheWeTextStyle.body),
              subtitle: Text(
                '업무기안 · study100 · 2026-06-20',
                style: TheWeTextStyle.caption,
              ),
            ),
          ),
          const Spacer(),
          Text(title, style: TheWeTextStyle.title),
        ],
      ),
    );
  }
}
