import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/features/approval/presentation/pages/attendance/approval_absence_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_box_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_detail_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_draft_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/settings/approval_help_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/settings/approval_settings_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/auth/approval_signup_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/leave/approval_leave_page.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_auth_gate.dart';

abstract final class AppRouteName {
  static const home = 'approvalHome';
  static const draft = 'approvalDraft';
  static const box = 'approvalBox';
  static const formBox = 'approvalFormBox';
  static const temporaryBox = 'approvalTemporaryBox';
  static const settings = 'approvalSettings';
  static const help = 'approvalHelp';
  static const absence = 'approvalAbsence';
  static const detail = 'approvalDetail';
  static const signup = 'approvalSignup';
  static const leave = 'approvalLeave';
  static const admin = 'approvalAdmin';
}

abstract final class AppRoutePath {
  static const home = '/';
  static const draft = '/approval/new';
  static const box = '/approval/box/:kind';
  static const formBox = '/approval/box/form/:formId';
  static const temporaryBox = '/approval/temporary';
  static const settings = '/approval/settings';
  static const help = '/approval/help';
  static const absence = '/approval/absence';
  static const detail = '/approval/:id';
  static const signup = '/signup';
  static const leave = '/leave';
  static const admin = '/admin';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      name: AppRouteName.signup,
      path: AppRoutePath.signup,
      pageBuilder: (context, state) =>
          _buildOverlayPage(state, const ApprovalSignupPage()),
    ),
    GoRoute(
      name: AppRouteName.home,
      path: AppRoutePath.home,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ApprovalAuthGate(child: ApprovalHomePage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.draft,
      path: AppRoutePath.draft,
      pageBuilder: (context, state) {
        return _buildOverlayPage(
          state,
          ApprovalAuthGate(
            child: ApprovalDraftPage(
              reuseDocumentId: state.uri.queryParameters['reuse'],
              selectedFormId: state.uri.queryParameters['form'],
            ),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.box,
      path: AppRoutePath.box,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: ApprovalAuthGate(
            child: ApprovalBoxPage(kind: state.pathParameters['kind'] ?? 'all'),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.formBox,
      path: AppRoutePath.formBox,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: ApprovalAuthGate(
            child: ApprovalBoxPage(
              kind: 'all',
              formId: state.pathParameters['formId'],
            ),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.temporaryBox,
      path: AppRoutePath.temporaryBox,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ApprovalAuthGate(child: ApprovalBoxPage(kind: 'temporary')),
      ),
    ),
    GoRoute(
      name: AppRouteName.settings,
      path: AppRoutePath.settings,
      pageBuilder: (context, state) => _buildOverlayPage(
        state,
        const ApprovalAuthGate(child: ApprovalSettingsPage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.help,
      path: AppRoutePath.help,
      pageBuilder: (context, state) => _buildOverlayPage(
        state,
        const ApprovalAuthGate(child: ApprovalHelpPage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.absence,
      path: AppRoutePath.absence,
      pageBuilder: (context, state) => NoTransitionPage(
        child: ApprovalAuthGate(child: ApprovalAbsencePage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.leave,
      path: AppRoutePath.leave,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ApprovalAuthGate(child: ApprovalLeavePage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.admin,
      path: AppRoutePath.admin,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ApprovalAuthGate(child: ApprovalAdminPage()),
      ),
    ),
    GoRoute(
      name: AppRouteName.detail,
      path: AppRoutePath.detail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';

        return _buildOverlayPage(
          state,
          ApprovalAuthGate(child: ApprovalDetailPage(documentId: id)),
        );
      },
    ),
  ],
);

CustomTransitionPage<void> _buildOverlayPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
