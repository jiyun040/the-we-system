import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_input_formatters.dart';

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
                    child: _BasicInfoTable(document: document),
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
          _DocumentMetaTable(document: document),
          if (document.documentLayout == 'basic') ...[
            _SectionHeader(title: '상 세 내 용'),
            Container(
              constraints: const BoxConstraints(minHeight: 340),
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
            _PdfDocumentBody(document: document),
          if (document.attachments.isNotEmpty) ...[
            const SizedBox(height: 22),
            _DocumentAttachmentArea(files: document.attachments),
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

class _PdfDocumentBody extends StatelessWidget {
  const _PdfDocumentBody({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    if (document.documentLayout == 'payroll') {
      return Column(
        children: [
          _ReadOnlyWideRow(
            label: '참    조',
            value: document.formFields['reference'] ?? '-',
          ),
          _SectionHeader(title: '상 세 내 용'),
          _ReadOnlyContent(content: document.content, minHeight: 260),
        ],
      );
    }

    final columns = _columnsFor(document.documentLayout);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyWideRow(
          label: '비    고',
          value: document.formFields['note'] ?? '-',
        ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < 720 ? 720 : constraints.maxWidth,
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columns
                          .map(
                            (column) => Expanded(
                              flex: column.$3,
                              child: _ReadOnlyTableCell(
                                text: column.$2,
                                header: true,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ...document.lineItems
                      .where(
                        (item) => item.values.any((value) => value.isNotEmpty),
                      )
                      .map(
                        (item) => IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: columns
                                .map(
                                  (column) => Expanded(
                                    flex: column.$3,
                                    child: _ReadOnlyTableCell(
                                      text: _displayLineItemValue(
                                        column.$1,
                                        item[column.$1] ?? '',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 8,
                          child: _ReadOnlyTableCell(
                            text: '합    계 (V.A.T 포함)',
                            header: true,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ReadOnlyTableCell(
                            text: _totalAmount(document.lineItems),
                            header: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '위 금액을 청구하오니 결재하여 주시기 바랍니다.',
          textAlign: TextAlign.center,
          style: TheWeTextStyle.body,
        ),
        const SizedBox(height: 24),
        Text(
          '우리기술 주식회사',
          textAlign: TextAlign.center,
          style: TheWeTextStyle.subtitle,
        ),
      ],
    );
  }

  List<(String, String, int)> _columnsFor(String layout) => switch (layout) {
    'hospitality' => const [
      ('date', '결 제 일', 2),
      ('customer', '이용 가맹점명', 3),
      ('place', '접 대 처', 3),
      ('attendees', '참 석 인 원', 4),
      ('amount', '금 액', 2),
    ],
    'purchase' => const [
      ('date', '날 짜', 2),
      ('item', '내 용', 3),
      ('quantity', '수 량', 2),
      ('amount', '금 액', 2),
      ('total', '합계금액', 2),
      ('remark', '비 고', 3),
    ],
    _ => const [
      ('date', '입 금 일', 2),
      ('item', '항 목', 3),
      ('purpose', '적 요', 6),
      ('amount', '금 액', 2),
    ],
  };

  String _totalAmount(List<Map<String, String>> items) {
    final sum = items.fold<int>(0, (total, item) {
      final raw = (item['total'] ?? item['amount'] ?? '').replaceAll(',', '');
      return total + (int.tryParse(raw) ?? 0);
    });
    return sum == 0 ? '-' : '${formatApprovalAmount(sum.toString())}원';
  }

  String _displayLineItemValue(String key, String value) {
    if (key == 'amount' || key == 'total') {
      return formatApprovalAmount(value);
    }
    return value;
  }
}

class _ReadOnlyContent extends StatelessWidget {
  const _ReadOnlyContent({required this.content, required this.minHeight});

  final String content;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight),
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(border: Border.all(color: TheWeColor.black900)),
    child: Text(
      content.isEmpty ? '-' : content,
      style: TheWeTextStyle.body.copyWith(fontSize: 16, height: 1.7),
    ),
  );
}

class _ReadOnlyWideRow extends StatelessWidget {
  const _ReadOnlyWideRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 110,
        child: _ReadOnlyTableCell(text: label, header: true),
      ),
      Expanded(child: _ReadOnlyTableCell(text: value)),
    ],
  );
}

class _ReadOnlyTableCell extends StatelessWidget {
  const _ReadOnlyTableCell({required this.text, this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 42),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
    decoration: BoxDecoration(
      color: header
          ? TheWeColor.black300.withValues(alpha: .14)
          : TheWeColor.white,
      border: Border.all(color: TheWeColor.black900, width: .6),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TheWeTextStyle.body.copyWith(
        fontSize: 14,
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}

class _DocumentAttachmentArea extends StatelessWidget {
  const _DocumentAttachmentArea({required this.files});

  final List<ApprovalAttachment> files;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: TheWeColor.surfaceAlt,
          border: Border.all(color: TheWeColor.black300.withValues(alpha: .4)),
        ),
        child: Text('첨부파일 ${files.length}개', style: TheWeTextStyle.subtitle),
      ),
      ...files.map((attachment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
              right: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
              bottom: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                color: TheWeColor.danger,
                size: 20,
              ),
              Text(attachment.name, style: TheWeTextStyle.body),
              Text(
                '(${_formatFileSize(attachment.sizeBytes)})',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
              OutlinedButton(
                onPressed: () => _showAttachmentPreview(context, attachment),
                child: const Text('미리보기'),
              ),
              OutlinedButton(
                onPressed: () => _downloadAttachment(context, attachment),
                child: const Text('다운로드'),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 12),
      TextField(
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '댓글을 남겨보세요.',
          prefixIcon: const Icon(Icons.account_circle_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)}KB';
  }
  return '${(kilobytes / 1024).toStringAsFixed(1)}MB';
}

Future<void> _showAttachmentPreview(
  BuildContext context,
  ApprovalAttachment attachment,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final compact = size.width < 520;
      return Dialog(
        insetPadding: EdgeInsets.all(compact ? 10 : 28),
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: compact ? size.width : 1000,
          height: compact ? size.height * .88 : size.height * .9,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 22,
                  12,
                  compact ? 8 : 14,
                  10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: TheWeColor.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TheWeTextStyle.subtitle,
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: TheWeColor.black300.withValues(alpha: .5),
              ),
              Expanded(
                child: ColoredBox(
                  color: TheWeColor.background,
                  child: PdfViewer.data(
                    attachment.bytes,
                    sourceName:
                        '${attachment.name}-${attachment.base64Data.hashCode}',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _downloadAttachment(
  BuildContext context,
  ApprovalAttachment attachment,
) async {
  final dotIndex = attachment.name.lastIndexOf('.');
  final hasExtension = dotIndex > 0 && dotIndex < attachment.name.length - 1;
  final name = hasExtension
      ? attachment.name.substring(0, dotIndex)
      : attachment.name;
  final extension = hasExtension
      ? attachment.name.substring(dotIndex + 1)
      : 'pdf';

  try {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: attachment.bytes,
      fileExtension: extension,
      mimeType: attachment.mimeType == 'application/pdf'
          ? MimeType.pdf
          : MimeType.custom,
      customMimeType: attachment.mimeType,
    );
    if (!context.mounted) {
      return;
    }
    showTheWeSnackBar(context, message: '${attachment.name} 파일을 저장했습니다.');
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    showTheWeSnackBar(
      context,
      message: '파일을 저장하지 못했습니다. 다시 시도해 주세요.',
      type: TheWeSnackBarType.error,
    );
  }
}

class _BasicInfoTable extends StatelessWidget {
  const _BasicInfoTable({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return _BorderTable(
      rows: [
        _TablePair(label: '문서번호', value: document.documentNo),
        _TablePair(label: '작 성 일', value: document.draftedAt),
        _TablePair(label: '작성부서', value: document.department),
        _TablePair(label: '작 성 자', value: document.drafter),
      ],
    );
  }
}

class _DocumentMetaTable extends StatelessWidget {
  const _DocumentMetaTable({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WideRow(label: '수    신', value: _join(document.receivers)),
        _WideRow(label: '참    조', value: _join(document.references)),
        _WideRow(label: '열 람 자', value: _join(document.viewers)),
        _WideRow(label: '협조부서', value: document.cooperationDepartment),
        _WideRow(label: '합    의', value: document.agreement),
        if (document.documentLayout == 'payroll')
          _WideRow(label: '제    목', value: document.title),
        if (document.linkedDocuments.isNotEmpty)
          _WideRow(label: '관련문서', value: _join(document.linkedDocuments)),
      ],
    );
  }

  String _join(List<String> values) => values.isEmpty ? '-' : values.join(', ');
}

class ApprovalStampTable extends StatelessWidget {
  const ApprovalStampTable({super.key, required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    final visibleSteps = steps.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 480
            ? 480.0
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 42,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: TheWeColor.black300.withValues(alpha: 0.18),
                border: Border.all(color: TheWeColor.black900, width: .6),
              ),
              child: Text(
                '결재 라인',
                style: TheWeTextStyle.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _VerticalCell(label: '결\n재'),
                      ...visibleSteps.map(
                        (step) => Expanded(child: _StampCell(step: step)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    final approved = step.status == '완료';
    final rejected = step.status == '반려';

    return Container(
      height: 126,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TheWeColor.black900),
          right: BorderSide(color: TheWeColor.black900),
          bottom: BorderSide(color: TheWeColor.black900),
        ),
      ),
      child: Column(
        children: [
          _StampText(step.role.isEmpty ? step.type : step.role),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (approved || rejected)
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rejected
                              ? TheWeColor.danger
                              : Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        rejected ? '반려' : '승인',
                        style: TheWeTextStyle.caption.copyWith(
                          color: rejected
                              ? TheWeColor.danger
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      step.name,
                      style: TheWeTextStyle.body.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _StampText(step.approvedAt ?? step.status),
        ],
      ),
    );
  }
}

class _StampText extends StatelessWidget {
  const _StampText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TheWeColor.black900)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.body.copyWith(fontSize: 14),
      ),
    );
  }
}

class _VerticalCell extends StatelessWidget {
  const _VerticalCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.18),
        border: Border.all(color: TheWeColor.black900),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BorderTable extends StatelessWidget {
  const _BorderTable({required this.rows});

  final List<_TablePair> rows;

  @override
  Widget build(BuildContext context) {
    return Column(children: rows.map((row) => _WideRow.fromPair(row)).toList());
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.label, required this.value});

  factory _WideRow.fromPair(_TablePair pair) {
    return _WideRow(label: pair.label, value: pair.value);
  }

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: TheWeColor.black900),
          right: BorderSide(color: TheWeColor.black900),
          bottom: BorderSide(color: TheWeColor.black900),
          top: BorderSide(color: TheWeColor.black900),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 82 : 124,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: TheWeColor.black300.withValues(alpha: 0.18),
              border: Border(right: BorderSide(color: TheWeColor.black900)),
            ),
            child: Text(
              label,
              style: TheWeTextStyle.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                value.isEmpty ? '-' : value,
                style: TheWeTextStyle.body.copyWith(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.18),
        border: Border.all(color: TheWeColor.black900, width: .6),
      ),
      child: Text(
        title,
        style: TheWeTextStyle.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TablePair {
  const _TablePair({required this.label, required this.value});

  final String label;
  final String value;
}
