import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_page.dart';

class _ComprehensiveTestController extends ApprovalDashboardController {
  _ComprehensiveTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

const _documents = [
  ApprovalDocument(
    id: 'APR-001',
    documentNo: '지원-2026-001',
    title: '사무용 노트북 구매',
    drafter: '김직원',
    department: '기술부',
    form: '구매 요청서',
    status: '결재대기',
    draftedAt: '2026-09-09 09:10',
    dueDate: '2026-09-12',
    progress: 50,
    steps: [
      ApprovalStep(name: '이팀장', department: '기술부', role: '팀장', status: '진행중'),
    ],
  ),
  ApprovalDocument(
    id: 'APR-002',
    documentNo: '회계-2026-002',
    title: '8월 법인카드 정산',
    drafter: '박회계',
    department: '경리부',
    form: '지출 결의서',
    status: '완료',
    draftedAt: '2026-09-08 11:20',
    dueDate: '2026-09-10',
    progress: 100,
  ),
];

EmployeeAccount _account(String id) => EmployeeAccount(
  id: id,
  password: '',
  name: id == 'admin' ? '슈퍼어드민' : '지정 관리자',
  department: '경리부',
  position: '대리',
  isAdmin: true,
  canChangeAdminOtp: true,
);

void main() {
  test('종합관리 권한은 관리자 모드의 슈퍼어드민에게만 부여한다', () {
    final superAdminState = signedOutApprovalState.copyWith(
      currentUser: _account('admin'),
      adminMode: true,
    );
    final designatedAdminState = signedOutApprovalState.copyWith(
      currentUser: _account(designatedAdminAccountId),
      adminMode: true,
    );

    expect(superAdminState.canAccessComprehensiveManagement, isTrue);
    expect(designatedAdminState.canAccessComprehensiveManagement, isFalse);
  });

  testWidgets('슈퍼어드민은 종합관리에서 전체 결재를 검색한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final state = signedOutApprovalState.copyWith(
      currentUser: _account('admin'),
      adminMode: true,
      documents: _documents,
      restrictedDocumentIds: const {'APR-001'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _ComprehensiveTestController(state),
          ),
        ],
        child: const MaterialApp(home: ApprovalAdminPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('종합관리'), findsOneWidget);
    await tester.tap(find.text('종합관리'));
    await tester.pumpAndSettle();

    expect(find.text('결재 종합관리'), findsOneWidget);
    expect(find.text('전체 문서'), findsOneWidget);
    expect(find.text('2건'), findsNWidgets(2));
    expect(find.text('사무용 노트북 구매'), findsOneWidget);
    expect(find.text('8월 법인카드 정산'), findsOneWidget);
    expect(find.text('김직원'), findsOneWidget);
    expect(find.text('이팀장'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('comprehensive-search')),
      '박회계',
    );
    await tester.pump();

    expect(find.text('사무용 노트북 구매'), findsNothing);
    expect(find.text('8월 법인카드 정산'), findsOneWidget);
  });

  testWidgets('지정 관리자에게 종합관리 메뉴를 노출하지 않는다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final state = signedOutApprovalState.copyWith(
      currentUser: _account(designatedAdminAccountId),
      adminMode: true,
      documents: _documents,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _ComprehensiveTestController(state),
          ),
        ],
        child: const MaterialApp(home: ApprovalAdminPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('종합관리'), findsNothing);
    expect(find.text('결재 문서 관리'), findsOneWidget);
  });

  test('슈퍼어드민은 제한 문서도 상세 조회 대상으로 가져온다', () async {
    final state = signedOutApprovalState.copyWith(
      currentUser: _account('admin'),
      adminMode: true,
      documents: _documents,
      restrictedDocumentIds: const {'APR-001'},
    );
    final container = ProviderContainer(
      overrides: [
        approvalDashboardControllerProvider.overrideWith(
          () => _ComprehensiveTestController(state),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(approvalDashboardControllerProvider.future);

    expect(container.read(approvalDocumentProvider('APR-001'))?.id, 'APR-001');
  });
}
