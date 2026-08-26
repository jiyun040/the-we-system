import 'approval_dialog_dependencies.dart';
import 'approval_dialog_layout.dart';

class ApprovalInfoDialog extends StatefulWidget {
  const ApprovalInfoDialog({super.key, required this.document});

  final ApprovalDocument document;

  @override
  State<ApprovalInfoDialog> createState() => _ApprovalInfoDialogState();
}

class _ApprovalInfoDialogState extends State<ApprovalInfoDialog> {
  int selectedIndex = 0;

  static const categories = ['* 결재선', '* 참조자', '* 수신자', '열람자', '* 공문서 수신처'];

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return TheWeModalSurface(
      maxWidth: 1120,
      maxHeightFactor: 0.86,
      child: SizedBox(
        height: screen.height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '결재 정보',
              onClose: () => Navigator.of(context).pop(),
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
            Expanded(child: _ApprovalInfoValues(values: _values())),
            const SizedBox(height: 16),
            TheWeModalActions(
              primaryLabel: '확인',
              secondaryLabel: '취소',
              primaryColor: TheWeColor.blue300,
              onPrimaryPressed: () => Navigator.of(context).pop(),
              onSecondaryPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _values() => switch (selectedIndex) {
    0 =>
      widget.document.steps
          .map(
            (step) =>
                '${step.type} · ${step.name} · ${step.department} · ${step.status}',
          )
          .toList(),
    1 => widget.document.references,
    2 => widget.document.receivers,
    3 => widget.document.viewers,
    _ => widget.document.publicReceivers,
  };
}

class _ApprovalInfoValues extends StatelessWidget {
  const _ApprovalInfoValues({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Center(
        child: Text(
          '서버에 등록된 정보가 없습니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
      );
    }
    return ListView.separated(
      itemCount: values.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(values[index], style: TheWeTextStyle.body),
      ),
    );
  }
}

class ApprovalDraftFormSelectionDialog extends StatefulWidget {
  const ApprovalDraftFormSelectionDialog({super.key, required this.templates});

  final List<ApprovalFormTemplate> templates;

  @override
  State<ApprovalDraftFormSelectionDialog> createState() =>
      _DraftFormSelectionDialogState();
}

class _DraftFormSelectionDialogState
    extends State<ApprovalDraftFormSelectionDialog> {
  late ApprovalFormTemplate selectedTemplate;

  @override
  void initState() {
    super.initState();
    selectedTemplate = widget.templates.first;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;
    final grouped = <String, List<ApprovalFormTemplate>>{};
    for (final template in widget.templates) {
      grouped.putIfAbsent(template.category, () => []).add(template);
    }

    return TheWeModalSurface(
      width: isPhone ? screen.width - 36 : null,
      maxWidth: 920,
      maxHeightFactor: 0.82,
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 18 : 24,
        vertical: isPhone ? 18 : 22,
      ),
      child: SizedBox(
        height: isPhone ? screen.height * 0.76 : 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '기안 항목선택',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isPhone
                  ? ListView(
                      children: [
                        SizedBox(height: 280, child: _templateList(grouped)),
                        const SizedBox(height: 12),
                        _templateDetail(expandBody: false),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 4, child: _templateList(grouped)),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: _templateDetail()),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            TheWeModalActions(
              primaryLabel: '확인',
              secondaryLabel: '취소',
              primaryColor: TheWeColor.blue300,
              onPrimaryPressed: () =>
                  Navigator.of(context).pop(selectedTemplate),
              onSecondaryPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateList(Map<String, List<ApprovalFormTemplate>> grouped) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: grouped.entries.map((entry) {
          return ExpansionTile(
            initiallyExpanded: true,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              entry.key,
              style: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            children: entry.value.map((template) {
              return ListTile(
                selected: template.id == selectedTemplate.id,
                selectedTileColor: TheWeColor.blue100.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(Icons.description_outlined),
                title: Text(template.name, style: TheWeTextStyle.body),
                subtitle: Text(
                  template.description,
                  style: TheWeTextStyle.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => setState(() => selectedTemplate = template),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _templateDetail({bool expandBody = true}) {
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        selectedTemplate.defaultContent,
        style: TheWeTextStyle.caption.copyWith(height: 1.6),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('상세정보', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 16),
          ApprovalDialogInfoRow(label: '양식명', value: selectedTemplate.name),
          const SizedBox(height: 12),
          ApprovalDialogInfoRow(
            label: '카테고리',
            value: selectedTemplate.category,
          ),
          const SizedBox(height: 12),
          ApprovalDialogInfoRow(
            label: '기안부서',
            value: selectedTemplate.cooperationDepartment,
          ),
          const SizedBox(height: 12),
          ApprovalDialogInfoRow(
            label: '설명',
            value: selectedTemplate.description,
          ),
          const SizedBox(height: 18),
          Text('기본 제목', style: TheWeTextStyle.body),
          const SizedBox(height: 8),
          Text(selectedTemplate.defaultTitle, style: TheWeTextStyle.caption),
          const SizedBox(height: 16),
          Text('기본 본문', style: TheWeTextStyle.body),
          const SizedBox(height: 8),
          expandBody ? Expanded(child: body) : body,
        ],
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
