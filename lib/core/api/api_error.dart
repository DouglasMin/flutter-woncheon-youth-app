import 'package:dio/dio.dart';

/// Extracts user-friendly error message from a DioException response.
String getApiErrorMessage(DioException e, {String fallback = '오류가 발생했습니다.'}) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String?;
    if (message != null && message.isNotEmpty) return message;
  }
  return fallback;
}
