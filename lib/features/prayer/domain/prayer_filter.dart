enum PrayerFilterPreset {
  all('전체'),
  newPosts('새 글'),
  thisWeek('이번 주'),
  oneMonth('1개월'),
  threeMonths('3개월'),
  custom('직접 선택');

  const PrayerFilterPreset(this.label);
  final String label;
}

class PrayerFilter {
  const PrayerFilter({
    this.preset = PrayerFilterPreset.all,
    this.customStart,
    this.customEnd,
  });

  final PrayerFilterPreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  DateTime? get startDate {
    final now = DateTime.now();
    switch (preset) {
      case PrayerFilterPreset.all:
        return null;
      case PrayerFilterPreset.newPosts:
        return now.subtract(const Duration(hours: 24));
      case PrayerFilterPreset.thisWeek:
        final weekday = now.weekday; // Mon=1, Sun=7
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
      case PrayerFilterPreset.oneMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case PrayerFilterPreset.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case PrayerFilterPreset.custom:
        return customStart;
    }
  }

  DateTime? get endDate {
    if (preset == PrayerFilterPreset.custom) return customEnd;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerFilter &&
          preset == other.preset &&
          customStart == other.customStart &&
          customEnd == other.customEnd;

  @override
  int get hashCode => Object.hash(preset, customStart, customEnd);
}
