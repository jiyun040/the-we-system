import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_notice.dart';

class _NoticeTestController extends ApprovalDashboardController {
  _NoticeTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

EmployeeAccount _adminAccount({
  required String id,
  required bool canChangeAdminOtp,
}) => EmployeeAccount(
  id: id,
  password: '',
  name: '테스트 관리자',
  department: '테스트부서',
  position: '관리자',
  email: '',
  isAdmin: true,
  canChangeAdminOtp: canChangeAdminOtp,
);

void main() {
  testWidgets('OTP 관리자에게만 공지 관리 메뉴와 작성 화면을 표시한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final manager = _adminAccount(
      id: designatedAdminAccountId,
      canChangeAdminOtp: true,
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: manager,
      accounts: [manager],
      adminMode: true,
    );
    expect(state.canManageNotices, isTrue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _NoticeTestController(state),
          ),
        ],
        child: const MaterialApp(home: ApprovalAdminPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('근태 관리'), findsOneWidget);
    expect(find.text('공지 관리'), findsOneWidget);
    await tester.tap(find.text('공지 관리'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin-notice-create-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('admin-notice-create-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-notice-editor')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-notice-save-button')));
    await tester.pump();
    expect(find.text('공지 제목과 내용을 모두 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('슈퍼어드민에게는 공지 관리 메뉴를 표시하지 않는다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final superAdmin = _adminAccount(id: 'admin', canChangeAdminOtp: false);
    final state = signedOutApprovalState.copyWith(
      currentUser: superAdmin,
      adminMode: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _NoticeTestController(state),
          ),
        ],
        child: const MaterialApp(home: ApprovalAdminPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공지 관리'), findsNothing);
  });

  testWidgets('등록된 공지사항을 일반 홈 화면에 표시한다', (tester) async {
    const notice = PortalNotice(
      id: 'notice-test',
      title: '테스트 공지 제목',
      content: '테스트 공지 내용',
      authorName: '테스트 작성자',
      createdAt: '2026-09-01T10:00:00+09:00',
      updatedAt: '2026-09-01T10:00:00+09:00',
      isPinned: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ApprovalHomeNoticePanel(notices: [notice])),
      ),
    );

    expect(find.text('테스트 공지 제목'), findsOneWidget);
    expect(find.text('테스트 공지 내용'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
  });
}
