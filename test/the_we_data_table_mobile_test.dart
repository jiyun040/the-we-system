import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';

void main() {
  testWidgets('cells with different text heights fill the same table row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: TheWeDataTable(
              headers: const ['시공사', '협력사'],
              minWidth: 600,
              rows: const [
                [Text('짧은 이름'), Text('긴 이름\n두 번째 줄\n세 번째 줄')],
              ],
              cellColors: const [
                [Colors.blue, Colors.green],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final blue = find.byWidgetPredicate(
      (widget) => widget is Material && widget.color == Colors.blue,
    );
    final green = find.byWidgetPredicate(
      (widget) => widget is Material && widget.color == Colors.green,
    );
    expect(tester.getTopLeft(blue).dy, tester.getTopLeft(green).dy);
    expect(tester.getSize(blue).height, tester.getSize(green).height);
    expect(tester.takeException(), isNull);
  });
}
