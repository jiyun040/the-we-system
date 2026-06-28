import 'package:go_router/go_router.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_absence_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_box_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_detail_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_draft_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_help_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_home_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval_settings_page.dart';

abstract final class AppRouteName {
  static const home = 'approvalHome';
  static const draft = 'approvalDraft';
  static const box = 'approvalBox';
  static const formBox = 'approvalFormBox';
  static const settings = 'approvalSettings';
  static const help = 'approvalHelp';
  static const absence = 'approvalAbsence';
  static const detail = 'approvalDetail';
}

abstract final class AppRoutePath {
  static const home = '/';
  static const draft = '/approval/new';
  static const box = '/approval/box/:kind';
  static const formBox = '/approval/box/form/:formId';
  static const settings = '/approval/settings';
  static const help = '/approval/help';
  static const absence = '/approval/absence';
  static const detail = '/approval/:id';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      name: AppRouteName.home,
      path: AppRoutePath.home,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ApprovalHomePage()),
    ),
    GoRoute(
      name: AppRouteName.draft,
      path: AppRoutePath.draft,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: ApprovalDraftPage(
            reuseDocumentId: state.uri.queryParameters['reuse'],
          ),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.box,
      path: AppRoutePath.box,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: ApprovalBoxPage(kind: state.pathParameters['kind'] ?? 'all'),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.formBox,
      path: AppRoutePath.formBox,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: ApprovalBoxPage(
            kind: 'all',
            formId: state.pathParameters['formId'],
          ),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.settings,
      path: AppRoutePath.settings,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ApprovalSettingsPage()),
    ),
    GoRoute(
      name: AppRouteName.help,
      path: AppRoutePath.help,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ApprovalHelpPage()),
    ),
    GoRoute(
      name: AppRouteName.absence,
      path: AppRoutePath.absence,
      pageBuilder: (context, state) =>
          NoTransitionPage(child: ApprovalAbsencePage()),
    ),
    GoRoute(
      name: AppRouteName.detail,
      path: AppRoutePath.detail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';

        return NoTransitionPage(child: ApprovalDetailPage(documentId: id));
      },
    ),
  ],
);
