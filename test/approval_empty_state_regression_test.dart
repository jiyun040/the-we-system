import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_calendar_panel.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';

void main() {
  testWidgets('결재 양식이 없으면 선택 창 예외 대신 안내를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  showDraftFormSelectionDialog(context, templates: const []),
              child: const Text('새 결재 진행'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('새 결재 진행'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text('사용 가능한 결재 양식이 없습니다. 관리자 설정에서 양식을 먼저 등록해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('기안 항목선택'), findsNothing);
  });

  testWidgets('일정이 없어도 월간 캘린더를 표시한다', (tester) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 900, child: ApprovalHomeCalendarPanel()),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('approval-month-calendar')), findsOneWidget);
    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    expect(find.text('등록된 일정이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('선택한 날짜에 일정을 추가하고 목록에서 확인한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 900, child: ApprovalHomeCalendarPanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('일정 추가'));
    await tester.pumpAndSettle();

    expect(find.textContaining('일정 추가'), findsWidgets);
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.first, '월간 정기 회의');
    final addButton = find.widgetWithText(FilledButton, '추가');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('월간 정기 회의'), findsWidgets);
    expect(find.text('등록된 일정이 없습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
