import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/core/network/auth_token_store.dart';
import 'package:the_we_system/features/approval/data/datasources/the_we_api_service.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/signup_employee_profile.dart';
import 'package:the_we_system/features/approval/presentation/pages/auth/approval_signup_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _RecordingApiService extends TheWeApiService {
  _RecordingApiService() : super(Dio(), AuthTokenStore());

  String? registeredPosition;

  @override
  Future<bool> hasStoredToken() async => false;

  @override
  Future<void> register({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
  }) async {
    registeredPosition = position;
    throw const ApiException('테스트 요청 종료');
  }
}

void main() {
  test('회원가입 구성원의 이름·부서·직책 조합을 고정한다', () {
    for (final expected in signupEmployeeProfiles) {
      final profile = signupProfileForName(expected.name);
      expect(profile, isNotNull);
      expect(profile!.department, expected.department);
      expect(profile.position, expected.position);
      expect(
        validateSignupEmployee(
          name: expected.name,
          department: expected.department,
          position: expected.position,
        ),
        isNull,
      );
    }
  });

  test('이름과 다른 부서·직책 조합을 거부한다', () {
    final profile = signupEmployeeProfiles.first;
    final another = signupEmployeeProfiles.firstWhere(
      (candidate) => candidate.department != profile.department,
    );
    expect(
      validateSignupEmployee(
        name: profile.name,
        department: another.department,
        position: another.position,
      ),
      '${profile.name}님의 부서는 ${profile.department}입니다.',
    );
  });

  testWidgets('부서와 이름에 따라 직책을 자동 입력한다', (tester) async {
    final sharedDepartment = signupEmployeeProfiles
        .map((profile) => profile.department)
        .firstWhere(
          (department) =>
              signupEmployeeProfiles
                  .where((profile) => profile.department == department)
                  .length >
              1,
        );
    final sharedProfiles = signupEmployeeProfiles
        .where((profile) => profile.department == sharedDepartment)
        .toList();
    final firstProfile = signupEmployeeProfiles.firstWhere(
      (profile) => profile.department != sharedDepartment,
    );
    final secondProfile = sharedProfiles.first;
    final thirdProfile = sharedProfiles.last;
    await tester.pumpWidget(const MaterialApp(home: ApprovalSignupPage()));

    await tester.enterText(
      find.byKey(const Key('signup-name-field')),
      firstProfile.name,
    );
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstProfile.department).last);
    await tester.pumpAndSettle();

    var positionField = tester.widget<CustomTextFormField>(
      find.byKey(const Key('signup-position-field')),
    );
    expect(positionField.controller.text, firstProfile.position);
    expect(positionField.readOnly, isTrue);

    await tester.enterText(
      find.byKey(const Key('signup-name-field')),
      secondProfile.name,
    );
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(secondProfile.department).last);
    await tester.pumpAndSettle();

    positionField = tester.widget<CustomTextFormField>(
      find.byKey(const Key('signup-position-field')),
    );
    expect(positionField.controller.text, secondProfile.position);

    await tester.enterText(
      find.byKey(const Key('signup-name-field')),
      thirdProfile.name,
    );
    await tester.pump();
    expect(positionField.controller.text, thirdProfile.position);
  });

  testWidgets('제출 시 자동 선택된 직책을 다시 계산해 서버로 전달한다', (tester) async {
    final profile = signupEmployeeProfiles.last;
    final api = _RecordingApiService();
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [theWeApiServiceProvider.overrideWithValue(api)],
        child: const MaterialApp(home: ApprovalSignupPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('signup-name-field')),
      profile.name,
    );
    await tester.enterText(
      find.byKey(const Key('signup-id-field')),
      'kim_account',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password-field')),
      'safe-password-1234',
    );
    await tester.enterText(
      find.byKey(const Key('signup-confirm-password-field')),
      'safe-password-1234',
    );
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(profile.department).last);
    await tester.pumpAndSettle();

    final positionField = tester.widget<CustomTextFormField>(
      find.byKey(const Key('signup-position-field')),
    );
    expect(positionField.controller.text, profile.position);

    // 브라우저 리빌드로 표시 컨트롤러가 비워지는 상황을 재현한다.
    positionField.controller.clear();
    await tester.tap(find.widgetWithText(FilledButton, '회원가입 완료'));
    await tester.pumpAndSettle();

    expect(api.registeredPosition, profile.position);
    expect(find.text('모든 항목을 입력해 주세요.'), findsNothing);
  });

  testWidgets('회원가입 입력 글자를 읽기 쉬운 크기로 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ApprovalSignupPage()));

    final fields = tester
        .widgetList<CustomTextFormField>(find.byType(CustomTextFormField))
        .toList();
    expect(fields, hasLength(5));
    for (final field in fields) {
      expect(field.style?.fontSize, 16);
    }
  });

  testWidgets('이름과 맞지 않는 부서로는 회원가입할 수 없다', (tester) async {
    final profile = signupEmployeeProfiles.first;
    final another = signupEmployeeProfiles.firstWhere(
      (candidate) => candidate.department != profile.department,
    );
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ApprovalSignupPage()));

    await tester.enterText(
      find.byKey(const Key('signup-name-field')),
      profile.name,
    );
    await tester.enterText(
      find.byKey(const Key('signup-id-field')),
      'research_lead',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password-field')),
      'safe-password',
    );
    await tester.enterText(
      find.byKey(const Key('signup-confirm-password-field')),
      'safe-password',
    );
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(another.department).last);
    await tester.pumpAndSettle();

    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '회원가입 완료'),
    );
    submitButton.onPressed?.call();
    await tester.pump();

    expect(
      find.text('${profile.name}님의 부서는 ${profile.department}입니다.'),
      findsOneWidget,
    );
  });
}
