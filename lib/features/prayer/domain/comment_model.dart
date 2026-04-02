import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentItem with _$CommentItem {
  const factory CommentItem({
    required String commentId,
    required String authorName,
    required String content,
    required String createdAt,
    required String memberId,
  }) = _CommentItem;

  factory CommentItem.fromJson(Map<String, dynamic> json) =>
      _$CommentItemFromJson(json);
}

@freezed
class ReactionState with _$ReactionState {
  const factory ReactionState({
    required bool reacted,
    required int count,
  }) = _ReactionState;

  factory ReactionState.fromJson(Map<String, dynamic> json) =>
      _$ReactionStateFromJson(json);
}
