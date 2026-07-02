import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';

class ApprovalDraftPage extends ConsumerStatefulWidget {
  const ApprovalDraftPage({
    super.key,
    this.reuseDocumentId,
    this.selectedFormId,
  });

  final String? reuseDocumentId;
  final String? selectedFormId;

  @override
  ConsumerState<ApprovalDraftPage> createState() => _ApprovalDraftPageState();
}

class _ApprovalDraftPageState extends ConsumerState<ApprovalDraftPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  String? selectedFormId;
  String? editingDocumentId;
  List<String> linkedDocuments = [];
  bool initialized = false;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: state.when(
          data: (appState) {
            final sourceDocument = widget.reuseDocumentId == null
                ? null
                : ref.watch(approvalDocumentProvider(widget.reuseDocumentId!));
            final seedDocument = _seedDocument(appState, sourceDocument);
            final currentFormId =
                selectedFormId ??
                widget.selectedFormId ??
                appState.formTemplates.first.id;
            final currentTemplate = appState.formTemplates
                .where((template) => template.id == currentFormId)
                .firstOrNull;

            if (!initialized) {
              selectedFormId = currentFormId;
              titleController.text = seedDocument.title;
              contentController.text = seedDocument.content;
              linkedDocuments = [...seedDocument.linkedDocuments];
              editingDocumentId = sourceDocument?.status == '작성중'
                  ? sourceDocument?.id
                  : null;
              initialized = true;
            }

            final draftDocument = seedDocument.copyWith(
              title: titleController.text,
              content: contentController.text,
              form: currentTemplate?.name ?? seedDocument.form,
              linkedDocuments: linkedDocuments,
            );

            return Column(
              children: [
                _DraftToolbar(
                  document: draftDocument,
                  canRequest: selectedFormId != null,
                  onPreview: () => _showPreview(context, draftDocument),
                  onRequest: () => _requestApproval(draftDocument),
                  onSave: _saveDraft,
                ),
                Divider(
                  height: 1,
                  color: TheWeColor.black300.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 760;
                      final catalog = SizedBox(
                        width: isNarrow ? double.infinity : 320,
                        height: isNarrow ? 300 : null,
                        child: _FormCatalog(
                          templates: appState.formTemplates,
                          selectedFormId: currentFormId,
                          onFormSelected: (formId) {
                            setState(() {
                              selectedFormId = formId;
                              final template = appState.formTemplates
                                  .where((item) => item.id == formId)
                                  .first;
                              titleController.text = template.defaultTitle;
                              contentController.text = template.defaultContent;
                              linkedDocuments = [];
                              editingDocumentId = null;
                            });
                          },
                        ),
                      );
                      final sheet = SingleChildScrollView(
                        padding: EdgeInsets.all(isNarrow ? 16 : 28),
                        child: Center(
                          child: _EditableDraftSheet(
                            document: draftDocument,
                            titleController: titleController,
                            contentController: contentController,
                            onAddAttachment: _addAttachmentFile,
                            onAddLinkedDocument: () =>
                                _addLinkedDocument(appState),
                            onRemoveLinkedDocument: (item) {
                              setState(() {
                                linkedDocuments = [
                                  for (final current in linkedDocuments)
                                    if (current != item) current,
                                ];
                              });
                            },
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            catalog,
                            Divider(
                              height: 1,
                              color: TheWeColor.black300.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            Expanded(child: sheet),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          catalog,
                          VerticalDivider(
                            width: 1,
                            color: TheWeColor.black300.withValues(alpha: 0.35),
                          ),
                          Expanded(child: sheet),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
          error: (error, stackTrace) => Center(
            child: Text('기안 문서를 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: TheWeColor.blue300),
          ),
        ),
      ),
    );
  }

  ApprovalDocument _seedDocument(
    ApprovalDashboardState state,
    ApprovalDocument? sourceDocument,
  ) {
    if (sourceDocument != null && sourceDocument.status == '작성중') {
      selectedFormId ??= _findTemplateIdByName(state, sourceDocument.form);
      return sourceDocument;
    }

    if (sourceDocument != null) {
      final templateId = _findTemplateIdByName(state, sourceDocument.form);
      selectedFormId ??= templateId;
      final template = state.formTemplates
          .where((item) => item.id == templateId)
          .firstOrNull;
      final base = ref
          .read(approvalDashboardControllerProvider.notifier)
          .buildDraftDocument(templateId);
      return base.copyWith(
        title: '${sourceDocument.title} 재기안',
        content: sourceDocument.content,
        form: template?.name ?? sourceDocument.form,
      );
    }

    final formId =
        selectedFormId ?? widget.selectedFormId ?? state.formTemplates.first.id;
    selectedFormId ??= formId;
    return ref
        .read(approvalDashboardControllerProvider.notifier)
        .buildDraftDocument(formId);
  }

  String _findTemplateIdByName(ApprovalDashboardState state, String formName) {
    return state.formTemplates
            .where((item) => item.name == formName)
            .firstOrNull
            ?.id ??
        state.formTemplates.first.id;
  }

  Future<void> _requestApproval(ApprovalDocument document) async {
    final urgent = await showRequestApprovalDialog(context, document: document);
    if (urgent == null) {
      return;
    }

    final formId = selectedFormId;
    if (formId == null) {
      return;
    }

    final id = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .requestApproval(
          documentId: editingDocumentId,
          draft: ApprovalRequestDraft(
            formId: formId,
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            urgent: urgent,
            linkedDocuments: linkedDocuments,
          ),
        );
    if (id != null && mounted) {
      context.goNamed(AppRouteName.detail, pathParameters: {'id': id});
    }
  }

  Future<void> _saveDraft() async {
    final formId = selectedFormId;
    if (formId == null) {
      return;
    }

    final id = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .saveDraft(
          formId: formId,
          documentId: editingDocumentId,
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          linkedDocuments: linkedDocuments,
        );
    if (id == null || !mounted) {
      return;
    }

    setState(() {
      editingDocumentId = id;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('임시 저장되었습니다.')));
  }

  void _showPreview(BuildContext context, ApprovalDocument document) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1080,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 18, 12),
                child: Row(
                  children: [
                    Text('기안 미리보기', style: TheWeTextStyle.title),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: TheWeColor.black300),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ApprovalDocumentSheet(document: document),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addAttachmentFile() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('파일 첨부', style: TheWeTextStyle.title),
        content: SizedBox(
          width: 420,
          child: CustomTextFormField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '첨부할 파일명을 입력하세요. 예: 계약서.pdf',
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
            child: const Text('추가'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }

    setState(() {
      if (!linkedDocuments.contains('[첨부] $normalized')) {
        linkedDocuments = [...linkedDocuments, '[첨부] $normalized'];
      }
    });
  }

  Future<void> _addLinkedDocument(ApprovalDashboardState appState) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _LinkedDocumentDialog(
        documents: appState.documents
            .where((document) => document.id != editingDocumentId)
            .toList(),
      ),
    );
    if (selected == null || selected.isEmpty) {
      return;
    }

    setState(() {
      if (!linkedDocuments.contains(selected)) {
        linkedDocuments = [...linkedDocuments, selected];
      }
    });
  }
}

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
    return Container(
      constraints: const BoxConstraints(maxWidth: 980),
      padding: const EdgeInsets.all(18),
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
              fontSize: 32,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              return Flex(
                direction: narrow ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: narrow ? 0 : 5,
                    child: Column(
                      children: [
                        _DraftInfoRow(label: '기 안 자', value: document.drafter),
                        _DraftInfoRow(
                          label: '부    서',
                          value: document.department,
                        ),
                        _DraftInfoRow(
                          label: '기 안 일',
                          value: document.draftedAt,
                        ),
                        _DraftInfoRow(
                          label: '수    신',
                          value: document.receivers.join(', '),
                        ),
                        _DraftInfoRow(
                          label: '참    조',
                          value: document.references.join(', '),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: narrow ? 0 : 20, height: narrow ? 16 : 0),
                  Expanded(
                    flex: narrow ? 0 : 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('결재 라인', style: TheWeTextStyle.subtitle),
                        const SizedBox(height: 8),
                        ApprovalStampTable(steps: document.steps),
                      ],
                    ),
                  ),
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
    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('연결 문서 선택', style: TheWeTextStyle.title),
      content: SizedBox(
        width: 540,
        height: 360,
        child: widget.documents.isEmpty
            ? Center(
                child: Text('연결할 수 있는 문서가 없습니다.', style: TheWeTextStyle.body),
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
      actions: [
        FilledButton(
          onPressed: selectedId == null
              ? null
              : () {
                  final document = widget.documents
                      .where((item) => item.id == selectedId)
                      .first;
                  Navigator.of(
                    context,
                  ).pop('[연결] ${document.documentNo} ${document.title}');
                },
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('추가'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _DraftInfoRow extends StatelessWidget {
  const _DraftInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
      child: Row(
        children: [
          Container(
            width: 110,
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
      child: Row(
        children: [
          Container(
            width: 110,
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
