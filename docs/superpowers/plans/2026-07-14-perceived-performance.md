# Perceived Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app feel faster to real users without adding product features or broad rewrites.

**Architecture:** Optimize the screens users wait on most by preserving useful UI while backend work continues, reducing avoidable duplicate requests, and tuning backend request overhead. Keep each change surgical and independently verifiable.

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, Serverless Framework, API Gateway Lambda authorizer, AWS Lambda, DynamoDB, PostgreSQL.

---

## Scope Guard

Do not redesign the app, introduce a new caching package, add offline mode, add new product behavior, or rewrite data models unless a task explicitly calls for it. The order below is based on user-visible performance, not theoretical backend purity.

Current dirty working tree note: at the time this plan was written, notice routing and app-update lifecycle changes were already uncommitted. Execution should either commit those first or use a fresh worktree.

## File Map

- `lib/features/prayer/presentation/prayer_detail_page.dart`  
  Prayer detail layout, reaction row, comment input/list. Primary target for perceived detail speed and interaction responsiveness.
- `lib/features/prayer/presentation/prayer_providers.dart`  
  Prayer list/detail/comment/reaction Riverpod providers. Target for pagination refresh behavior and reaction pending state.
- `test/features/prayer/presentation/prayer_detail_page_test.dart`  
  Add widget tests for loading behavior and interaction guards.
- `test/features/prayer/presentation/prayer_providers_test.dart`  
  Add provider tests for refresh/load-more behavior where practical.
- `lib/features/attendance/presentation/attendance_check_page.dart`  
  Attendance tab screen composition. Target for making core attendance content feel primary.
- `lib/features/attendance/presentation/attendance_providers.dart`  
  Weekly attendance and group-prayer provider behavior.
- `test/features/attendance/presentation/attendance_check_page_test.dart`  
  Add widget/provider tests for attendance core rendering while secondary content loads.
- `lib/main.dart`  
  Startup non-critical work timing.
- `lib/core/api/api_client.dart`  
  Dio token handling and request retry behavior.
- `woncheon-backend/serverless.yml`  
  API Gateway authorizer TTL.
- `woncheon-backend/src/functions/notice/list.ts`  
  Notice list query behavior.
- `woncheon-admin/src/app/api/admin/notices/route.ts`  
  Notice write path if published-key optimization is chosen later.
- `woncheon-backend/src/functions/prayer/list.ts`  
  Prayer list server-side filtering and later scale work.

---

### Task 1: Prayer Detail Opens Faster

**User-visible goal:** Tapping a prayer card should show the main prayer content as soon as the detail request returns; comments/reaction loading must not make the screen feel blank or broken.

**Files:**
- Modify: `lib/features/prayer/presentation/prayer_detail_page.dart`
- Test: `test/features/prayer/presentation/prayer_detail_page_test.dart`

- [ ] **Step 1: Add a narrow test seam for the private comments widget**

In `lib/features/prayer/presentation/prayer_detail_page.dart`, add `foundation.dart` if not already imported:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
```

Add this helper near `_CommentsSection`:

```dart
@visibleForTesting
Widget buildPrayerCommentsSectionForTest(String prayerId) {
  return _CommentsSection(prayerId: prayerId);
}
```

- [ ] **Step 2: Write a widget test for comments loading visibility**

Create `test/features/prayer/presentation/prayer_detail_page_test.dart` if it does not exist. Use provider overrides for `commentsProvider` and assert the comments section shows a compact loading affordance instead of disappearing.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';

void main() {
  testWidgets('comments section shows a compact loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentsProvider('PRAYER01').overrideWith((ref) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return const [];
          }),
        ],
        child: const MaterialApp(
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
}
```

