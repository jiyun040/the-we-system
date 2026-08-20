import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

import 'approval_dialog_layout.dart';
import 'approval_info_dialog.dart';
import 'approval_line_dialog.dart';

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
    builder: (context) => TheWeModalSurface(
      maxWidth: 640,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '$action하기',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalDialogInfoRow(label: '결재문서명', value: document.title),
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
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.pink,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: action,
            secondaryLabel: '취소',
            primaryColor: action == '승인' ? TheWeColor.blue300 : TheWeColor.pink,
            onPrimaryPressed: () async {
              await onConfirm(opinionController.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            onSecondaryPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

Future<ApprovalFormTemplate?> showDraftFormSelectionDialog(
  BuildContext context, {
  required List<ApprovalFormTemplate> templates,
}) {
  return showDialog<ApprovalFormTemplate>(
    context: context,
    builder: (context) =>
        ApprovalDraftFormSelectionDialog(templates: templates),
  );
}

Future<void> showApprovalFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => ApprovalLargeDialog(
      title: '결재양식 선택',
      actions: const ['확인', '취소'],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ApprovalTreePanel(
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
            child: ApprovalDetailBox(
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
    builder: (context) => ApprovalLargeDialog(
      title: '결재 문서 첨부',
      actions: const ['확인', '취소'],
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ApprovalTreePanel(
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
            child: ApprovalDocumentPickerTable(
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
    builder: (context) => const ApprovalInfoDialog(),
  );
}

Future<void> showSaveApprovalLineDialog(BuildContext context) {
  final controller = TextEditingController(text: '업무기안.202');

  return showDialog<void>(
    context: context,
    builder: (context) => TheWeModalSurface(
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TheWeModalAlertIcon(),
          const SizedBox(height: 18),
          Text(
            '개인 결재선으로 저장',
            textAlign: TextAlign.center,
            style: TheWeTextStyle.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 94,
                child: Text('결재선 이름', style: TheWeTextStyle.body),
              ),
              Expanded(child: CustomTextFormField(controller: controller)),
            ],
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            centered: true,
            primaryLabel: '확인',
            secondaryLabel: '취소',
            onPrimaryPressed: () => Navigator.of(context).pop(),
            onSecondaryPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
      builder: (context, setState) => TheWeModalSurface(
        maxWidth: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '결재요청',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ApprovalDialogInfoRow(label: '결재문서명', value: document.title),
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
                          style: TheWeTextStyle.body.copyWith(
                            fontSize: 16,
                            height: 1.5,
                          ),
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
                      Expanded(
                        child: Text(
                          '선택 시 결재자의 대기문서 가장 상단에 표시됩니다.',
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            TheWeModalActions(
              primaryLabel: '결재요청',
              secondaryLabel: '취소',
              primaryColor: TheWeColor.blue300,
              onPrimaryPressed: () => Navigator.of(context).pop(urgent),
              onSecondaryPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
