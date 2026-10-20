import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/data/sales_api_service.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

void main() {
  test('같은 달을 다시 조회하면 갱신된 서버 건수를 사용한다', () async {
    var requests = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'items': requests == 1
                    ? [
                        {'id': 'old', 'projectName': '종료일 수정 전 현장'},
                      ]
                    : <Map<String, dynamic>>[],
                'summary': {'unbilledCount': requests == 1 ? 1 : 0},
              },
            ),
          );
        },
      ),
    );
    final api = SalesApiService(dio);
    final month = DateTime(2026, 10);
    expect((await api.fetchLedger(month: month)).items, hasLength(1));
    final updated = await api.fetchLedger(month: month);
    expect(updated.items, isEmpty);
    expect(updated.summary.unbilledCount, 0);
    expect(requests, 2);
  });

  test('상단 집계는 현재 표에 보이는 행만 계산한다', () {
    final visible = [
      SalesLedgerEntry.fromJson({
        'id': '1',
        'supplyAmount': 100000,
        'billingDate': '2026-10-10',
      }),
      SalesLedgerEntry.fromJson({'id': '2', 'supplyAmount': 200000}),
    ];
    final summary = SalesLedgerSummary.fromEntries(visible);
    expect(summary.supplyAmount, 300000);
    expect(summary.billCount, 1);
    expect(summary.unbilledCount, 1);
    expect(summary.unissuedInvoiceCount, 1);
    expect(summary.unpaidAmount, 100000);
  });
}
