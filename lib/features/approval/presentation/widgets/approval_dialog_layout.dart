part of 'approval_dialogs.dart';

class _LargeDialog extends StatelessWidget {
  const _LargeDialog({
    required this.title,
    required this.child,
    required this.actions,
  });

  final String title;
  final Widget child;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TheWeRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TheWeSpacing.section,
          vertical: TheWeSpacing.page,
        ),
        child: SizedBox(
          width: 860,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: TheWeTextStyle.title),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              TheWeGaps.verticalSection,
              child,
              TheWeGaps.verticalXxl,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: TheWeSpacing.sm),
                        child: action == '확인'
                            ? FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: TheWeColor.blue300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      TheWeRadius.sm,
                                    ),
                                  ),
                                ),
                                child: Text(action),
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(action),
                              ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreePanel extends StatelessWidget {
  const _TreePanel({
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

class _DetailBox extends StatelessWidget {
  const _DetailBox({required this.title, required this.rows, this.topAction});

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

class _DocumentPickerTable extends StatelessWidget {
  const _DocumentPickerTable({required this.title, required this.documents});

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
