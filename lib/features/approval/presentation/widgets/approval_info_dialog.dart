part of 'approval_dialogs.dart';

class _ApprovalInfoDialog extends StatefulWidget {
  const _ApprovalInfoDialog();

  @override
  State<_ApprovalInfoDialog> createState() => _ApprovalInfoDialogState();
}

class _ApprovalInfoDialogState extends State<_ApprovalInfoDialog> {
  int selectedIndex = 0;

  static const categories = ['* 결재선', '* 참조자', '* 수신자', '열람자', '* 공문서 수신처'];

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: screen.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('결재 정보', style: TheWeTextStyle.title),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 26,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < categories.length; index++)
                    _ApprovalInfoCategory(
                      label: categories[index],
                      selected: selectedIndex == index,
                      onTap: () => setState(() => selectedIndex = index),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: switch (selectedIndex) {
                  0 => _ApprovalLineSetup(),
                  1 => const _PeopleSetup(
                    caption: '참조자는 결재 중에도 문서를 열람할 수 있습니다.',
                  ),
                  2 => const _PeopleSetup(caption: '수신자는 접수 대기 문서함에서 확인합니다.'),
                  3 => const _PeopleSetup(
                    caption: '열람자는 결재 완료 후 문서를 열람할 수 있습니다.',
                  ),
                  _ => _PublicReceiverSetup(),
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: TheWeColor.blue300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftFormSelectionDialog extends StatefulWidget {
  const _DraftFormSelectionDialog({required this.templates});

  final List<ApprovalFormTemplate> templates;

  @override
  State<_DraftFormSelectionDialog> createState() =>
      _DraftFormSelectionDialogState();
}

class _DraftFormSelectionDialogState extends State<_DraftFormSelectionDialog> {
  late ApprovalFormTemplate selectedTemplate;

  @override
  void initState() {
    super.initState();
    selectedTemplate = widget.templates.first;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ApprovalFormTemplate>>{};
    for (final template in widget.templates) {
      grouped.putIfAbsent(template.category, () => []).add(template);
    }

    return Dialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 920,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('기안 항목선택', style: TheWeTextStyle.title),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '새 결재 진행 후 바로 문서로 넘어가지 않고, 여기서 동일한 기안 양식을 먼저 선택합니다.',
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: TheWeColor.black300.withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(14),
                          children: grouped.entries.map((entry) {
                            return ExpansionTile(
                              initiallyExpanded: true,
                              tilePadding: EdgeInsets.zero,
                              leading: const Icon(Icons.folder_outlined),
                              title: Text(
                                entry.key,
                                style: TheWeTextStyle.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              children: entry.value
                                  .map(
                                    (template) => ListTile(
                                      selected:
                                          template.id == selectedTemplate.id,
                                      selectedTileColor: TheWeColor.blue100
                                          .withValues(alpha: 0.45),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      leading: const Icon(
                                        Icons.description_outlined,
                                      ),
                                      title: Text(
                                        template.name,
                                        style: TheWeTextStyle.body,
                                      ),
                                      subtitle: Text(
                                        template.description,
                                        style: TheWeTextStyle.caption,
                                      ),
                                      onTap: () => setState(
                                        () => selectedTemplate = template,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: TheWeColor.black300.withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('상세정보', style: TheWeTextStyle.subtitle),
                            const SizedBox(height: 16),
                            _DialogInfoRow(
                              label: '양식명',
                              value: selectedTemplate.name,
                            ),
                            const SizedBox(height: 12),
                            _DialogInfoRow(
                              label: '카테고리',
                              value: selectedTemplate.category,
                            ),
                            const SizedBox(height: 12),
                            _DialogInfoRow(
                              label: '기안부서',
                              value: selectedTemplate.cooperationDepartment,
                            ),
                            const SizedBox(height: 12),
                            _DialogInfoRow(
                              label: '설명',
                              value: selectedTemplate.description,
                            ),
                            const SizedBox(height: 18),
                            Text('기본 제목', style: TheWeTextStyle.body),
                            const SizedBox(height: 8),
                            Text(
                              selectedTemplate.defaultTitle,
                              style: TheWeTextStyle.caption,
                            ),
                            const SizedBox(height: 16),
                            Text('기본 본문', style: TheWeTextStyle.body),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: TheWeColor.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  selectedTemplate.defaultContent,
                                  style: TheWeTextStyle.caption.copyWith(
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(selectedTemplate),
                    style: FilledButton.styleFrom(
                      backgroundColor: TheWeColor.blue300,
                    ),
                    child: const Text('확인'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalInfoCategory extends StatelessWidget {
  const _ApprovalInfoCategory({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? TheWeColor.black900 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TheWeTextStyle.body.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? TheWeColor.black900 : TheWeColor.black500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
