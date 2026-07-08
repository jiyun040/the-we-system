import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/processing_card.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/layout.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_empty_state.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_mobile_document_card.dart';

part 'approval_home_overview.dart';
part 'approval_home_calendar_panel.dart';
part 'approval_home_notice.dart';
part 'approval_home_calendar_models.dart';
part 'approval_home_calendar_day.dart';
part 'approval_home_calendar_dialog.dart';
part 'approval_home_trend.dart';
part 'approval_home_processing.dart';

class ApprovalHomePage extends ConsumerStatefulWidget {
  const ApprovalHomePage({super.key});

  @override
  ConsumerState<ApprovalHomePage> createState() => _ApprovalHomePageState();
}

class _ApprovalHomePageState extends ConsumerState<ApprovalHomePage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController waitingScrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    waitingScrollController.dispose();
    super.dispose();
  }

  void _scrollWaitingDocuments(double delta) {
    if (!waitingScrollController.hasClients) {
      return;
    }

    final target = (waitingScrollController.offset + delta).clamp(
      0.0,
      waitingScrollController.position.maxScrollExtent,
    );

    waitingScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 0)
          : null,
      body: state.when(
        data: (approvalState) {
          final dashboard = approvalState.dashboard;
          final keyword = approvalState.keyword.trim();
          final waitingDocuments = _filterDocuments(
            dashboard.waitingDocuments,
            keyword,
          );

          final isPhone = MediaQuery.sizeOf(context).width < 520;

          final content = Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                color: TheWeColor.blue300,
                onRefresh: () => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .refresh(),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 24,
                        isPhone ? 18 : 28,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _Header(
                          userName: approvalState.currentUser?.name ?? '사용자',
                          controller: searchController,
                          onChanged: ref
                              .read(
                                approvalDashboardControllerProvider.notifier,
                              )
                              .updateKeyword,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 24,
                        isPhone ? 18 : 28,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _PortalOverview(state: approvalState),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 28,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _ProcessingSection(
                          title: '결재 대기 문서',
                          documents: waitingDocuments,
                          controller: waitingScrollController,
                          onScrollLeft: () => _scrollWaitingDocuments(-300),
                          onScrollRight: () => _scrollWaitingDocuments(300),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 28,
                        isPhone ? 18 : 28,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _DraftProgressSection(
                          documents: dashboard.processingDocuments
                              .take(10)
                              .toList(),
                          totalCount: dashboard.processingDocuments.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          if (isPhone) {
            return Row(children: [content]);
          }

          return Row(
            children: [
              SideBar(
                frequentForms: dashboard.frequentForms,
                pendingDocument: dashboard.pendingCount,
                receiveDocument: dashboard.receivedCount,
                openPendingDocument: dashboard.referenceCount,
                scheduledDocument: dashboard.scheduledCount,
              ),
              VerticalDivider(
                width: 1,
                color: TheWeColor.black300.withValues(alpha: 0.32),
              ),
              content,
            ],
          );
        },
        error: (error, stackTrace) => _LoadFailed(
          onRetry: () =>
              ref.read(approvalDashboardControllerProvider.notifier).refresh(),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: TheWeColor.blue300)),
      ),
    );
  }

  List<ApprovalDocument> _filterDocuments(
    List<ApprovalDocument> documents,
    String keyword,
  ) {
    if (keyword.isEmpty) {
      return documents;
    }

    return documents.where((document) {
      return document.title.contains(keyword) ||
          document.drafter.contains(keyword) ||
          document.form.contains(keyword) ||
          document.department.contains(keyword);
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.controller,
    required this.onChanged,
  });

  final String userName;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Row(
                children: [
                  Text('홈', style: TheWeTextStyle.pageTitle),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TheWeColor.blue100.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$userName님',
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.blue300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: controller,
                      height: 42,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: '문서명, 기안자, 양식 검색',
                        prefixIcon: Icon(
                          Icons.search,
                          color: TheWeColor.black500,
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconAction(
                    icon: Icons.settings_outlined,
                    message: '설정',
                    onPressed: () => context.pushNamed(AppRouteName.settings),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.help_outline,
                    message: '도움말',
                    onPressed: () => context.pushNamed(AppRouteName.help),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
