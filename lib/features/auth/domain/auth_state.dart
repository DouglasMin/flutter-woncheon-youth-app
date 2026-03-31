import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String accessToken,
    required String refreshToken,
    required bool isFirstLogin,
    required MemberInfo member,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class MemberInfo with _$MemberInfo {
  const factory MemberInfo({
    required String memberId,
    required String name,
  }) = _MemberInfo;

  factory MemberInfo.fromJson(Map<String, dynamic> json) =>
      _$MemberInfoFromJson(json);
}
