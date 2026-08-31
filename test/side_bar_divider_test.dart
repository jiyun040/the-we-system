import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/constants/color.dart';

void main() {
  testWidgets('모든 화면의 사이드바 구분선은 홈 색상을 사용한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [SizedBox(width: 320), SideBarDivider()]),
        ),
      ),
    );

    final divider = tester.widget<VerticalDivider>(
      find.byType(VerticalDivider),
    );

    expect(divider.width, 1);
    expect(divider.color, TheWeColor.black300.withValues(alpha: 0.32));
  });
}
