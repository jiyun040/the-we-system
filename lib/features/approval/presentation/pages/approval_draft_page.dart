import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';

class ApprovalDraftPage extends ConsumerStatefulWidget {
  const ApprovalDraftPage({super.key, this.reuseDocumentId});

  final String? reuseDocumentId;

  @override
  ConsumerState<ApprovalDraftPage> createState() => _ApprovalDraftPageState();
}

class _ApprovalDraftPageState extends ConsumerState<ApprovalDraftPage> {
  final titleController = TextEditingController(text: '업무용 PC 구매 예산 할당 요청');
  final contentController = TextEditingController(
    text:
        '업무용 PC 구매 예산 할당 요청 재가 바랍니다.\n\n1. 구매 목적: 노후 PC 교체 및 교육 실습 장비 확보\n2. 구매 품목: 데스크톱 PC 6대, 모니터 6대\n3. 예산 요청: 9,600,000원',
  );
  String selectedForm = '업무기안[기본양식]';

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentAsync = widget.reuseDocumentId == null
        ? null
        : ref.watch(approvalDocumentProvider(widget.reuseDocumentId!));

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: documentAsync == null
            ? _DraftContent(
                document: _draftDocument(),
                titleController: titleController,
                contentController: contentController,
                selectedForm: selectedForm,
                onFormSelected: _selectForm,
              )
            : documentAsync.when(
                data: (document) => _DraftContent(
                  document: document.copyWith(
                    status: '작성중',
                    title: '${document.title} 재기안',
                  ),
                  titleController: titleController
                    ..text = '${document.title} 재기안',
                  contentController: contentController..text = document.content,
                  selectedForm: selectedForm,
                  onFormSelected: _selectForm,
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    '재사용할 결재 문서를 찾을 수 없습니다.',
                    style: TheWeTextStyle.subtitle,
                  ),
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(color: TheWeColor.blue300),
                ),
              ),
      ),
    );
  }

  ApprovalDocument _draftDocument() {
    return ApprovalDocument(
      id: 'DRAFT-NEW',
      title: titleController.text,
      drafter: '교육강사',
      department: '교육관리팀',
      form: selectedForm,
      status: '작성중',
      draftedAt: '2026-06-28',
      dueDate: '2026-06-30',
      progress: 0,
      documentNo: '임시저장 전',
      effectiveDate: '2026-06-30',
      cooperationDepartment: '재경팀',
      agreement: '순차합의',
      content: contentController.text,
      urgent: false,
      receivers: const ['재경팀'],
      references: const ['교육관리팀 부장'],
      viewers: const ['교육관리팀 구성원'],
      publicReceivers: const ['다우기술'],
      linkedDocuments: const ['노후PC 교체 예산 신청 기안'],
      steps: const [
        ApprovalStep(
          name: '교육강사',
          department: '교육관리팀',
          type: '신청',
          role: '부장',
          status: '기안',
        ),
        ApprovalStep(
          name: '이재오',
          department: '교육관리팀',
          type: '승인',
          role: '차장',
          status: '결재 예정',
        ),
        ApprovalStep(
          name: '김경영',
          department: '경영관리팀',
          type: '승인',
          role: '상무',
          status: '결재 예정',
        ),
      ],
    );
  }

  void _selectForm(String form) {
    setState(() {
      selectedForm = form;
      if (form.contains('휴가')) {
        titleController.text = '7월 교육관리팀 팀 휴가 일정 승인';
        contentController.text =
            '교육관리팀 7월 휴가 일정을 아래와 같이 상신합니다.\n\n1. 휴가 기간: 2026-07-08 ~ 2026-07-12\n2. 대상자: 교육강사, 교육관리자, 운영지원 담당자\n3. 업무 인수인계: 이재오 차장이 교육 문의 1차 대응\n4. 요청사항: 팀 휴가 일정 승인 및 인사관리팀 공유';
      } else if (form.contains('구매')) {
        titleController.text = '업무용 PC 구매 예산 할당 요청';
        contentController.text =
            '업무용 PC 구매 예산 할당 요청 재가 바랍니다.\n\n1. 구매 목적: 노후 PC 교체 및 교육 실습 장비 확보\n2. 구매 품목: 데스크톱 PC 6대, 모니터 6대\n3. 예산 요청: 9,600,000원';
      } else {
        titleController.text = '정산을 위한 운영인력 충원의 건';
        contentController.text =
            '신규 콘텐츠 마케팅 진행에 따라 원활한 정산을 위한 운영 인력 채용 또는 내부 인력 배정을 받고자 하오니 검토 후 재가하여 주시기 바랍니다.';
      }
    });
  }
}

class _DraftContent extends StatelessWidget {
  const _DraftContent({
    required this.document,
    required this.titleController,
    required this.contentController,
    required this.selectedForm,
    required this.onFormSelected,
  });

