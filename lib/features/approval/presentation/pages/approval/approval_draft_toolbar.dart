part of 'approval_draft_page.dart';

class _DraftToolbar extends StatelessWidget {
  const _DraftToolbar({
    required this.document,
    required this.onPreview,
    required this.onRequest,
    required this.onSave,
    required this.canRequest,
  });

  final ApprovalDocument document;
  final VoidCallback onPreview;
  final VoidCallback onRequest;
  final VoidCallback onSave;
  final bool canRequest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TheWeBackButton(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  document.form,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TheWeTextStyle.pageTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canRequest)
                _DraftAction(
                  icon: Icons.edit_note,
                  label: '결재요청',
                  onPressed: onRequest,
                ),
              _DraftAction(
                icon: Icons.save_alt,
                label: '임시저장',
                onPressed: onSave,
              ),
              _DraftAction(
                icon: Icons.visibility_outlined,
                label: '미리보기',
                onPressed: onPreview,
              ),
              _DraftAction(
                icon: Icons.close,
                label: '취소',
                onPressed: () => context.goNamed(AppRouteName.home),
              ),
              _DraftAction(
                icon: Icons.info_outline,
                label: '결재 정보',
                onPressed: () => showApprovalInfoDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftAction extends StatelessWidget {
  const _DraftAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TheWeTextStyle.body),
      style: TextButton.styleFrom(foregroundColor: TheWeColor.black900),
    );
  }
}

class _FormCatalog extends StatelessWidget {
  const _FormCatalog({
    required this.templates,
    required this.selectedFormId,
    required this.onFormSelected,
  });

  final List<ApprovalFormTemplate> templates;
  final String selectedFormId;
  final ValueChanged<String> onFormSelected;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ApprovalFormTemplate>>{};
    for (final template in templates) {
      grouped.putIfAbsent(template.category, () => []).add(template);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기안 항목선택', style: TheWeTextStyle.title),
          const SizedBox(height: 12),
          Text(
            '새 결재 진행 후 선택한 양식을 이곳에서 계속 바꿀 수 있습니다.',
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 18),
          ...grouped.entries.map(
            (entry) => ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(Icons.folder_outlined, color: TheWeColor.black500),
              title: Text(entry.key, style: TheWeTextStyle.body),
              children: entry.value
                  .map(
                    (form) => ListTile(
                      dense: true,
                      selected: selectedFormId == form.id,
                      selectedTileColor: TheWeColor.blue100.withValues(
                        alpha: 0.45,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        Icons.description_outlined,
                        color: selectedFormId == form.id
                            ? TheWeColor.blue300
                            : TheWeColor.black500,
                      ),
                      title: Text(form.name, style: TheWeTextStyle.body),
                      subtitle: Text(
                        form.description,
                        style: TheWeTextStyle.caption,
                      ),
                      onTap: () => onFormSelected(form.id),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
