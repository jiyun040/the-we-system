import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_step.dart';

class ApprovalDocumentSheet extends StatelessWidget {
  const ApprovalDocumentSheet({super.key, required this.document});

  final ApprovalDocument document;

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
            _sheetTitle(document.form),
            textAlign: TextAlign.center,
            style: TheWeTextStyle.pageTitle.copyWith(
              fontSize: 30,
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
                    child: _BasicInfoTable(document: document),
                  ),
                  SizedBox(width: narrow ? 0 : 20, height: narrow ? 16 : 0),
                  Expanded(
                    flex: narrow ? 0 : 6,
                    child: _ApprovalStampTable(steps: document.steps),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _DocumentMetaTable(document: document),
          _SectionHeader(title: '상 세 내 용'),
          Container(
            constraints: const BoxConstraints(minHeight: 340),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
            decoration: BoxDecoration(
              border: Border.all(color: TheWeColor.black900),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(1),
              ),
            ),
            child: Text(
              document.content,
              style: TheWeTextStyle.body.copyWith(height: 1.8),
            ),
          ),
        ],
      ),
    );
  }

  String _sheetTitle(String form) {
    if (form.contains('협조')) {
      return '업 무 협 조';
    }
    if (form.contains('휴가')) {
      return '휴 가 신 청';
    }
    return '업 무 기 안';
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
        _TablePair(label: '기 안 자', value: document.drafter),
        _TablePair(label: '소    속', value: document.department),
        _TablePair(label: '기 안 일', value: document.draftedAt),
        _TablePair(label: '시행일자', value: document.effectiveDate),
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
        _WideRow(label: '제    목', value: document.title),
        if (document.linkedDocuments.isNotEmpty)
          _WideRow(label: '관련문서', value: _join(document.linkedDocuments)),
      ],
    );
  }

  String _join(List<String> values) => values.isEmpty ? '-' : values.join(', ');
}

class _ApprovalStampTable extends StatelessWidget {
  const _ApprovalStampTable({required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    final visibleSteps = steps.take(4).toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerticalCell(label: '결\n재'),
          ...visibleSteps.map(
            (step) => Expanded(child: _StampCell(step: step)),
          ),
        ],
      ),
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    final approved = step.status == '완료' || step.status == '진행중';

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
                  if (approved)
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: Text(
                        '승인',
                        style: TheWeTextStyle.caption.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(step.name, style: TheWeTextStyle.caption),
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
        style: TheWeTextStyle.caption,
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
        style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
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
            width: 124,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: TheWeColor.black300.withValues(alpha: 0.18),
              border: Border(right: BorderSide(color: TheWeColor.black900)),
            ),
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                value.isEmpty ? '-' : value,
                style: TheWeTextStyle.body,
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
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.18),
        border: Border(
          left: BorderSide(color: TheWeColor.black900),
          right: BorderSide(color: TheWeColor.black900),
          bottom: BorderSide(color: TheWeColor.black900),
        ),
      ),
      child: Text(
        title,
        style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TablePair {
  const _TablePair({required this.label, required this.value});

  final String label;
  final String value;
}
