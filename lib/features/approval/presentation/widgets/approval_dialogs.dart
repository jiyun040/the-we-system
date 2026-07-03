import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/layout.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

part 'approval_info_dialog.dart';
part 'approval_dialog_layout.dart';
part 'approval_line_dialog.dart';

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
