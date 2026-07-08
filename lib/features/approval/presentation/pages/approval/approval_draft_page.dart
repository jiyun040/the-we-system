import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';

part 'approval_draft_toolbar.dart';
part 'approval_draft_sheet.dart';
part 'approval_draft_linked_documents.dart';

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
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 1)
          : null,
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
