import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_input_formatters.dart';

import 'approval_draft_linked_documents.dart';
import 'approval_draft_sheet.dart';
import 'approval_draft_toolbar.dart';

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
  String? selectedApprovalLineId;
  List<String> linkedDocuments = [];
  List<ApprovalAttachment> attachments = [];
  Map<String, String> formFields = {};
  List<Map<String, String>> lineItems = [];
  final Set<int> manuallyEditedLineTotals = {};
  bool departmentVisible = false;
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
      appBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationAppBar()
          : null,
      drawer: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationDrawer()
          : null,
      body: SafeArea(
        child: state.when(
          data: (appState) {
            final availableTemplates = appState.activeFormTemplates;
            if (availableTemplates.isEmpty) {
              return Center(
                child: Text(
                  '서버에 사용 가능한 결재 양식이 없습니다.',
                  style: TheWeTextStyle.subtitle,
                ),
              );
            }
            final sourceDocument = widget.reuseDocumentId == null
                ? null
                : ref.watch(approvalDocumentProvider(widget.reuseDocumentId!));
            final initialDocument = _initialDocument(appState, sourceDocument);
            final currentFormId =
                availableTemplates.any((form) => form.id == selectedFormId)
                ? selectedFormId!
                : availableTemplates.any(
                    (form) => form.id == widget.selectedFormId,
                  )
                ? widget.selectedFormId!
                : availableTemplates.first.id;
            final currentTemplate = availableTemplates
                .where((template) => template.id == currentFormId)
                .firstOrNull;

            if (!initialized) {
              selectedFormId = currentFormId;
              titleController.text = initialDocument.title;
              contentController.text = initialDocument.content;
              linkedDocuments = [...initialDocument.linkedDocuments];
              attachments = [...initialDocument.attachments];
              formFields = {...initialDocument.formFields};
              if (currentTemplate?.documentLayout ==
                      ApprovalDocumentLayout.hospitality &&
                  (formFields['draftedAt']?.isEmpty ?? true)) {
                formFields['draftedAt'] = initialDocument.draftedAt;
              }
              lineItems = initialDocument.lineItems
                  .map((item) => {...item})
                  .toList();
              departmentVisible = false;
              editingDocumentId = sourceDocument?.status == '작성중'
                  ? sourceDocument?.id
                  : null;
              selectedApprovalLineId = _approvalLineIdForDocument(
                currentTemplate,
                initialDocument,
                appState.accounts,
              );
              initialized = true;
            }

            final selectedApprovalLine = currentTemplate?.approvalLines
                .where((line) => line.id == selectedApprovalLineId)
                .firstOrNull;

            final draftDocument = initialDocument.copyWith(
              title: titleController.text,
              content: contentController.text,
              form: currentTemplate?.name ?? initialDocument.form,
              linkedDocuments: linkedDocuments,
              attachments: attachments,
              draftedAt:
                  currentTemplate?.documentLayout ==
                      ApprovalDocumentLayout.hospitality
                  ? (formFields['draftedAt'] ?? initialDocument.draftedAt)
                  : initialDocument.draftedAt,
              documentLayout:
                  currentTemplate?.documentLayout ??
                  initialDocument.documentLayout,
              formFields: formFields,
              lineItems: lineItems,
              steps: appState.currentUser == null
                  ? initialDocument.steps
                  : buildApprovalStepsFor(
                      appState.currentUser!,
                      appState.accounts,
                      approverIds: selectedApprovalLine?.userIds,
                    ),
            );

            return Column(
              children: [
                ApprovalDraftToolbar(
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
                      void selectForm(String formId) {
                        setState(() {
                          selectedFormId = formId;
                          final template = availableTemplates
                              .where((item) => item.id == formId)
                              .first;
                          titleController.text = template.defaultTitle;
                          contentController.text = template.defaultContent;
                          linkedDocuments = [];
                          attachments = [];
                          formFields =
                              template.documentLayout ==
                                  ApprovalDocumentLayout.hospitality
                              ? {'draftedAt': _draftToday()}
                              : {};
                          lineItems =
                              template.documentLayout ==
                                      ApprovalDocumentLayout.basic ||
                                  template.documentLayout ==
                                      ApprovalDocumentLayout.payroll
                              ? []
                              : List.generate(
                                  template.lineItemRows,
                                  (_) => <String, String>{},
                                );
                          manuallyEditedLineTotals.clear();
                          departmentVisible = false;
                          editingDocumentId = null;
                          selectedApprovalLineId =
                              template.approvalLines.firstOrNull?.id;
                        });
                      }

                      final catalog = isNarrow
                          ? ApprovalCompactFormSelector(
                              templates: availableTemplates,
                              selectedFormId: currentFormId,
                              onFormSelected: selectForm,
                            )
                          : SizedBox(
                              width: 320,
                              child: ApprovalFormCatalog(
                                templates: availableTemplates,
                                selectedFormId: currentFormId,
                                onFormSelected: selectForm,
                              ),
                            );
                      final sheet = SingleChildScrollView(
                        padding: EdgeInsets.all(isNarrow ? 16 : 28),
                        child: Center(
                          child: ApprovalEditableDraftSheet(
                            document: draftDocument,
                            titleController: titleController,
                            contentController: contentController,
                            onAddAttachment: _addAttachmentFile,
                            onDropAttachments: _addAttachmentFiles,
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
                            onRemoveAttachment: (attachment) {
                              setState(() {
                                attachments = [
                                  for (final current in attachments)
                                    if (current != attachment) current,
                                ];
                              });
                            },
                            departmentVisible: departmentVisible,
                            onDepartmentVisibilityChanged: (value) {
                              setState(() => departmentVisible = value);
                            },
                            onFormFieldChanged: (key, value) {
                              setState(() => formFields[key] = value);
                            },
                            onLineItemChanged: (index, key, value) {
                              setState(() {
                                final updatedItem = <String, String>{
                                  ...lineItems[index],
                                  key: value,
                                };
                                if (key == 'total') {
                                  final calculated =
                                      calculateApprovalLineItemTotal(
                                        quantity: updatedItem['quantity'] ?? '',
                                        amount: updatedItem['amount'] ?? '',
                                      );
                                  final entered = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  if (entered == calculated) {
                                    manuallyEditedLineTotals.remove(index);
                                  } else {
                                    manuallyEditedLineTotals.add(index);
                                  }
                                } else if ((key == 'quantity' ||
                                        key == 'amount') &&
                                    !manuallyEditedLineTotals.contains(index)) {
                                  updatedItem['total'] =
                                      calculateApprovalLineItemTotal(
                                        quantity: updatedItem['quantity'] ?? '',
                                        amount: updatedItem['amount'] ?? '',
                                      );
                                }
                                lineItems[index] = updatedItem;
                              });
                            },
                          ),
                        ),
                      );
                      final lineSelector =
                          currentTemplate == null ||
                              currentTemplate.approvalLines.isEmpty
                          ? const SizedBox.shrink()
                          : _DraftApprovalLineSelector(
                              lines: currentTemplate.approvalLines,
                              selectedLine:
                                  selectedApprovalLine ??
                                  currentTemplate.approvalLines.first,
                              onChanged: (line) => setState(
                                () => selectedApprovalLineId = line.id,
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
                            lineSelector,
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
                          Expanded(
                            child: Column(
                              children: [
                                lineSelector,
                                Expanded(child: sheet),
                              ],
                            ),
                          ),
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

  ApprovalDocument _initialDocument(
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
        documentLayout: sourceDocument.documentLayout,
        formFields: sourceDocument.formFields,
        lineItems: sourceDocument.lineItems,
        linkedDocuments: sourceDocument.linkedDocuments,
        attachments: sourceDocument.attachments,
      );
    }

    final availableTemplates = state.activeFormTemplates;
    final preferredId = selectedFormId ?? widget.selectedFormId;
    final formId = availableTemplates.any((form) => form.id == preferredId)
        ? preferredId!
        : availableTemplates.first.id;
    selectedFormId ??= formId;
    return ref
        .read(approvalDashboardControllerProvider.notifier)
        .buildDraftDocument(formId);
  }

  String _findTemplateIdByName(ApprovalDashboardState state, String formName) {
    return state.activeFormTemplates
            .where((item) => item.name == formName)
            .firstOrNull
            ?.id ??
        state.activeFormTemplates.first.id;
  }

  String? _approvalLineIdForDocument(
    ApprovalFormTemplate? template,
    ApprovalDocument document,
    List<EmployeeAccount> accounts,
  ) {
    if (template == null || template.approvalLines.isEmpty) return null;
    final documentNames = document.steps
        .skip(1)
        .map((step) => step.name)
        .toList();
    for (final line in template.approvalLines) {
      final lineNames = line.userIds
          .map(
            (id) =>
                accounts.where((account) => account.id == id).firstOrNull?.name,
          )
          .whereType<String>()
          .toList();
      if (lineNames.length == documentNames.length &&
          List.generate(
            lineNames.length,
            (index) => lineNames[index] == documentNames[index],
          ).every((matches) => matches)) {
        return line.id;
      }
    }
    return template.approvalLines.first.id;
  }

  Future<void> _requestApproval(ApprovalDocument document) async {
    if (document.documentLayout == ApprovalDocumentLayout.hospitality &&
        DateTime.tryParse(formFields['draftedAt']?.trim() ?? '') == null) {
      showTheWeSnackBar(
        context,
        message: '기안일을 YYYY-MM-DD 형식으로 입력해 주세요.',
        type: TheWeSnackBarType.error,
      );
      return;
    }
    final urgent = await showRequestApprovalDialog(context, document: document);
    if (urgent == null) {
      return;
    }
    if (!mounted) return;

    final formId = selectedFormId;
    if (formId == null) {
      showTheWeSnackBar(
        context,
        message: '결재 양식을 먼저 선택해 주세요.',
        type: TheWeSnackBarType.error,
      );
      return;
    }

    final id = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .requestApproval(
          documentId: editingDocumentId,
          approvalLineId: selectedApprovalLineId,
          draft: ApprovalRequestDraft(
            formId: formId,
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            urgent: urgent,
            linkedDocuments: linkedDocuments,
            attachments: attachments,
            departmentVisible: departmentVisible,
            documentLayout: document.documentLayout,
            formFields: formFields,
            lineItems: lineItems,
          ),
        );
    if (id != null && mounted) {
      context.goNamed(AppRouteName.detail, pathParameters: {'id': id});
    }
  }

  String _draftToday() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _saveDraft() async {
    final formId = selectedFormId;
    if (formId == null) {
      showTheWeSnackBar(
        context,
        message: '결재 양식을 먼저 선택해 주세요.',
        type: TheWeSnackBarType.error,
      );
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
          attachments: attachments,
          departmentVisible: departmentVisible,
          formFields: formFields,
          lineItems: lineItems,
          approvalLineId: selectedApprovalLineId,
        );
    if (id == null || !mounted) {
      return;
    }

    setState(() {
      editingDocumentId = id;
    });
    showTheWeSnackBar(context, message: '임시 저장되었습니다.');
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
    final file = await openFile();
    if (file == null) {
      return;
    }

    await _addAttachmentFiles([file]);
  }

  Future<void> _addAttachmentFiles(List<XFile> files) async {
    final accepted = <ApprovalAttachment>[];
    var oversizedCount = 0;
    var emptyCount = 0;
    var unreadableCount = 0;

    for (final file in files) {
      Uint8List bytes;
      try {
        bytes = await _readAttachmentBytes(file);
      } catch (_) {
        unreadableCount++;
        continue;
      }
      if (bytes.isEmpty) {
        emptyCount++;
        continue;
      }
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        oversizedCount++;
        continue;
      }

      accepted.add(
        ApprovalAttachment.fromBytes(
          name: file.name,
          mimeType: file.mimeType ?? 'application/octet-stream',
          bytes: bytes,
        ),
      );
    }

    if (!mounted) return;

    if (accepted.isNotEmpty) {
      final acceptedNames = accepted.map((item) => item.name).toSet();
      setState(() {
        attachments = [
          for (final current in attachments)
            if (!acceptedNames.contains(current.name)) current,
          ...accepted,
        ];
      });
    }

    if (oversizedCount > 0 || emptyCount > 0 || unreadableCount > 0) {
      final reasons = [
        if (oversizedCount > 0) '10MB 초과 파일 $oversizedCount개',
        if (emptyCount > 0) '빈 파일 $emptyCount개',
        if (unreadableCount > 0) '읽을 수 없는 파일 $unreadableCount개',
      ].join(', ');
      showTheWeSnackBar(
        context,
        message: '$reasons는 첨부하지 않았습니다.',
        type: TheWeSnackBarType.error,
      );
    }
  }

  Future<Uint8List> _readAttachmentBytes(XFile file) async {
    final bookmark = file is DropItem ? file.extraAppleBookmark : null;
    var securityAccessStarted = false;
    try {
      if (bookmark != null && bookmark.isNotEmpty) {
        securityAccessStarted = await DesktopDrop.instance
            .startAccessingSecurityScopedResource(bookmark: bookmark);
      }
      return await file.readAsBytes();
    } finally {
      if (securityAccessStarted && bookmark != null) {
        await DesktopDrop.instance.stopAccessingSecurityScopedResource(
          bookmark: bookmark,
        );
      }
    }
  }

  Future<void> _addLinkedDocument(ApprovalDashboardState appState) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => ApprovalLinkedDocumentDialog(
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

class _DraftApprovalLineSelector extends StatelessWidget {
  const _DraftApprovalLineSelector({
    required this.lines,
    required this.selectedLine,
    required this.onChanged,
  });

  final List<ApprovalLinePreset> lines;
  final ApprovalLinePreset selectedLine;
  final ValueChanged<ApprovalLinePreset> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('draft-approval-line-selector'),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    color: TheWeColor.blueSurface,
    child: Row(
      children: [
        const Icon(Icons.account_tree_outlined, color: TheWeColor.blue300),
        const SizedBox(width: 10),
        Text('결재라인 선택', style: TheWeTextStyle.subtitle),
        const SizedBox(width: 16),
        Expanded(
          child: TheWeDropdown<ApprovalLinePreset>(
            key: const ValueKey('draft-approval-line-dropdown'),
            value: selectedLine,
            items: lines,
            labelBuilder: (line) => line.name,
            onChanged: (line) {
              if (line != null) onChanged(line);
            },
          ),
        ),
      ],
    ),
  );
}
