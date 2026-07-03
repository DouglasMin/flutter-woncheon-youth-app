import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';

class NoticeRepository {
  NoticeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<NoticeListResponse> listNotices({
    int limit = AppConstants.defaultPageSize,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.notices,
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return NoticeListResponse.fromJson(data);
  }

  Future<NoticeDetail> getNotice(String noticeId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.notice(noticeId),
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return NoticeDetail.fromJson(data);
  }
}
