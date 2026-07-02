import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';

class ApprovalBoxPage extends ConsumerWidget {
  const ApprovalBoxPage({super.key, required this.kind, this.formId});

  final String kind;
  final String? formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: state.when(
          data: (value) {
            final documents = _documentsForKind(value);
            final visibleDocuments = formId == null
                ? documents
                : documents
                      .where((document) => _matchesForm(document, formId!))
                      .toList();

            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TheWeBackButton(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TheWeTextStyle.pageTitle,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          if (formId != null) {
                            context.goNamed(
                              AppRouteName.draft,
                              queryParameters: {'form': formId!},
                            );
                            return;
                          }

                          final selected = await showDraftFormSelectionDialog(
                            context,
                            templates: value.formTemplates,
                          );
                          if (selected == null || !context.mounted) {
                            return;
                          }

                          context.goNamed(
                            AppRouteName.draft,
                            queryParameters: {'form': selected.id},
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('새 결재 진행'),
                        style: FilledButton.styleFrom(
                          backgroundColor: TheWeColor.black900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ArchiveTabs(selected: kind),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _DocumentTable(
                      kind: kind,
                      documents: visibleDocuments,
                    ),
                  ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => Center(
            child: Text('문서함을 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: TheWeColor.blue300),
          ),
        ),
      ),
    );
  }

  String get _title {
    if (formId != null) {
      return '${_formTitle(formId!)} 결재 내역';
    }

    return switch (kind) {
      'sent' => '내가 보낸 결재',
      'waiting' => '결재 대기 문서',
      'received' => '내가 받은 결재',
      'reference' => '참조/열람 대기',
      'scheduled' => '결재 예정 문서',
      'drafts' => '공용 기안 문서함',
      'temporary' => '임시저장함',
      _ => '전체 결재 내역',
    };
  }

  String _formTitle(String id) {
    return switch (id) {
      'team-vacation' => '팀 휴가',
      'expense-slip' => '지출 결의서',
      'purchase-request' => '구매 요청서',
      _ => '양식별',
    };
  }

  bool _matchesForm(ApprovalDocument document, String id) {
    return switch (id) {
      'team-vacation' => document.form.contains('휴가'),
      'expense-slip' => document.form.contains('지출'),
      'purchase-request' => document.form.contains('구매'),
      _ => document.form == id,
    };
  }

  List<ApprovalDocument> _documentsForKind(ApprovalDashboardState state) {
    return switch (kind) {
      'sent' => state.dashboard.processingDocuments,
      'waiting' => state.dashboard.waitingDocuments,
      'received' => state.dashboard.waitingDocuments,
      'reference' => state.referenceDocuments,
      'scheduled' => state.scheduledDocuments,
      'drafts' => state.sharedDraftDocuments,
      'temporary' =>
        state.authoredDocuments
            .where(
              (document) =>
                  document.status == '작성중' ||
                  document.status == '임시저장' ||
                  document.documentNo == '임시저장',
            )
            .toList()
          ..sort((a, b) => b.draftedAt.compareTo(a.draftedAt)),
      _ => state.visibleDocuments,
    };
  }
}

class _ArchiveTabs extends StatelessWidget {
  const _ArchiveTabs({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _TabButton(label: '받은 결재', routeKind: 'received', selected: selected),
        _TabButton(label: '보낸 결재', routeKind: 'sent', selected: selected),
        _TabButton(label: '기안 문서함', routeKind: 'drafts', selected: selected),
        _TabButton(label: '임시저장함', routeKind: 'temporary', selected: selected),
        _TabButton(label: '전체 내역', routeKind: 'all', selected: selected),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.routeKind,
    required this.selected,
  });

  final String label;
  final String routeKind;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == routeKind;

    return isSelected
        ? FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
            child: Text(label, style: TheWeTextStyle.section),
          )
        : OutlinedButton(
            onPressed: () => routeKind == 'temporary'
                ? context.goNamed(AppRouteName.temporaryBox)
                : context.goNamed(
                    AppRouteName.box,
                    pathParameters: {'kind': routeKind},
                  ),
            child: Text(label, style: TheWeTextStyle.section),
          );
  }
}

