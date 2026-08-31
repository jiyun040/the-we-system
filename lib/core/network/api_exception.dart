import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['error'];
      if (detail is Map<String, dynamic>) {
        return ApiException(
          detail['message']?.toString() ?? '서버 요청을 처리하지 못했습니다.',
          statusCode: error.response?.statusCode,
          code: detail['code']?.toString(),
        );
      }
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException('서버에 연결할 수 없습니다. 네트워크와 서버 상태를 확인해 주세요.');
    }
    return ApiException(
      error.message ?? '서버 요청을 처리하지 못했습니다.',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

String userFacingErrorMessage(
  Object error, {
  String fallback = '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  if (error is ApiException && error.message.trim().isNotEmpty) {
    return error.message.trim();
  }
  return fallback;
}
