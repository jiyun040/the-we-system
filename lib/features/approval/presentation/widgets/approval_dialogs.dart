import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

import 'approval_dialog_layout.dart';
import 'approval_info_dialog.dart';

Future<void> showApprovalDecisionDialog(
  BuildContext context, {
  required ApprovalDocument document,
  required String action,
  required Future<void> Function(String opinion) onConfirm,
}) {
  final opinionController = TextEditingController(text: '');

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
}) async {
  if (templates.isEmpty) {
    showTheWeSnackBar(
      context,
      message: '사용 가능한 결재 양식이 없습니다. 관리자 설정에서 양식을 먼저 등록해 주세요.',
      type: TheWeSnackBarType.info,
    );
    return null;
  }

  return showDialog<ApprovalFormTemplate>(
    context: context,
    builder: (context) =>
        ApprovalDraftFormSelectionDialog(templates: templates),
  );
}

Future<void> showApprovalInfoDialog(
  BuildContext context, {
  required ApprovalDocument document,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => ApprovalInfoDialog(document: document),
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
