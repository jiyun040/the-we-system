import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/features/approval/presentation/models/signup_employee_profile.dart';
import 'package:the_we_system/features/approval/presentation/pages/auth/approval_signup_page.dart';

void main() {
  test('회원가입 구성원의 이름·부서·직책 조합을 고정한다', () {
    const expected = {
      '조상훈': ('대표이사', '대표'),
      '조세훈': ('기술부', '전무'),
      '김현정': ('공무', '대리'),
      '김효민': ('경리부', '대리'),
      '정효정': ('관리부', '이사'),
      '송형숙': ('관리부', '부장'),
      '조용덕': ('연구소', '부장'),
    };

    for (final entry in expected.entries) {
      final profile = signupProfileForName(entry.key);
      expect(profile, isNotNull);
      expect(profile!.department, entry.value.$1);
      expect(profile.position, entry.value.$2);
      expect(
        validateSignupEmployee(
          name: entry.key,
          department: entry.value.$1,
          position: entry.value.$2,
        ),
        isNull,
      );
    }
  });

  test('이름과 다른 부서·직책 조합을 거부한다', () {
    expect(
      validateSignupEmployee(name: '조용덕', department: '대표이사', position: '대표'),
      '조용덕님의 부서는 연구소입니다.',
    );
    expect(
      validateSignupEmployee(name: '정효정', department: '관리부', position: '부장'),
      '정효정님의 직책은 이사입니다.',
    );
  });

  testWidgets('부서와 이름에 따라 직책을 자동 입력한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ApprovalSignupPage()));

    await tester.enterText(find.byKey(const Key('signup-name-field')), '조용덕');
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연구소').last);
    await tester.pumpAndSettle();

    var positionField = tester.widget<CustomTextFormField>(
      find.byKey(const Key('signup-position-field')),
    );
    expect(positionField.controller.text, '부장');
    expect(positionField.readOnly, isTrue);

    await tester.enterText(find.byKey(const Key('signup-name-field')), '정효정');
    await tester.tap(find.byKey(const Key('signup-department-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관리부').last);
    await tester.pumpAndSettle();

    positionField = tester.widget<CustomTextFormField>(
      find.byKey(const Key('signup-position-field')),
    );
    expect(positionField.controller.text, '이사');

    await tester.enterText(find.byKey(const Key('signup-name-field')), '송형숙');
    await tester.pump();
    expect(positionField.controller.text, '부장');
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
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ApprovalSignupPage()));

    await tester.enterText(find.byKey(const Key('signup-name-field')), '조용덕');
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
    await tester.tap(find.text('대표이사').last);
    await tester.pumpAndSettle();

    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '회원가입 완료'),
    );
    submitButton.onPressed?.call();
    await tester.pump();

    expect(find.text('조용덕님의 부서는 연구소입니다.'), findsOneWidget);
  });
}
