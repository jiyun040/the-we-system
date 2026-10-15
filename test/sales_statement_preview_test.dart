import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/presentation/sales_statement_preview.dart';

void main() {
  testWidgets('mobile statement fits one page and supports pinch zoom', (
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
            height: 680,
            child: SalesStatementPreview(
              statement: const SalesStatement(projectName: '테스트 현장', items: []),
              issued: DateTime(2026, 10, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement preview uses template and shows supplied values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final statement = SalesStatement(
      projectName: '테스트 현장',
      items: [
        SalesLedgerEntry.fromJson({
          'contractor': '테스트 시공사',
          'partner': '테스트 협력사',
          'startDate': '2026-09-01',
          'endDate': '2026-09-30',
          'elevator': '1호기',
          'supplyAmount': 3000000,
          'installment': 1,
          'invoiceIssuer': '협력사',
        }),
      ],
    );
    await tester.runAsync(() async {
      final loader = FontLoader('SUIT-Variable')
        ..addFont(rootBundle.load('assets/fonts/SUIT-Medium.ttf'));
      await loader.load();
      File(
        '/tmp/statement-app-preview.pdf',
      ).writeAsBytesSync(await statementTemplatePdf(statement));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('preview'),
            child: SalesStatementPreview(
              statement: statement,
              issued: DateTime(2026, 10, 13),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트 협력사'), findsOneWidget);
    expect(find.text('테스트 현장'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '/tmp/statement-app-preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
