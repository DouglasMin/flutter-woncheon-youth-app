import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice_model.freezed.dart';
part 'notice_model.g.dart';

@freezed
class NoticeItem with _$NoticeItem {
  const factory NoticeItem({
    required String noticeId,
    required String title,
    required String contentPreview,
    required bool pinned,
    required String publishedAt,
  }) = _NoticeItem;

  factory NoticeItem.fromJson(Map<String, dynamic> json) =>
      _$NoticeItemFromJson(json);
}

@freezed
class NoticeDetail with _$NoticeDetail {
  const factory NoticeDetail({
    required String noticeId,
    required String title,
    required String content,
    required bool pinned,
    required String publishedAt,
  }) = _NoticeDetail;

  factory NoticeDetail.fromJson(Map<String, dynamic> json) =>
      _$NoticeDetailFromJson(json);
}

@freezed
class NoticeListResponse with _$NoticeListResponse {
  const factory NoticeListResponse({
    required List<NoticeItem> items,
    required bool hasMore,
    String? nextCursor,
  }) = _NoticeListResponse;

  factory NoticeListResponse.fromJson(Map<String, dynamic> json) =>
      _$NoticeListResponseFromJson(json);
}
