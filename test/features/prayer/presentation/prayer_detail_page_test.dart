import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';
import 'package:woncheon_youth/features/prayer/data/prayer_repository.dart';
import 'package:woncheon_youth/features/prayer/domain/comment_model.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_detail_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

void main() {
  testWidgets('comments section shows a compact loading state', (tester) async {
    final comments = Completer<List<CommentItem>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            _FakeSecureStorageService(),
          ),
          commentsProvider('PRAYER01').overrideWith((ref) async {
            return comments.future;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: buildPrayerCommentsSectionForTest('PRAYER01'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('댓글 0'), findsOneWidget);
    expect(find.text('불러오는 중'), findsOneWidget);
  });

  testWidgets('reaction ignores duplicate taps while request is pending', (
    tester,
  ) async {
    final repo = _FakePrayerRepository(toggleDelay: const Duration(seconds: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prayerRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(body: buildPrayerReactionRowForTest('P1')),
        ),
      ),
    );

    await tester.tap(find.byType(PrayButton));
    await tester.tap(find.byType(PrayButton));

    expect(repo.toggleReactionCalls, 1);

    await tester.pump(const Duration(seconds: 1));
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  @override
  Future<String?> getMemberId() async => 'MEMBER01';
}

class _FakePrayerRepository extends PrayerRepository {
  _FakePrayerRepository({this.toggleDelay = Duration.zero})
    : super(ApiClient.forTest());

  final Duration toggleDelay;
  int toggleReactionCalls = 0;

  @override
  Future<ReactionState> getReaction(String prayerId) async {
    return const ReactionState(reacted: false, count: 0);
  }

  @override
  Future<ReactionState> toggleReaction(String prayerId) async {
    toggleReactionCalls += 1;
    await Future<void>.delayed(toggleDelay);
    return const ReactionState(reacted: true, count: 1);
  }
}
