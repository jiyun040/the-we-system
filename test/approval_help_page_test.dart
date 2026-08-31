import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/pages/settings/approval_help_page.dart';

void main() {
  testWidgets('도움말은 한 항목만 펼친다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ApprovalHelpPage()));

    const firstQuestion = '결재와 반려는 어떻게 다른가요?';
    const firstAnswer =
        '결재는 현재 단계의 승인 처리를 의미합니다. 반려는 기안자에게 문서를 되돌려 수정 후 재상신하도록 요청하는 처리입니다.';
    const secondQuestion = '결재 대기 문서는 어디에서 확인하나요?';
    const secondAnswer =
        '전자결재 홈의 결재 대기 문서 카드에서 확인합니다. 카드를 선택하면 문서 양식과 결재선을 함께 볼 수 있습니다.';

    expect(find.text(firstAnswer), findsNothing);
    expect(find.text(secondAnswer), findsNothing);

    await tester.tap(find.text(firstQuestion));
    await tester.pumpAndSettle();
    expect(find.text(firstAnswer), findsOneWidget);

    await tester.tap(find.text(secondQuestion));
    await tester.pumpAndSettle();
    expect(find.text(secondAnswer), findsOneWidget);
    expect(find.text(firstAnswer), findsNothing);
  });
}
