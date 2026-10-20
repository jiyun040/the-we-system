import 'package:dio/dio.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

class SalesLedgerResponse {
  const SalesLedgerResponse({required this.items, required this.summary});
  final List<SalesLedgerEntry> items;
  final SalesLedgerSummary summary;
}

class SalesApiService {
  const SalesApiService(this._dio);
  final Dio _dio;

  Future<SalesLedgerResponse> fetchLedger({
    required DateTime month,
    String query = '',
    String status = '',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales/ledger',
        queryParameters: {
          'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
          if (query.trim().isNotEmpty) 'q': query.trim(),
          if (status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final result = SalesLedgerResponse(
        items: rawItems
            .whereType<Map>()
            .where(
              (item) =>
                  item['isDel'] != true &&
                  item['isDel']?.toString().toLowerCase() != 'true',
            )
            .map(
              (item) =>
                  SalesLedgerEntry.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        summary: SalesLedgerSummary.fromJson(
          Map<String, dynamic>.from(data['summary'] as Map? ?? const {}),
        ),
      );
      return result;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SalesLedgerEntry> updateEntry(SalesLedgerEntry entry) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/sales/ledger/${entry.id}',
        data: entry.toEditableJson(),
      );
      final saved = SalesLedgerEntry.fromJson(response.data ?? const {});
      if (response.data?['invoiceIssuer']?.toString().trim() !=
          entry.toEditableJson()['invoiceIssuer']) {
        throw const ApiException(
          '계산서 발행처가 서버에 저장되지 않았습니다. 서버 업데이트 적용 여부를 확인해 주세요.',
        );
      }
      if (response.data?['adjustmentAmount'] == null ||
          response.data?['adjustmentReason'] == null ||
          saved.adjustmentAmount != entry.adjustmentAmount ||
          saved.adjustmentReason != entry.adjustmentReason) {
        throw const ApiException(
          '조정액과 조정사항이 서버에 저장되지 않았습니다. 서버 업데이트 적용 여부를 확인해 주세요.',
        );
      }
      return saved;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SalesStatement> fetchStatement(
    String projectName,
    DateTime month,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales/statements',
        queryParameters: {
          'projectName': projectName,
          'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      return SalesStatement(
        projectName: data['projectName']?.toString() ?? projectName,
        items: rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  SalesLedgerEntry.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
