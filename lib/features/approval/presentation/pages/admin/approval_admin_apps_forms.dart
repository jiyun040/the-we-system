import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminAppManagement extends ConsumerWidget {
  const AdminAppManagement({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일반 계정 업무 APP 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 8),
        Text(
          '일반 계정 홈에 노출할 업무와 전자결재 양식을 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 18),
        ...[
          (
            PortalAppId.approval,
            '전자결재',
            Icons.approval_outlined,
            '${state.activeFormTemplates.length}개 양식 사용 중',
          ),
          (
            PortalAppId.attendance,
            '근태',
            Icons.schedule_outlined,
            '출퇴근 및 근태 현황',
          ),
          (
            PortalAppId.leave,
            '휴가',
            Icons.beach_access_outlined,
            '휴가 신청 및 연차 현황',
          ),
        ].map(
          (app) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(mobile ? 15 : 18),
            decoration: adminSurface(),
            child: mobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Icon(app.$3, color: TheWeColor.blue300),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AppDescription(
                              title: app.$2,
                              description: app.$4,
                            ),
                          ),
                          Switch(
                            key: ValueKey('app-switch-${app.$1}'),
                            value: state.isAppEnabled(app.$1),
                            onChanged: (enabled) => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .toggleApp(app.$1, enabled),
                          ),
                        ],
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                showAdminFormManagementDialog(context, ref),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('양식 관리'),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(app.$3, color: TheWeColor.blue300),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AppDescription(
                          title: app.$2,
                          description: app.$4,
                        ),
                      ),
                      Switch(
                        key: ValueKey('app-switch-${app.$1}'),
                        value: state.isAppEnabled(app.$1),
                        onChanged: (enabled) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleApp(app.$1, enabled),
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () =>
                              showAdminFormManagementDialog(context, ref),
                          child: const Text('양식 관리'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(mobile ? 15 : 18),
          decoration: adminSurface(),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: TheWeColor.blue300),
              const SizedBox(width: 16),
              const Expanded(
                child: _AppDescription(
                  title: '인력현황',
                  description: '관리자 계정에서만 노출',
                ),
              ),
              const Chip(
                avatar: Icon(Icons.lock_outline, size: 16),
                label: Text('관리자 전용'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppDescription extends StatelessWidget {
  const _AppDescription({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TheWeTextStyle.subtitle),
      Text(
        description,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> showAdminFormManagementDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final mobile = MediaQuery.sizeOf(context).width < 600;
  if (mobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: TheWeColor.background,
      builder: (sheetContext) => FractionallySizedBox(
        key: const ValueKey('mobile-form-management-sheet'),
        heightFactor: .72,
        child: _FormManagementContent(
          mobile: true,
          onClose: () => Navigator.pop(sheetContext),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: TheWeColor.background,
      child: SizedBox(
        width: 820,
        height: 640,
        child: _FormManagementContent(
          mobile: false,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    ),
  );
}

class _FormManagementContent extends ConsumerWidget {
  const _FormManagementContent({required this.mobile, required this.onClose});

  final bool mobile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 24,
        mobile ? 4 : 24,
        mobile ? 16 : 24,
        mobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '전자결재 양식 관리',
                    style: TheWeTextStyle.title.copyWith(fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
            Text(
              '사용하지 않는 양식은 일반 계정에서 바로 숨겨집니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showFormEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('양식 추가'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('전자결재 양식 관리', style: TheWeTextStyle.title),
                      const SizedBox(height: 4),
                      Text(
                        '사용 여부를 끄면 일반 계정의 기안 양식에서 즉시 제외됩니다.',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showFormEditor(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('양식 추가'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.formTemplates.isEmpty
                ? const Center(child: Text('등록된 양식이 없습니다.'))
                : ListView.separated(
                    itemCount: state.formTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final template = state.formTemplates[index];
                      final enabled = !state.disabledFormTemplateIds.contains(
                        template.id,
                      );
                      return _FormTemplateCard(
                        template: template,
                        enabled: enabled,
                        mobile: mobile,
                        onEnabledChanged: (value) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleFormTemplate(template.id, value),
                        onEdit: () =>
                            _showFormEditor(context, ref, template: template),
                        onDelete: () =>
                            _deleteFormTemplate(context, ref, template),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormTemplateCard extends StatelessWidget {
  const _FormTemplateCard({
    required this.template,
    required this.enabled,
    required this.mobile,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ApprovalFormTemplate template;
  final bool enabled;
  final bool mobile;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, mobile ? 9 : 10, 7, mobile ? 9 : 10),
    decoration: BoxDecoration(
      color: TheWeColor.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TheWeColor.black300.withValues(alpha: .18)),
    ),
    child: mobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _FormTemplateDescription(template: template)),
                  Switch(
                    key: ValueKey('form-switch-${template.id}'),
                    value: enabled,
                    onChanged: onEnabledChanged,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('수정'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: TheWeColor.danger,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _FormTemplateDescription(template: template)),
              Switch(
                key: ValueKey('form-switch-${template.id}'),
                value: enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: '양식 수정',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: TheWeColor.danger,
                tooltip: '양식 삭제',
              ),
            ],
          ),
  );
}

class _FormTemplateDescription extends StatelessWidget {
  const _FormTemplateDescription({required this.template});

  final ApprovalFormTemplate template;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(template.name, style: TheWeTextStyle.subtitle),
      const SizedBox(height: 3),
      Text(
        '${template.category} · ${ApprovalDocumentLayout.labels[template.documentLayout]} · ${template.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> _deleteFormTemplate(
  BuildContext context,
  WidgetRef ref,
  ApprovalFormTemplate template,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('양식 삭제'),
      content: Text('${template.name} 양식을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .deleteFormTemplate(template.id);
  }
}

Future<void> _showFormEditor(
  BuildContext context,
  WidgetRef ref, {
  ApprovalFormTemplate? template,
}) async {
  final category = TextEditingController(text: template?.category);
  final name = TextEditingController(text: template?.name);
  final description = TextEditingController(text: template?.description);
  final defaultTitle = TextEditingController(text: template?.defaultTitle);
  final defaultContent = TextEditingController(text: template?.defaultContent);
  final lineItemRows = TextEditingController(
    text: '${template?.lineItemRows ?? 8}',
  );
  var documentLayout = template?.documentLayout ?? ApprovalDocumentLayout.basic;
  var error = '';

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: TheWeColor.surfaceAlt,
        title: Text(template == null ? '양식 추가' : '양식 수정'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '분류'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '양식명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: '설명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultTitle,
                  decoration: const InputDecoration(labelText: '기본 제목'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultContent,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '기본 본문'),
                ),
                const SizedBox(height: 10),
                TheWeDropdown<String>(
                  value: documentLayout,
                  width: double.infinity,
                  items: ApprovalDocumentLayout.labels.keys.toList(),
                  labelBuilder: (value) =>
                      ApprovalDocumentLayout.labels[value] ?? value,
                  onChanged: (value) => setDialogState(
                    () =>
                        documentLayout = value ?? ApprovalDocumentLayout.basic,
                  ),
                ),
                if (documentLayout != ApprovalDocumentLayout.basic &&
                    documentLayout != ApprovalDocumentLayout.payroll) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: lineItemRows,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '문서 표 입력 행 수',
                      helperText: 'PDF형 문서에 표시할 입력 행 수를 설정합니다.',
                    ),
                  ),
                ],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final message = ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .saveFormTemplate(
                    templateId: template?.id,
                    category: category.text,
                    name: name.text,
                    description: description.text,
                    defaultTitle: defaultTitle.text,
                    defaultContent: defaultContent.text,
                    documentLayout: documentLayout,
                    lineItemRows:
                        int.tryParse(lineItemRows.text)?.clamp(1, 30) ?? 8,
                  );
              if (message != null) {
                setDialogState(() => error = message);
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}
