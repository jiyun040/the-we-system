import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_empty_state.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_mobile_document_card.dart';

part 'approval_box_mobile.dart';
part 'approval_box_table_cells.dart';

class ApprovalBoxPage extends ConsumerWidget {
  const ApprovalBoxPage({super.key, required this.kind, this.formId});

  final String kind;
  final String? formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 1)
          : null,
      body: SafeArea(
        child: state.when(
          data: (value) {
            final isPhone = MediaQuery.sizeOf(context).width < 520;
            final documents = _documentsForKind(value);
            final visibleDocuments = formId == null
                ? documents
                : documents
                      .where((document) => _matchesForm(document, formId!))
                      .toList();

            return Padding(
              padding: EdgeInsets.all(isPhone ? 18 : 28),
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
                          style:
                              (isPhone
                                      ? TheWeTextStyle.title
                                      : TheWeTextStyle.pageTitle)
                                  .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          if (formId != null) {
                            context.pushNamed(
                              AppRouteName.draft,
                              queryParameters: {'form': formId!},
                            );
                            return;
                          }

                          final selected = await showDraftFormSelectionDialog(
                            context,
                            templates: value.activeFormTemplates,
                          );
                          if (selected == null || !context.mounted) {
                            return;
                          }

                          context.pushNamed(
                            AppRouteName.draft,
                            queryParameters: {'form': selected.id},
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(isPhone ? '새 결재' : '새 결재 진행'),
                        style: FilledButton.styleFrom(
                          backgroundColor: TheWeColor.black900,
                          padding: EdgeInsets.symmetric(
                            horizontal: isPhone ? 12 : 16,
                            vertical: isPhone ? 12 : 14,
                          ),
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
      'department' => '부서 문서함',
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
      'received' => state.receivedDocuments,
      'reference' => state.referenceDocuments,
      'scheduled' => state.scheduledDocuments,
      'drafts' => state.sharedDraftDocuments,
      'department' => state.departmentDocuments,
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
    final returnKind = GoRouterState.of(
      context,
    ).uri.queryParameters['returnKind'];

    return Wrap(
      spacing: 8,
      children: [
        _TabButton(
          label: '부서 문서함',
          routeKind: 'department',
          selected: selected,
          returnKind: returnKind,
        ),
        _TabButton(
          label: '받은 결재',
          routeKind: 'received',
          selected: selected,
          returnKind: returnKind,
        ),
        _TabButton(
          label: '보낸 결재',
          routeKind: 'sent',
          selected: selected,
          returnKind: returnKind,
        ),
        _TabButton(
          label: '기안 문서함',
          routeKind: 'drafts',
          selected: selected,
          returnKind: returnKind,
        ),
        _TabButton(
          label: '임시저장함',
          routeKind: 'temporary',
          selected: selected,
          returnKind: returnKind,
        ),
        _TabButton(
          label: '전체 내역',
          routeKind: 'all',
          selected: selected,
          returnKind: returnKind,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.routeKind,
    required this.selected,
    required this.returnKind,
  });

  final String label;
  final String routeKind;
  final String selected;
  final String? returnKind;

  static const _tabKinds = {
    'received',
    'sent',
    'drafts',
    'department',
    'temporary',
    'all',
  };

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == routeKind;
    final canReturnFromAll =
        routeKind == 'all' &&
        isSelected &&
        returnKind != null &&
        !_tabKinds.contains(returnKind);

    return isSelected
        ? FilledButton(
            onPressed: canReturnFromAll
                ? () => context.goNamed(
                    AppRouteName.box,
                    pathParameters: {'kind': returnKind!},
                  )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: TheWeColor.blue300,
              disabledBackgroundColor: TheWeColor.blue300,
              disabledForegroundColor: TheWeColor.black900,
            ),
            child: Text(label, style: TheWeTextStyle.section),
          )
        : OutlinedButton(
            onPressed: () {
              if (routeKind == 'temporary') {
                context.goNamed(AppRouteName.temporaryBox);
                return;
              }

              if (routeKind == 'all' && !_tabKinds.contains(selected)) {
                context.goNamed(
                  AppRouteName.box,
                  pathParameters: {'kind': routeKind},
                  queryParameters: {'returnKind': selected},
                );
                return;
              }

              context.goNamed(
                AppRouteName.box,
                pathParameters: {'kind': routeKind},
              );
            },
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
        if (constraints.maxWidth < 640) {
          return _DocumentMobileList(
            kind: kind,
            documents: documents,
            canCancelForCurrentUser: (document) =>
                currentUser != null &&
                _canCancelDocument(document) &&
                (appState?.isAdminMode == true ||
                    document.drafter == currentUser.name),
            onCancel: (id) => ref
                .read(approvalDashboardControllerProvider.notifier)
                .cancelSubmission(id),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: TheWeDataTable(
            headers: const [
              '기안일',
              '완료일',
              '결재양식',
              '긴급',
              '제목',
              '첨부',
              '기안부서',
              '문서번호',
              '결재상태',
              '관리',
            ],
            columnFlexes: const [2, 2, 3, 1, 5, 1, 2, 2, 2, 3],
            minWidth: 1380,
            onRowTaps: documents
                .map<VoidCallback?>(
                  (document) =>
                      () => context.pushNamed(
                        AppRouteName.detail,
                        pathParameters: {'id': document.id},
                      ),
                )
                .toList(),
            rows: documents.map((document) {
              final canCancel =
                  currentUser != null &&
                  _canCancelDocument(document) &&
                  (appState?.isAdminMode == true ||
                      document.drafter == currentUser.name);
              return <Widget>[
                _DocumentTableText(document.draftedAt),
                _DocumentTableText(_completedAt(document)),
                _DocumentTableText(document.form),
                document.urgent
                    ? const _UrgentChip()
                    : const _DocumentTableText('-'),
                _DocumentTableText(
                  document.title.trim().isEmpty ? '-' : document.title,
                ),
                _DocumentTableText(
                  document.linkedDocuments.isEmpty
                      ? '-'
                      : '${document.linkedDocuments.length}',
                ),
                _DocumentTableText(document.department),
                _DocumentTableText(document.documentNo),
                _DocumentStatusChip(document.status),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (kind == 'drafts' && canCancel)
                      OutlinedButton(
                        onPressed: () => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .cancelSubmission(document.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TheWeColor.pink,
                          side: BorderSide(color: TheWeColor.pink),
                        ),
                        child: const Text('상신취소'),
                      ),
                    OutlinedButton(
                      onPressed: () => context.pushNamed(
                        AppRouteName.draft,
                        queryParameters: {'reuse': document.id},
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TheWeColor.blue300,
                        side: BorderSide(color: TheWeColor.blue300),
                      ),
                      child: Text(document.status == '작성중' ? '이어쓰기' : '재사용'),
                    ),
                  ],
                ),
              ];
            }).toList(),
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

extension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
