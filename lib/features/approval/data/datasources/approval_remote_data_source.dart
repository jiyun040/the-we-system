import 'package:dio/dio.dart';
import 'package:the_we_system/features/approval/domain/entities/dashboard/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

class ApprovalRemoteDataSource {
  ApprovalRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ApprovalDashboard> fetchDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/approvals/dashboard',
    );
    return ApprovalDashboard.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<ApprovalDocument> fetchDocument(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/approvals/documents/$id',
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> approveDocument(String id) async {
    await _dio.post<void>(
      '/approvals/$id/approve',
      data: const <String, dynamic>{},
    );
  }
}
