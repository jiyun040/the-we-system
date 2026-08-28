import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'approval_document_sheet_attachments.dart';
import 'approval_document_sheet_body.dart';
import 'approval_document_sheet_tables.dart';

class ApprovalDocumentSheet extends StatelessWidget {
  const ApprovalDocumentSheet({super.key, required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      constraints: const BoxConstraints(maxWidth: 980),
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        border: Border.all(color: TheWeColor.black900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _sheetTitle(document.form),
            textAlign: TextAlign.center,
            style: TheWeTextStyle.pageTitle.copyWith(
              fontSize: compact ? 24 : 30,
              letterSpacing: compact ? 3 : 6,
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
                    child: ApprovalBasicInfoTable(document: document),
                  ),
                  SizedBox(width: narrow ? 0 : 20, height: narrow ? 16 : 0),
                  Expanded(
                    flex: narrow ? 0 : 6,
                    child: ApprovalStampTable(steps: document.steps),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (document.documentLayout == 'payroll')
            ApprovalWideRow(label: '제    목', value: document.title),
          if (document.documentLayout == 'basic') ...[
            ApprovalSectionHeader(title: '상 세 내 용'),
            Container(
              constraints: const BoxConstraints(minHeight: 420),
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 28,
                compact ? 16 : 24,
                compact ? 14 : 28,
                compact ? 24 : 36,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: TheWeColor.black900),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(1),
                ),
              ),
              child: Text(
                document.content,
                style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.8),
              ),
            ),
          ] else
            ApprovalPdfDocumentBody(document: document),
          if (document.attachments.isNotEmpty) ...[
            const SizedBox(height: 22),
            ApprovalDocumentAttachmentArea(files: document.attachments),
          ],
        ],
      ),
    );
  }

  String _sheetTitle(String form) {
    if (document.documentLayout == 'expense') {
      return '지출결의서(지급품의)';
    }
    if (document.documentLayout == 'hospitality') {
      return '지출결의서(기업업무추진비)';
    }
    if (document.documentLayout == 'purchase') {
      return '비품/소모품 구입신청서';
    }
    if (document.documentLayout == 'payroll') {
      return '급여대장 기안서';
    }
    if (form.contains('협조')) {
      return '업 무 협 조';
    }
    if (form.contains('휴가')) {
      return '휴 가 신 청';
    }
    return '업 무 기 안';
  }
}
