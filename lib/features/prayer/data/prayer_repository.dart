import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';

class PrayerRepository {
  PrayerRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PrayerListResponse> listPrayers({
    int limit = 20,
    String? cursor,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.prayers,
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return PrayerListResponse.fromJson(data);
  }

  Future<PrayerDetail> getPrayer(String prayerId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.prayer(prayerId),
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return PrayerDetail.fromJson(data);
  }

  Future<void> createPrayer({
    required String content,
    required bool isAnonymous,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.prayers,
      data: {'content': content, 'isAnonymous': isAnonymous},
    );
  }

  Future<void> deletePrayer(String prayerId) async {
    await _apiClient.dio.delete<Map<String, dynamic>>(
      Endpoints.prayer(prayerId),
    );
  }
}