- [ ] **Step 3: Run test and confirm it fails**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_detail_page_test.dart
```

Expected: FAIL because comments loading currently renders `SizedBox.shrink()`.

- [ ] **Step 4: Replace invisible comments loading with compact loading**

In `lib/features/prayer/presentation/prayer_detail_page.dart`, change the comments loading branch:

```dart
commentsAsync.when(
  loading: () => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: WCLoadingView(compact: true, label: '불러오는 중'),
  ),
  error: (_, __) => Text(
    '댓글을 불러올 수 없습니다.',
    style: TextStyle(color: wc.textTer, fontSize: 13),
  ),
  data: (comments) {
    // existing data branch
  },
)
```

- [ ] **Step 5: Verify task**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_detail_page_test.dart
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/prayer/presentation/prayer_detail_page.dart test/features/prayer/presentation/prayer_detail_page_test.dart
git commit -m "perf: show prayer detail secondary loading states"
```

---

### Task 2: Attendance Tab Initial Load Feels Faster

**User-visible goal:** The attendance tab should prioritize core attendance/group content. "목장 기도제목" should be clearly secondary and must not make the initial tab feel blocked.

**Files:**
- Modify: `lib/features/attendance/presentation/attendance_check_page.dart`
- Modify: `lib/features/attendance/presentation/attendance_providers.dart`
- Test: `test/features/attendance/presentation/attendance_check_page_test.dart`

- [ ] **Step 1: Write a test for independent group-prayer loading**

Create `test/features/attendance/presentation/attendance_check_page_test.dart` and verify the attendance header/body can render while the group-prayer section is still loading.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_check_page.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';