class _DocumentTable extends ConsumerWidget {
  const _DocumentTable({required this.kind, required this.documents});

  final String kind;
  final List<ApprovalDocument> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref
        .watch(approvalDashboardControllerProvider)
        .asData
        ?.value;
    final currentUser = appState?.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 1380 ? 1380 : constraints.maxWidth,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: TheWeColor.black300.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: TheWeColor.black300.withValues(alpha: 0.08),
                    child: Row(
                      children: const [
                        _HeaderCell('기안일', flex: 2),
                        _HeaderCell('완료일', flex: 2),
                        _HeaderCell('결재양식', flex: 3),
                        _HeaderCell('긴급', flex: 1),
                        _HeaderCell('제목', flex: 5),
                        _HeaderCell('첨부', flex: 1),
                        _HeaderCell('기안부서', flex: 2),
                        _HeaderCell('문서번호', flex: 2),
                        _HeaderCell('결재상태', flex: 2),
                        _HeaderCell('관리', flex: 3),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: documents.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: TheWeColor.black300.withValues(alpha: 0.22),
                      ),
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        final canCancel =
                            currentUser != null &&
                            _canCancelDocument(document) &&
                            (currentUser.isAdmin ||
                                document.drafter == currentUser.name);

                        return InkWell(
                          onTap: () => context.goNamed(
                            AppRouteName.detail,
                            pathParameters: {'id': document.id},
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _BodyCell(document.draftedAt, flex: 2),
                                _BodyCell(_completedAt(document), flex: 2),
                                _BodyCell(document.form, flex: 3),
                                _BodyCell(
                                  document.urgent ? '긴급' : '-',
                                  flex: 1,
                                ),
                                _BodyCell(document.title, flex: 5),
                                _BodyCell(
                                  document.linkedDocuments.isEmpty
                                      ? '-'
                                      : '${document.linkedDocuments.length}',
                                  flex: 1,
                                ),
                                _BodyCell(document.department, flex: 2),
                                _BodyCell(document.documentNo, flex: 2),
                                _StatusCell(document.status, flex: 2),
                                Expanded(
                                  flex: 3,
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (kind == 'drafts' && canCancel)
                                        OutlinedButton(
                                          onPressed: () => ref
                                              .read(
                                                approvalDashboardControllerProvider
                                                    .notifier,
                                              )
                                              .cancelSubmission(document.id),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: TheWeColor.pink,
                                            ),
                                          ),
                                          child: Text(
                                            '상신취소',
                                            style: TheWeTextStyle.section
                                                .copyWith(
                                                  color: TheWeColor.pink,
                                                ),
                                          ),
                                        ),
                                      OutlinedButton(
                                        onPressed: () => context.goNamed(
                                          AppRouteName.draft,
                                          queryParameters: {
                                            'reuse': document.id,
                                          },
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: TheWeColor.blue300,
                                          ),
                                        ),
                                        child: Text(
                                          document.status == '작성중'
                                              ? '이어쓰기'
                                              : '재사용',
                                          style: TheWeTextStyle.section
                                              .copyWith(
                                                color: TheWeColor.blue300,
                                              ),
                                        ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _completedAt(ApprovalDocument document) {
    if (document.status != '완료') {
      return '-';
    }

    return document.steps
            .where((step) => step.status == '완료')
            .lastOrNull
            ?.approvedAt
            ?.split(' ')
            .first ??
        document.effectiveDate;
  }

  bool _canCancelDocument(ApprovalDocument document) {
    if (!document.canCancel) {
      return false;
    }

    return !document.steps.skip(1).any((step) => step.status == '완료');
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.body,
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final color = switch (text) {
      '완료' => TheWeColor.green,
      '반려' => TheWeColor.pink,
      '작성중' => TheWeColor.black500,
      _ => TheWeColor.blue300,
    };

    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TheWeTextStyle.caption.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
