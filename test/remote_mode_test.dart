import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/core/config/app_env.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/main.dart';

class _SignedOutController extends ApprovalDashboardController {
  @override
  Future<ApprovalDashboardState> build() async => signedOutApprovalState;
}

class _FailingController extends ApprovalDashboardController {
  @override
  Future<ApprovalDashboardState> build() async {
    throw const ApiException('테스트 서버 오류입니다.');
  }
}

void main() {
  test('기본 실행은 Django API 주소를 사용한다', () {
    expect(AppEnv.baseUrl, isNotEmpty);
    expect(AppEnv.baseUrl, endsWith('/api/v1'));
  });

  test('로그아웃 초기 상태에는 업무 데이터가 없다', () {
    expect(signedOutApprovalState.accounts, isEmpty);
    expect(signedOutApprovalState.formTemplates, isEmpty);
    expect(signedOutApprovalState.documents, isEmpty);
    expect(signedOutApprovalState.leaveRequests, isEmpty);
  });

  test('조직도에서 시스템 관리자와 빈 부서를 제외한다', () {
    final state = signedOutApprovalState.copyWith(
      accounts: const [
        EmployeeAccount(
          id: 'admin',
          password: '',
          name: '슈퍼어드민',
          department: '시스템관리',
          position: '시스템 관리자',
          email: '',
          isAdmin: true,
        ),
        EmployeeAccount(
          id: 'employee',
          password: '',
          name: '직원',
          department: '운영팀',
          position: '사원',
          email: '',
        ),
        EmployeeAccount(
          id: 'unassigned',
          password: '',
          name: '미배정',
          department: '',
          position: '사원',
          email: '',
        ),
      ],
      selectedOrgDepartment: '운영팀',
    );

    expect(state.departments, ['운영팀']);
    expect(state.selectedDepartmentMembers.map((account) => account.id), [
      'employee',
    ]);
  });

  testWidgets('로그인 화면은 계정 정보를 자동 입력하지 않는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields, hasLength(2));
    for (final field in fields) {
      expect(field.controller?.text ?? '', isEmpty);
    }
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('로그인 입력 필드는 브라우저 계정 자동완성을 지원한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(fields.first.autofillHints, const [AutofillHints.username]);
    expect(fields.last.autofillHints, const [AutofillHints.password]);
  });

  testWidgets('로그인 입력 글자를 읽기 쉽게 표시하고 Enter 동작을 제공한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    final idField = fields[0];
    final passwordField = fields[1];

    expect(idField.style.fontSize, 16);
    expect(passwordField.style.fontSize, 16);
    expect(idField.textInputAction, TextInputAction.next);
    expect(passwordField.textInputAction, TextInputAction.done);
    expect(passwordField.onSubmitted, isNotNull);

    idField.onSubmitted?.call('employee');
    await tester.pump();
    expect(passwordField.focusNode.hasFocus, isTrue);
  });

  testWidgets('로그인 예외 메시지를 눈에 띄게 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    expect(find.byKey(const Key('login-error-message')), findsOneWidget);
    expect(find.text('아이디와 비밀번호를 모두 입력해 주세요.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('초기 서버 오류의 실제 메시지와 재시도 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _FailingController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('서버에 연결할 수 없습니다.'), findsOneWidget);
    expect(find.text('테스트 서버 오류입니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('백그라운드 작업 오류를 전역 알림으로 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyApp)),
    );
    container
        .read(approvalOperationErrorProvider.notifier)
        .show(const ApiException('변경사항 저장에 실패했습니다.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('변경사항 저장에 실패했습니다.'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