void main() {
  testWidgets('attendance core renders before group prayers finish', (tester) async {
    final weekly = WeeklyAttendance(
      isLeader: false,
      group: const GroupInfo(id: 1, name: '테스트'),
      date: '2026-07-12',
      today: const TodayStatus(
        isPresent: false,
        hasRecord: false,
        markedBy: null,
        markedAt: null,
      ),
      history: const [],
      stats: const MyStats(totalWeeks: 12, presentWeeks: 7, rate: 58.3),
      members: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyAttendanceProvider.overrideWith((ref) async => weekly),
          groupPrayersProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return const [];
          }),
        ],
        child: const MaterialApp(home: AttendanceCheckPage()),
      ),
    );

    await tester.pump();
    expect(find.text('테스트 목장'), findsOneWidget);
    expect(find.text('목장 기도제목'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test and confirm current behavior**

Run:

```bash
flutter test test/features/attendance/presentation/attendance_check_page_test.dart
```

Expected: PASS if current architecture already separates weekly attendance from group prayers. If it fails because constructors differ, fix the test setup to match the actual model constructors before changing production code.

- [ ] **Step 3: Only if the test proves blocking, split secondary loading**

If group prayers block core rendering, move the group-prayer watch into the smallest widget that renders only that sliver:

```dart
class _GroupPrayers extends ConsumerWidget {
  const _GroupPrayers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(groupPrayersProvider);
    return prayersAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: WCLoadingView(compact: true, label: '기도제목을 불러오는 중'),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: WCStateView(
          icon: FluentIcons.error_circle_24_regular,
          title: '기도제목을 불러올 수 없습니다',
        ),
      ),
      data: (items) => _GroupPrayerList(items: items),
    );
  }
}
```

- [ ] **Step 4: Verify task**

Run:

```bash
flutter test test/features/attendance/presentation/attendance_check_page_test.dart
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/attendance/presentation/attendance_check_page.dart lib/features/attendance/presentation/attendance_providers.dart test/features/attendance/presentation/attendance_check_page_test.dart
git commit -m "perf: keep attendance core independent from group prayers"
```

---

### Task 3: Startup And Splash-To-Home Flow

**User-visible goal:** App entry should not wait on non-critical startup work. Routing and required update checks may run; push/device-token work should not block the first usable screen.

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/splash/presentation/splash_page.dart`
- Test: `test/features/splash/splash_startup_test.dart`

- [ ] **Step 1: Write a startup behavior test**

Create `test/features/splash/splash_startup_test.dart` to assert non-critical work is not awaited before navigation. Use fakes for storage and push services if existing providers allow it. If provider setup is too heavy, test the extracted startup decision function from Step 3.

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup route decision only depends on token and first-login state', () async {
    final route = decideStartupRoute(
      hasAccessToken: true,
      isFirstLogin: false,
    );

    expect(route, '/home');
  });
}
```

- [ ] **Step 2: Run test and confirm it fails**

Run:

```bash
flutter test test/features/splash/splash_startup_test.dart
```

Expected: FAIL until `decideStartupRoute` exists, or PASS if equivalent logic already exists.

- [ ] **Step 3: Extract route decision only if needed**

In `lib/features/splash/presentation/splash_page.dart`, add a tiny pure helper near the bottom:

```dart
@visibleForTesting
String decideStartupRoute({
  required bool hasAccessToken,
  required bool isFirstLogin,
}) {
  if (!hasAccessToken) return AppRoutes.login;
  return isFirstLogin ? AppRoutes.changePassword : AppRoutes.home;
}
```

Then replace the final route branch:

```dart
context.go(
  decideStartupRoute(
    hasAccessToken: token != null,
    isFirstLogin: isFirstLogin,
  ),
);
```

- [ ] **Step 4: Confirm non-critical calls are unawaited**

In `lib/main.dart`, keep push permission and notification registration non-blocking:

```dart
unawaited(pushService.requestPermission());
```

In `lib/features/splash/presentation/splash_page.dart`, keep device token registration non-blocking:

```dart
if (!isFirstLogin) {
  unawaited(registerDeviceTokenAfterAuth(ref));
}
```

- [ ] **Step 5: Verify task**

Run:

```bash
flutter test test/features/splash/splash_startup_test.dart
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

Expected: tests and debug builds pass.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/features/splash/presentation/splash_page.dart test/features/splash/splash_startup_test.dart
git commit -m "perf: keep startup routing focused on critical checks"
```

---

### Task 4: Authenticated Request Overhead

**User-visible goal:** Authenticated screens should feel less randomly slow by reducing repeated authorizer and token-read overhead.

**Files:**
- Modify: `woncheon-backend/serverless.yml`
- Modify: `lib/core/api/api_client.dart`
- Test: `test/core/api/api_client_test.dart`

- [ ] **Step 1: Write an ApiClient token-read test**

Create `test/core/api/api_client_test.dart`. Because `SecureStorageService` wraps a concrete `FlutterSecureStorage`, add only narrow `@visibleForTesting` helpers to `ApiClient`; do not introduce a new storage abstraction.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/api/api_client.dart';

void main() {
  test('ApiClient does not read secure storage for every request when token is cached', () async {
    final client = ApiClient.forTest();

    await client.setAccessTokenForTest('ACCESS');
    final first = await client.authorizationHeaderForTest();
    final second = await client.authorizationHeaderForTest();

    expect(first, 'Bearer ACCESS');
    expect(second, 'Bearer ACCESS');
  });
}
```

Add the minimum test seam in `ApiClient`:

```dart
@visibleForTesting
ApiClient.forTest() : _storage = SecureStorageService(const FlutterSecureStorage()) {
  _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
  _dio.interceptors.add(_TokenRefreshInterceptor(_storage, _dio));
}

@visibleForTesting
Future<void> setAccessTokenForTest(String token) async {
  final interceptor = _dio.interceptors.whereType<_TokenRefreshInterceptor>().single;
  interceptor.cachedAccessTokenForTest = token;
}

@visibleForTesting
Future<String?> authorizationHeaderForTest() async {
  final options = RequestOptions(path: '/test');
  final interceptor = _dio.interceptors.whereType<_TokenRefreshInterceptor>().single;
  return interceptor.authorizationHeaderForTest(options);
}
```

- [ ] **Step 2: Run test and confirm it fails**

Run:

```bash
flutter test test/core/api/api_client_test.dart
```

Expected: FAIL until token caching/test seams exist.

- [ ] **Step 3: Add minimal token cache**

In `lib/core/api/api_client.dart`, keep a private cached token in the interceptor:

```dart
class _TokenRefreshInterceptor extends QueuedInterceptor {
  _TokenRefreshInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  final Dio _dio;
  String? _cachedAccessToken;

  @visibleForTesting
  set cachedAccessTokenForTest(String? token) => _cachedAccessToken = token;

  @visibleForTesting
  Future<String?> authorizationHeaderForTest(RequestOptions options) async {
    final token = _cachedAccessToken ?? await _storage.getAccessToken();
    _cachedAccessToken = token;
    return token == null ? null : 'Bearer $token';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _cachedAccessToken ?? await _storage.getAccessToken();
    _cachedAccessToken = token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

After refresh succeeds, update `_cachedAccessToken`:

```dart
final accessToken = data['accessToken'] as String;
await _storage.saveTokens(
  accessToken: accessToken,
  refreshToken: data['refreshToken'] as String,
);
_cachedAccessToken = accessToken;
```

When refresh fails and storage is cleared, also clear `_cachedAccessToken`.

- [ ] **Step 4: Add short API Gateway authorizer TTL**

In `woncheon-backend/serverless.yml`, change authenticated routes from:

```yaml
resultTtlInSeconds: 0
```

to:

```yaml
resultTtlInSeconds: 60
```

Do not change auth endpoints where no authorizer exists. Use `60` first; it is enough to reduce repeated authorizer Lambda invocations while keeping auth-state changes reasonably fresh.

- [ ] **Step 5: Verify task**

Run:

```bash
flutter test test/core/api/api_client_test.dart
flutter test
cd woncheon-backend && pnpm sls package --stage dev
```

Expected: Flutter tests pass and Serverless package succeeds.

- [ ] **Step 6: Commit**

```bash
git add lib/core/api/api_client.dart test/core/api/api_client_test.dart woncheon-backend/serverless.yml
git commit -m "perf: reduce authenticated request overhead"
```

---

### Task 5: Prayer List Refresh And Pagination Feel

**User-visible goal:** Pull-to-refresh should not blank out the existing list, and infinite scroll should stay stable.

**Files:**
- Modify: `lib/features/prayer/presentation/prayer_providers.dart`
- Modify: `lib/features/prayer/presentation/prayer_list_page.dart`
- Test: `test/features/prayer/presentation/prayer_providers_test.dart`

- [ ] **Step 1: Write provider test for preserving items during refresh**

Create `test/features/prayer/presentation/prayer_providers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refresh preserves current prayer list while fetching fresh data', () async {
    final container = ProviderContainer(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(
          FakePrayerRepository(
            firstItems: [fakePrayer('P1')],
            refreshedItems: [fakePrayer('P2')],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(prayerListProvider.future);
    expect(initial.items.map((p) => p.prayerId), ['P1']);

    final refreshFuture = container.read(prayerListProvider.notifier).refresh();
    final duringRefresh = container.read(prayerListProvider).valueOrNull;
    expect(duringRefresh?.items.map((p) => p.prayerId), ['P1']);

    await refreshFuture;
    final refreshed = container.read(prayerListProvider).valueOrNull;
    expect(refreshed?.items.map((p) => p.prayerId), ['P2']);
  });
}
```

Define these helpers in the same test file:

```dart
PrayerItem fakePrayer(String id) {
  return PrayerItem(
    prayerId: id,
    authorName: '테스터',
    isAnonymous: false,
    contentPreview: '기도제목',
    createdAt: '2026-07-14T00:00:00.000Z',
  );
}

class FakePrayerRepository extends PrayerRepository {
  FakePrayerRepository({
    required this.firstItems,
    required this.refreshedItems,
  }) : super(ApiClient.forTest());

  final List<PrayerItem> firstItems;
  final List<PrayerItem> refreshedItems;
  var calls = 0;

  @override
  Future<PrayerListResponse> listPrayers({
    int limit = AppConstants.defaultPageSize,
    String? cursor,
    String? startDate,
    String? endDate,
    List<String>? memberIds,
  }) async {
    calls += 1;
    return PrayerListResponse(
      items: calls == 1 ? firstItems : refreshedItems,
      hasMore: false,
      nextCursor: null,
    );
  }
}
```

- [ ] **Step 2: Run test and confirm it fails**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_providers_test.dart
```

Expected: FAIL because current `refresh()` invalidates self and enters loading.

- [ ] **Step 3: Add refresh state without blanking list**

In `PrayerListState`, add:

```dart
this.isRefreshing = false,
final bool isRefreshing;
```

Update `copyWith`, equality, and hashCode to include `isRefreshing`.

Change `refresh()`:

```dart
Future<void> refresh() async {
  final current = state.valueOrNull;
  if (current == null) {
    ref.invalidateSelf();
    await future;
    return;
  }

  state = AsyncData(current.copyWith(isRefreshing: true));
  final filter = ref.read(prayerFilterProvider);
  final repo = ref.read(prayerRepositoryProvider);
  final response = await repo.listPrayers(
    startDate: filter.startDate?.toUtc().toIso8601String(),
    endDate: filter.endDate?.toUtc().toIso8601String(),
  );

  state = AsyncData(
    PrayerListState(
      items: response.items,
      nextCursor: response.nextCursor,
      hasMore: response.hasMore,
    ),
  );
}
```

- [ ] **Step 4: Keep list visible in UI**

In `prayer_list_page.dart`, when `state.isRefreshing` is true, keep rendering `data.items` and rely on `RefreshIndicator` for feedback. Do not replace the list with `WCLoadingView`.

- [ ] **Step 5: Verify task**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_providers_test.dart
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/prayer/presentation/prayer_providers.dart lib/features/prayer/presentation/prayer_list_page.dart test/features/prayer/presentation/prayer_providers_test.dart
git commit -m "perf: preserve prayer list during refresh"
```

---

### Task 6: Comment And Reaction Responsiveness

**User-visible goal:** Tapping pray/comment actions should feel immediate and should not allow accidental duplicate backend operations.

**Files:**
- Modify: `lib/features/prayer/presentation/prayer_providers.dart`
- Modify: `lib/features/prayer/presentation/prayer_detail_page.dart`
- Test: `test/features/prayer/presentation/prayer_detail_page_test.dart`

- [ ] **Step 1: Write reaction double-tap guard test**

Add to `test/features/prayer/presentation/prayer_detail_page_test.dart`:

```dart
testWidgets('reaction ignores duplicate taps while request is pending', (tester) async {
  final repo = FakePrayerRepository(toggleDelay: const Duration(seconds: 1));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [prayerRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(body: buildPrayerReactionRowForTest('P1')),
      ),
    ),
  );

  await tester.tap(find.byType(PrayButton));
  await tester.tap(find.byType(PrayButton));

  expect(repo.toggleReactionCalls, 1);
});
```

Add a narrow test seam in `lib/features/prayer/presentation/prayer_detail_page.dart`:

```dart
@visibleForTesting
Widget buildPrayerReactionRowForTest(String prayerId) {
  return _ReactionRow(prayerId: prayerId);
}
```

Define `FakePrayerRepository` in the test file or reuse the helper from `prayer_providers_test.dart` if it has been moved to a shared test helper file. The fake must override `getReaction` and `toggleReaction`:

```dart
class FakePrayerRepository extends PrayerRepository {
  FakePrayerRepository({this.toggleDelay = Duration.zero}) : super(ApiClient.forTest());

  final Duration toggleDelay;
  var toggleReactionCalls = 0;

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
```

- [ ] **Step 2: Run test and confirm it fails**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_detail_page_test.dart
```

Expected: FAIL because current reaction toggle has no pending guard.

- [ ] **Step 3: Add pending guard to ReactionNotifier**

In `ReactionNotifier`:

```dart
bool _isToggling = false;

Future<void> toggle() async {
  if (_isToggling) return;
  _isToggling = true;
  final previous = state.valueOrNull;
  if (previous != null) {
    state = AsyncData(
      ReactionState(
        reacted: !previous.reacted,
        count: previous.count + (previous.reacted ? -1 : 1),
      ),
    );
  }

  try {
    final result = await ref.read(prayerRepositoryProvider).toggleReaction(arg);
    state = AsyncData(result);
  } catch (e, st) {
    if (previous != null) state = AsyncData(previous);
    Error.throwWithStackTrace(e, st);
  } finally {
    _isToggling = false;
  }
}
```

- [ ] **Step 4: Disable reaction tap while provider is loading if needed**

In `_ReactionRow`, use the provider state:

```dart
final isPending = asyncState.isLoading;
PrayButton(
  count: state.count,
  reacted: state.reacted,
  onTap: isPending
      ? null
      : () async {
          await ref.read(reactionProvider(prayerId).notifier).toggle();
        },
)
```

If `PrayButton.onTap` is non-nullable, change it to `VoidCallback?` and render disabled styling only in `lib/shared/widgets/wc_widgets.dart`.

- [ ] **Step 5: Verify task**

Run:

```bash
flutter test test/features/prayer/presentation/prayer_detail_page_test.dart
flutter test
```

Expected: duplicate tap test passes and all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/prayer/presentation/prayer_providers.dart lib/features/prayer/presentation/prayer_detail_page.dart lib/shared/widgets/wc_widgets.dart test/features/prayer/presentation/prayer_detail_page_test.dart
git commit -m "perf: make prayer interactions responsive and guarded"
```

---

### Task 7: Notice List Query Efficiency

**User-visible goal:** Notice list should remain quick as draft/published notice count grows. This is lower priority and should stay small.

**Files:**
- Modify: `woncheon-backend/src/functions/notice/list.ts`
- Modify only if needed: `woncheon-admin/src/app/api/admin/notices/route.ts`
- Test: `woncheon-backend/tests/notice/list.test.ts`

- [ ] **Step 1: Write backend test for draft-heavy paging**

In `woncheon-backend/tests/notice/list.test.ts`, add a case that mocks a DynamoDB page containing drafts and published notices. The expected behavior is that published notices are returned and pagination is honest.

```ts
import type { APIGatewayProxyEvent, Context, Callback } from 'aws-lambda';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { handler } from '../../src/functions/notice/list.js';
import type { NoticeRecord } from '../../src/types/notice.js';

const { mockDocClientSend } = vi.hoisted(() => ({
  mockDocClientSend: vi.fn(),
}));

vi.mock('../../src/libs/dynamo.js', () => ({
  docClient: { send: mockDocClientSend },
  TABLE_NAME: 'woncheon-test',
}));

const mockContext = {} as Context;
const mockCallback: Callback = vi.fn();

function makeEvent(queryStringParameters: Record<string, string>): APIGatewayProxyEvent {
  return {
    queryStringParameters,
    pathParameters: null,
    headers: {},
    multiValueHeaders: {},
    httpMethod: 'GET',
    isBase64Encoded: false,
    path: '/notices',
    resource: '/notices',
    body: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as APIGatewayProxyEvent['requestContext'],
  };
}

function makeNotice(overrides: Partial<NoticeRecord>): NoticeRecord {
  return {
    noticeId: 'NOTICE',
    title: '공지',
    content: '공지 내용',
    status: 'published',
    pinned: false,
    createdAt: '2026-07-14T00:00:00.000Z',
    updatedAt: '2026-07-14T00:00:00.000Z',
    publishedAt: '2026-07-14T00:00:00.000Z',
    ...overrides,
  };
}

beforeEach(() => {
  mockDocClientSend.mockReset();
});

it('does not return an empty page when drafts are present before published notices', async () => {
  mockDocClientSend.mockResolvedValueOnce({
    Items: [
      makeNotice({ noticeId: 'DRAFT01', status: 'draft' }),
      makeNotice({ noticeId: 'NOTICE01', status: 'published' }),
    ],
    LastEvaluatedKey: undefined,
  });

  const res = await handler(makeEvent({ limit: '2' }), mockContext, mockCallback);
  const body = JSON.parse(res.body);

  expect(body.data.items.map((item: { noticeId: string }) => item.noticeId)).toEqual([
    'NOTICE01',
  ]);
  expect(body.data.hasMore).toBe(false);
});
```

- [ ] **Step 2: Run test**

Run:

```bash
cd woncheon-backend && pnpm test tests/notice/list.test.ts
```

Expected: PASS if current behavior is acceptable for small volume.

- [ ] **Step 3: If test reveals bad paging, increase query window before key redesign**

In `notice/list.ts`, keep the public response limit but query a slightly wider page:

```ts
const queryLimit = Math.min(limit * 3, 100);
```

Use `Limit: queryLimit`, then slice after filtering:

```ts
const items = ((result.Items ?? []) as NoticeRecord[])
  .filter((item) => item.status === 'published')
  .slice(0, limit)
  .map(toNoticeListItem);
```

This is intentionally smaller than a key redesign.

- [ ] **Step 4: Verify task**

Run:

```bash
cd woncheon-backend && pnpm test tests/notice/list.test.ts
cd woncheon-backend && pnpm sls package --stage dev
```

Expected: notice tests and packaging pass.

- [ ] **Step 5: Commit**

```bash
git add woncheon-backend/src/functions/notice/list.ts woncheon-backend/tests/notice/list.test.ts
git commit -m "perf: keep notice list paging stable with drafts"
```

---

### Task 8: Backend Data Model Scale Work

**User-visible goal:** Avoid premature DynamoDB redesign. Only do scale work when data volume makes filtered queries slow enough for users to notice.

**Files:**
- Create: `docs/performance/backend-scale-thresholds.md`
- Modify later only if thresholds are exceeded: `woncheon-backend/src/functions/prayer/list.ts`
- Modify later only if thresholds are exceeded: `woncheon-backend/serverless.yml`

- [ ] **Step 1: Create threshold doc**

Create `docs/performance/backend-scale-thresholds.md`:

```markdown
# Backend Scale Thresholds

We do not redesign DynamoDB keys until a user-visible threshold is crossed.

## Prayer List

Current path:
- Query `GSI2PK = PRAYER_LIST`
- Optionally filter by date, member IDs, and blocked members
- Wider query window is used when server-side filtering is active

Redesign trigger:
- p95 `/prayers` latency over 800ms for 3 consecutive days, or
- group-prayer section regularly returns fewer than requested items while `LastEvaluatedKey` exists, or
- DynamoDB consumed reads for `/prayers` become a meaningful cost driver.

Candidate redesign:
- Add member-scoped list keys for group/member filtered reads.
- Preserve anonymity in API responses.
- Keep existing `PRAYER_LIST` for global feed.

## Notice List

Current path:
- Query `GSI2PK = NOTICE_LIST`
- Filter `status = published`

Redesign trigger:
- more than 100 unpublished/draft notices, or
- p95 `/notices` latency over 500ms for 3 consecutive days.

Candidate redesign:
- Write published notices to a published-only list key.
- Remove from published key when unpublished.
```

- [ ] **Step 2: Verify doc has no red-flag words**

Run:

```bash
rg -n "unresolved|marker|left blank" docs/performance/backend-scale-thresholds.md
```

Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git add docs/performance/backend-scale-thresholds.md
git commit -m "docs: define backend scale thresholds"
```

---

## Verification Checklist

Run after all tasks selected for the current batch:

```bash
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
cd woncheon-backend && pnpm test tests/notice/list.test.ts
cd woncheon-backend && pnpm sls package --stage dev
```

Expected:
- Flutter tests pass.
- Android debug build passes.
- iOS debug no-codesign build passes.
- Notice backend tests pass.
- Serverless package succeeds.

Known current caveat:
- `flutter analyze` may exit 1 due existing info-level lints unrelated to this plan. Treat new warnings in touched files as blockers, but do not do a broad lint cleanup inside these performance tasks.

## Andrej-Style Self-Review

**Think before coding:** The plan interprets the request as perceived-performance work, not feature expansion. It prioritizes visible latency points before backend purity.

**Keep it simple:** The plan avoids new dependencies, offline mode, global cache frameworks, and broad data-model rewrites. The only infra tuning is a short authorizer TTL.

**Make surgical changes:** Each task names a small set of files. The lowest-priority scale work is documentation and thresholds, not immediate table redesign.

**Define and verify the goal:** Each task has a user-visible goal, a failing or confirming test, concrete commands, and expected outcomes.

## Execution Recommendation

Do Tasks 1-4 first. They should produce the highest felt improvement for the least scope. Tasks 5-6 are interaction polish. Tasks 7-8 should wait unless testing or production metrics show a problem.
