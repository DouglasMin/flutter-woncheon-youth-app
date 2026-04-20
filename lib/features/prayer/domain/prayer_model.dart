import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_model.freezed.dart';
part 'prayer_model.g.dart';

@freezed
class PrayerItem with _$PrayerItem {
  const factory PrayerItem({
    required String prayerId,
    required String authorName,
    required bool isAnonymous,
    required String contentPreview,
    required String createdAt,
  }) = _PrayerItem;

  factory PrayerItem.fromJson(Map<String, dynamic> json) =>
      _$PrayerItemFromJson(json);
}

@freezed
class PrayerDetail with _$PrayerDetail {
  const factory PrayerDetail({
    required String prayerId,
    required String authorName,
    required bool isAnonymous,
    required String content,
    required String createdAt,
    required bool isMine,
    // 익명 게시물은 null. 실명 게시물의 차단 기능에 사용.
    String? authorMemberId,
  }) = _PrayerDetail;

  factory PrayerDetail.fromJson(Map<String, dynamic> json) =>
      _$PrayerDetailFromJson(json);
}

@freezed
class PrayerListResponse with _$PrayerListResponse {
  const factory PrayerListResponse({
    required List<PrayerItem> items,
    required bool hasMore,
    String? nextCursor,
  }) = _PrayerListResponse;

  factory PrayerListResponse.fromJson(Map<String, dynamic> json) =>
      _$PrayerListResponseFromJson(json);
}
