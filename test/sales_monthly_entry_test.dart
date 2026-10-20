import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/data/sales_api_service.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_order.dart';
import 'package:the_we_system/features/sales/domain/sales_statement_notes.dart';

void main() {
  test('월별 사용일을 저장해도 조회 월과 계약 원본 기간을 유지한다', () async {
    final entry = SalesLedgerEntry.fromJson({
      'id': '1',
      'month': '2026-10',
      'projectName': '장기 현장',
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'contractStartDate': '2026-08-10',
      'contractEndDate': '2026-12-15',
      'invoiceIssuer': '협력사',
      'adjustmentAmount': 0,
      'adjustmentReason': '',
    });
    final changed = entry.copyWith(supplyAmount: 3000000);
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data['month'], '2026-10');
          expect(options.data['startDate'], '2026-10-01');
          expect(options.data['endDate'], '2026-10-31');
          expect(changed.contractStartDate, DateTime(2026, 8, 10));
          expect(changed.contractEndDate, DateTime(2026, 12, 15));
          handler.resolve(
            Response(requestOptions: options, data: options.data),
          );
        },
      ),
    );
    expect(
      (await SalesApiService(dio).updateEntry(changed)).supplyAmount,
      3000000,
    );
  });

  test('월별 시작일이 같아져도 기존 호기의 계약 시작 순서를 유지한다', () {
    SalesLedgerEntry entry(String elevator, String contractStart) =>
        SalesLedgerEntry.fromJson({
          'projectName': '동일 현장',
          'elevator': elevator,
          'status': '진행',
          'startDate': '2026-10-01',
          'contractStartDate': contractStart,
        });
    final rows = [entry('1호기', '2026-09-10'), entry('2호기', '2026-08-01')]
      ..sort(compareSalesLedgerEntries);
    expect(rows.first.elevator, '2호기');
  });

  test('2월 전체 월 사용은 월 미만 안내 대상이 아니다', () {
    final fullMonth = SalesLedgerEntry.fromJson({
      'month': '2027-02',
      'startDate': '2027-02-01',
      'endDate': '2027-02-28',
    });
    expect(statementItemNote(fullMonth), '');
    expect(statementFooterNotes([fullMonth]), isEmpty);
    expect(
      statementItemNote(fullMonth.copyWith(startDate: DateTime(2027, 2, 10))),
      '19일',
    );
  });
}
