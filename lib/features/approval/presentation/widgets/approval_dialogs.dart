import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

Future<void> showApprovalDecisionDialog(
  BuildContext context, {
  required ApprovalDocument document,
  required String action,
  required Future<void> Function(String opinion) onConfirm,
}) {
  final opinionController = TextEditingController(
    text: action == '승인' ? '관련 내용을 확인하였기에 결재합니다.' : '',
  );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      title: Row(
        children: [
          Text('$action하기', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogInfoRow(label: '결재문서명', value: document.title),
            const SizedBox(height: 20),
            Text('결재의견', style: TheWeTextStyle.body),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: opinionController,
              minLines: 5,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '의견을 작성해 주세요.'),
            ),
            if (action == '반려') ...[
              const SizedBox(height: 12),
              Text(
                '반려 시 기안자에게 수정 요청 알림이 발송됩니다.',
                style: TheWeTextStyle.caption.copyWith(color: TheWeColor.pink),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            await onConfirm(opinionController.text.trim());
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: action == '승인'
                ? TheWeColor.blue300
                : TheWeColor.pink,
            foregroundColor: TheWeColor.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(action),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}

Future<ApprovalFormTemplate?> showDraftFormSelectionDialog(
  BuildContext context, {
  required List<ApprovalFormTemplate> templates,
}) {
  return showDialog<ApprovalFormTemplate>(
    context: context,
    builder: (context) => _DraftFormSelectionDialog(templates: templates),
  );
}

Future<void> showApprovalFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LargeDialog(
      title: '결재양식 선택',
      actions: const ['확인', '취소'],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _TreePanel(
              searchHint: '양식제목',
              nodes: const [
                '근태',
                '  (신규)휴가신청-연차관리연동',
                '  연장근무신청_근태관리연동',
                '지원',
                '  구매품의서',
                '  업무기안',
                '  경조화신청',
                '  도서구입신청',
              ],
              selectedIndex: 5,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: _DetailBox(
              title: '상세정보',
              rows: const [
                ('제목', '업무기안[기본양식]'),
                ('전사문서함', '업무 문서함'),
                ('보존연한', '5년'),
                ('기안부서', '교육관리팀'),
                ('부서문서함', '미지정'),
              ],
              topAction: '자주 쓰는 양식으로 추가',
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showAttachDocumentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LargeDialog(
      title: '결재 문서 첨부',
      actions: const ['확인', '취소'],
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _TreePanel(
              searchHint: '문서함',
              nodes: const [
                '개인 문서함',
                '  기안 문서함',
                '  결재 문서함',
                '  참조/열람 문서함',
                '  수신 문서함',
                '부서 문서함',
                '  기안 완료함',
                '  부서 참조함',
              ],
              selectedIndex: 2,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 7,
            child: _DocumentPickerTable(
              title: '다른 결재문서를 연결할 수도 있습니다',
              documents: const [
                '노후PC 교체 예산 신청 기안',
                '사용자 교육 기안입니다.',
                '테스트 대기 문서',
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showApprovalInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _ApprovalInfoDialog(),
  );
}

Future<void> showSaveApprovalLineDialog(BuildContext context) {
  final controller = TextEditingController(text: '업무기안.202');

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: Row(
        children: [
          Text('개인 결재선으로 저장', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Row(
          children: [
            SizedBox(
              width: 94,
              child: Text('결재선 이름', style: TheWeTextStyle.body),
            ),
            Expanded(child: CustomTextFormField(controller: controller)),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('확인'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}

Future<bool?> showRequestApprovalDialog(
  BuildContext context, {
  required ApprovalDocument document,
}) {
  final controller = TextEditingController();
  var urgent = false;

  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Row(
          children: [
            Text('결재요청', style: TheWeTextStyle.title),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogInfoRow(label: '결재문서명', value: document.title),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text('기안의견', style: TheWeTextStyle.body),
                  ),
                  Expanded(
                    child: CustomTextFormField(
                      controller: controller,
                      minLines: 5,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: '의견을 작성해 주세요.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 100),
                  Checkbox(
                    value: urgent,
                    onChanged: (value) =>
                        setState(() => urgent = value ?? false),
                  ),
                  Text('긴급', style: TheWeTextStyle.body),
                  const SizedBox(width: 12),
                  Text(
                    '선택 시 결재자의 대기문서 가장 상단에 표시됩니다.',
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(urgent),
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
            child: const Text('결재요청'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    ),
  );
}

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
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
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
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
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
                style: TheWeTextStyle.body.copyWith(
                  color: TheWeColor.black500,
                ),
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
                                      selectedTileColor:
                                          TheWeColor.blue100.withValues(
                                            alpha: 0.45,
                                          ),
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
                                      onTap: () =>
                                          setState(() => selectedTemplate = template),
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
                                  color: const Color(0xFFF8FAFC),
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
                    onPressed: () => Navigator.of(context).pop(selectedTemplate),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
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
              const SizedBox(height: 26),
              child,
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: action == '확인'
                            ? FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: TheWeColor.blue300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
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

class _ApprovalLineSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름/아이디/부서/직위/직책/...',
            nodes: [
              '다우오피스',
              '  김윤덕 사장',
              '  웍스 매니저',
              '사업본부',
              '  김경영 상무',
              '  이재오 차장',
              '  관리자 과장',
              '교육관리팀',
              '  교육관리자 부장',
              '  교육강사 부장',
            ],
            selectedIndex: 5,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _SelectedPeopleTable(
                rows: const [
                  ('신청', '기안', '교육강사', '교육관리팀', '기안'),
                  ('승인', '결재', '이재오', '교육관리팀', '대결 승인 대기'),
                  ('승인', '결재', '김경영', '경영관리팀', '결재 예정'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => showSaveApprovalLineDialog(context),
                    child: const Text('개인 결재선으로 저장'),
                  ),
                  const SizedBox(width: 18),
                  Text('합의방식 :', style: TheWeTextStyle.body),
                  const SizedBox(width: 8),
                  const _AgreementOption(label: '순차합의', selected: true),
                  const SizedBox(width: 12),
                  const _AgreementOption(label: '병렬합의'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreementOption extends StatelessWidget {
  const _AgreementOption({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? TheWeColor.blue300 : TheWeColor.black300,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(label, style: TheWeTextStyle.body),
      ],
    );
  }
}

class _PeopleSetup extends StatelessWidget {
  const _PeopleSetup({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름/아이디/부서/직위/직책/...',
            nodes: ['교육관리팀', '  교육관리자 부장', '  교육강사 부장', '기획팀', '  김사원'],
            selectedIndex: 2,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: _SelectedPeopleTable(
            caption: caption,
            rows: const [
              ('추가', '사용자', '교육관리자', '교육관리팀', '저장 전'),
              ('추가', '부서', '기획팀', '기획팀', '저장 전'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicReceiverSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름, 이메일',
            nodes: [
              '공용 주소록',
              '  교육강사 (teacher@study.com)',
              '  김다우 (vipark@daou.co.kr)',
            ],
            selectedIndex: 2,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _SelectedPeopleTable(
                rows: const [('신규 발송', '공문', '김다우', '다우기술', '발신 명의 선택 필요')],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('발신 명의 : ', style: TheWeTextStyle.body),
                  TheWeDropdown<String>(
                    value: '(주)대한민국',
                    width: 160,
                    items: const ['(주)대한민국', '경영지원부문장', '다우기술'],
                    labelBuilder: (value) => value,
                    onChanged: (_) {},
                  ),
                  const SizedBox(width: 12),
                  Text('직인 : ', style: TheWeTextStyle.body),
                  TheWeDropdown<String>(
                    value: '선택',
                    width: 130,
                    items: const ['선택', '대표이사', '부문장'],
                    labelBuilder: (value) => value,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedPeopleTable extends StatelessWidget {
  const _SelectedPeopleTable({required this.rows, this.caption});

  final List<(String, String, String, String, String)> rows;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Column(
        children: [
          Container(
            height: 38,
            color: TheWeColor.black300.withValues(alpha: 0.14),
            child: Row(
              children: ['타입', '구분', '이름', '부서', '상태', '삭제']
                  .map(
                    (header) => Expanded(
                      child: Center(
                        child: Text(
                          header,
                          style: TheWeTextStyle.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...rows.map(
            (row) => SizedBox(
              height: 54,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(row.$1, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$2, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$3, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$4, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$5, style: TheWeTextStyle.caption),
                    ),
                  ),
                  const Expanded(child: Icon(Icons.delete_outline, size: 18)),
                ],
              ),
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  caption!,
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: TheWeTextStyle.body)),
        Expanded(child: Text(value, style: TheWeTextStyle.body)),
      ],
    );
  }
}
