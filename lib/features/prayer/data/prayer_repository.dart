import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/features/prayer/domain/comment_model.dart';
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

  // Comments
  Future<List<CommentItem>> getComments(String prayerId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.comments(prayerId),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentItem> createComment({
    required String prayerId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.comments(prayerId),
      data: {'content': content},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CommentItem.fromJson(data);
  }

  Future<void> updateComment({
    required String prayerId,
    required String commentId,
    required String content,
  }) async {
    await _apiClient.dio.put<Map<String, dynamic>>(
      Endpoints.comment(prayerId, commentId),
      data: {'content': content},
    );
  }

  Future<void> deleteComment({
    required String prayerId,
    required String commentId,
  }) async {
    await _apiClient.dio.delete<Map<String, dynamic>>(
      Endpoints.comment(prayerId, commentId),
    );
  }

  // Reactions
  Future<ReactionState> getReaction(String prayerId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.reaction(prayerId),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return ReactionState.fromJson(data);
  }

  Future<ReactionState> toggleReaction(String prayerId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.reaction(prayerId),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return ReactionState.fromJson(data);
  }
}