  final ApprovalDocument document;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String selectedForm;
  final ValueChanged<String> onFormSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DraftToolbar(
          document: document,
          onPreview: () => _showPreview(context, document),
        ),
        Divider(height: 1, color: TheWeColor.black300.withValues(alpha: 0.35)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final catalog = SizedBox(
                width: isNarrow ? double.infinity : 320,
                height: isNarrow ? 280 : null,
                child: _FormCatalog(
                  selectedForm: selectedForm,
                  onFormSelected: onFormSelected,
                ),
              );
              final sheet = SingleChildScrollView(
                padding: EdgeInsets.all(isNarrow ? 16 : 28),
                child: Center(
                  child: _EditableDraftSheet(
                    document: document.copyWith(
                      title: titleController.text,
                      content: contentController.text,
                    ),
                    titleController: titleController,
                    contentController: contentController,
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    catalog,
                    Divider(
                      height: 1,
                      color: TheWeColor.black300.withValues(alpha: 0.35),
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
                    Text('수신자 미리보기', style: TheWeTextStyle.title),
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
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '받는 사람 화면에서는 아래 문서와 결재/반려/보류 액션이 함께 보입니다.',
                          style: TheWeTextStyle.body.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ApprovalDocumentSheet(
                        document: document.copyWith(
                          title: titleController.text,
                          content: contentController.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftToolbar extends StatelessWidget {
  const _DraftToolbar({required this.document, required this.onPreview});

  final ApprovalDocument document;
  final VoidCallback onPreview;

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
              _DraftAction(
                icon: Icons.edit_note,
                label: '결재요청',
                onPressed: () =>
                    showRequestApprovalDialog(context, document: document),
              ),
              _DraftAction(
                icon: Icons.save_alt,
                label: '임시저장',
                onPressed: () {},
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
              _DraftAction(
                icon: Icons.article_outlined,
                label: '양식 선택',
                onPressed: () => showApprovalFormDialog(context),
              ),
              _DraftAction(
                icon: Icons.attach_file,
                label: '문서 연결',
                onPressed: () => showAttachDocumentDialog(context),
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
    required this.selectedForm,
    required this.onFormSelected,
  });

  final String selectedForm;
  final ValueChanged<String> onFormSelected;

  static const forms = {
    '근태': ['팀 휴가 결재서', '휴가 신청서', '연장근무 신청서'],
    '지원': ['업무기안[기본양식]', '구매 요청서', '지출 결의서'],
    '협조': ['업무협조[기본양식]', '공문 발송 협조서'],
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결재양식 선택', style: TheWeTextStyle.title),
          const SizedBox(height: 12),
          Text(
            '폴더를 열어 하위 양식을 선택하세요.',
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 18),
          ...forms.entries.map(
            (entry) => ExpansionTile(
              initiallyExpanded: entry.value.contains(selectedForm),
              leading: Icon(Icons.folder_outlined, color: TheWeColor.black500),
              title: Text(entry.key, style: TheWeTextStyle.body),
              children: entry.value
                  .map(
                    (form) => ListTile(
                      dense: true,
                      selected: selectedForm == form,
                      selectedTileColor: TheWeColor.blue100.withValues(
                        alpha: 0.45,
                      ),
                      leading: Icon(
                        Icons.description_outlined,
                        color: selectedForm == form
                            ? TheWeColor.blue300
                            : TheWeColor.black500,
                      ),
                      title: Text(form, style: TheWeTextStyle.body),
                      onTap: () => onFormSelected(form),
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
  });

  final ApprovalDocument document;
  final TextEditingController titleController;
  final TextEditingController contentController;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 980),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TheWeColor.black900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            document.form.contains('휴가') ? '휴 가 신 청' : '기 안 용 지',
            textAlign: TextAlign.center,
            style: TheWeTextStyle.pageTitle.copyWith(
              fontSize: 30,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 22),
          _DraftInfoRow(label: '기 안 자', value: document.drafter),
          _DraftInfoRow(label: '부    서', value: document.department),
          _DraftInfoRow(label: '기 안 일', value: document.draftedAt),
          _DraftInfoRow(label: '수    신', value: document.receivers.join(', ')),
          _DraftInfoRow(label: '참    조', value: document.references.join(', ')),
          _DraftInputRow(label: '제    목', controller: titleController),
          Container(
            height: 34,
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
          Text('파일 첨부', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: TheWeColor.black300.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: TheWeColor.black500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '구매견적서.pdf, 팀휴가일정.xlsx',
                    style: TheWeTextStyle.body,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('파일 추가'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftInfoRow extends StatelessWidget {
  const _DraftInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _DraftRow(
      label: label,
      child: Text(value, style: TheWeTextStyle.body),
    );
  }
}

class _DraftInputRow extends StatelessWidget {
  const _DraftInputRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _DraftRow(
      label: label,
      child: CustomTextFormField(controller: controller),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
      child: Row(
        children: [
          Container(
            width: 120,
            constraints: const BoxConstraints(minHeight: 42),
            alignment: Alignment.center,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
