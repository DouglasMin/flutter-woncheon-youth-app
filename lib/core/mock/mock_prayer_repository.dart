import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';

class MockPrayerRepository {
  final List<_MockPrayer> _prayers = [
    _MockPrayer(
      id: 'prayer-001',
      memberId: 'mock-member-001',
      authorName: '익명',
      isAnonymous: true,
      content: '취업 준비 중인데 주님의 인도하심을 구합니다. 하나님의 뜻대로 좋은 곳에서 일할 수 있기를 기도합니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _MockPrayer(
      id: 'prayer-002',
      memberId: 'member-other',
      authorName: '김철수',
      isAnonymous: false,
      content: '가족의 건강을 위해 기도 부탁드립니다. 어머니께서 최근 건강이 안 좋으셔서 걱정이 됩니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _MockPrayer(
      id: 'prayer-003',
      memberId: 'member-other2',
      authorName: '이영희',
      isAnonymous: false,
      content: '대학원 논문 마감이 다가오고 있습니다. 지혜와 집중력을 주시길 기도합니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    _MockPrayer(
      id: 'prayer-004',
      memberId: 'mock-member-001',
      authorName: 'test',
      isAnonymous: false,
      content: '이번 주 청년부 예배를 위해 기도합니다. 은혜로운 시간이 되기를.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    _MockPrayer(
      id: 'prayer-005',
      memberId: 'member-other3',
      authorName: '익명',
      isAnonymous: true,
      content: '마음의 평안을 위해 기도 부탁드려요.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<PrayerListResponse> listPrayers({
    int limit = 10,
    String? cursor,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    var filtered = _prayers.toList();

    if (startDate != null) {
      filtered = filtered.where((p) => !p.createdAt.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((p) => !p.createdAt.isAfter(endOfDay)).toList();
    }

    return PrayerListResponse(
      items: filtered.map((p) {
        final preview = p.content.length > 200
            ? '${p.content.substring(0, 200)}...'
            : p.content;
        return PrayerItem(
          prayerId: p.id,
          authorName: p.authorName,
          isAnonymous: p.isAnonymous,
          contentPreview: preview,
          createdAt: p.createdAt.toIso8601String(),
        );
      }).toList(),
      hasMore: false,
    );
  }

  Future<PrayerDetail> getPrayer(String prayerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final prayer = _prayers.firstWhere(
      (p) => p.id == prayerId,
      orElse: () => throw Exception('Not found'),
    );

    return PrayerDetail(
      prayerId: prayer.id,
      authorName: prayer.authorName,
      isAnonymous: prayer.isAnonymous,
      content: prayer.content,
      createdAt: prayer.createdAt.toIso8601String(),
      isMine: prayer.memberId == 'mock-member-001',
    );
  }

  Future<void> createPrayer({
    required String content,
    required bool isAnonymous,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _prayers.insert(
      0,
      _MockPrayer(
        id: 'prayer-${DateTime.now().millisecondsSinceEpoch}',
        memberId: 'mock-member-001',
        authorName: isAnonymous ? '익명' : 'test',
        isAnonymous: isAnonymous,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deletePrayer(String prayerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _prayers.removeWhere((p) => p.id == prayerId);
  }
}

class _MockPrayer {
  _MockPrayer({
    required this.id,
    required this.memberId,
    required this.authorName,
    required this.isAnonymous,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String memberId;
  final String authorName;
  final bool isAnonymous;
  final String content;
  final DateTime createdAt;
}
