/// SemVer 비교 — "1.0.5" 형식의 marketing version 문자열을 비교.
/// `+build` 부분은 무시 (CFBundleVersion / Play versionCode는 별도 메커니즘).
///
/// 반환값:
/// - 양수: a > b (a가 더 최신)
/// - 0: 동일
/// - 음수: a < b
int compareSemver(String a, String b) {
  final aParts = _normalize(a);
  final bParts = _normalize(b);
  final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < maxLen; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av - bv;
  }
  return 0;
}

/// "1.0.5+6" → [1, 0, 5]   ('+' 이후 build 제거, 숫자 아닌 토큰 제외)
List<int> _normalize(String version) {
  final beforePlus = version.split('+').first;
  return beforePlus
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList(growable: false);
}

/// remote가 local보다 엄격히 높으면 true.
bool isUpdateAvailable({
  required String localVersion,
  required String remoteVersion,
}) {
  return compareSemver(remoteVersion, localVersion) > 0;
}
