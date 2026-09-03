import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/the_we_date_picker.dart';

void main() {
  testWidgets('날짜 선택기의 월과 요일을 한국어로 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showTheWeDatePicker(
              context,
              initialDate: DateTime(2026, 9, 3),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              title: '날짜 선택',
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 9월'), findsOneWidget);
    expect(find.text('September 2026'), findsNothing);
    for (final weekday in const ['일', '월', '화', '수', '목', '금', '토']) {
      expect(find.text(weekday), findsWidgets);
    }
  });
}
