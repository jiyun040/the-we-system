import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/data/sales_api_service.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/core/network/api_exception.dart';

void main() {
  SalesLedgerEntry entry(String issuer) => SalesLedgerEntry.fromJson({
    'id': 'issuer-test',
    'contractor': '코오롱 글로벌',
    'partner': '삼창건설',
    'startDate': '2026-06-12',
    'invoiceIssuer': issuer,
  });
  test(
    'issuer matches company names regardless of spacing and explicit roles',
    () {
      expect(entry('코오롱글로벌').invoiceIssuerType, '시공사');
      expect(entry('시공사').invoiceIssuerType, '시공사');
      expect(entry('삼창 건설').invoiceIssuerType, '협력사');
      expect(entry('협력사').invoiceIssuerType, '협력사');
      expect(entry('').invoiceIssuerType, '협력사');
      expect(entry('').toEditableJson()['invoiceIssuer'], '협력사');
      expect(entry('다른회사').invoiceIssuerType, '');
    },
  );
  test('API sends issuer and preserves returned value', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data['invoiceIssuer'], '시공사');
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                ...options.data,
                'id': 'issuer-test',
                'contractor': '코오롱 글로벌',
              },
            ),
          );
        },
      ),
    );
    final saved = await SalesApiService(dio).updateEntry(entry('시공사'));
    expect(saved.invoiceIssuer, '시공사');
    expect(saved.invoiceIssuerType, '시공사');
  });
  test('older server dropping issuer is reported as save failure', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {'id': 'issuer-test', 'startDate': '2026-06-12'},
            ),
          );
        },
      ),
    );
    await expectLater(
      SalesApiService(dio).updateEntry(entry('시공사')),
      throwsA(isA<ApiException>()),
    );
  });
}
