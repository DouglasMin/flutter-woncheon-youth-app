import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_filter_bar.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class PrayerListPage extends ConsumerStatefulWidget {
  const PrayerListPage({super.key});

  @override
  ConsumerState<PrayerListPage> createState() => _PrayerListPageState();
}

class _PrayerListPageState extends ConsumerState<PrayerListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    Haptic.selection();
    final current = ref.read(prayerViewModeProvider);
    ref.read(prayerViewModeProvider.notifier).state =
        current == PrayerViewMode.list
            ? PrayerViewMode.card
            : PrayerViewMode.list;
  }

  void _onScroll() {
    final isLoading =
        ref.read(prayerListProvider).valueOrNull?.isLoadingMore ?? false;
    if (isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(prayerListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerListProvider);
    final readIds = ref.watch(readPrayerIdsProvider).valueOrNull ?? {};
    final viewMode = ref.watch(prayerViewModeProvider);

    final listContent = state.when(
      loading: () => Center(
        child: isIOS
            ? const CupertinoActivityIndicator(radius: 14)
            : const CircularProgressIndicator(),
      ),
      error: (e, _) => _buildError(),
      data: (data) {
        if (data.items.isEmpty) return _buildEmpty();

        return RefreshIndicator(
          onRefresh: () => ref.read(prayerListProvider.notifier).refresh(),
          color: AppColors.primary,
          child: viewMode == PrayerViewMode.list
              ? ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount:
                      data.items.length + (data.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) =>
                      _buildItem(context, data, index, readIds),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount:
                      data.items.length + (data.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) =>
                      _buildItem(context, data, index, readIds),
                ),
        );
      },
    );

    final body = Column(
      children: [
        const SizedBox(height: 8),
        const PrayerFilterBar(),
        const SizedBox(height: 8),
        Expanded(child: listContent),
      ],
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '중보기도',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _toggleViewMode,
            child: Icon(
              viewMode == PrayerViewMode.list
                  ? FluentIcons.grid_24_regular
                  : FluentIcons.list_24_regular,
              size: 22,
            ),
          ),
          backgroundColor: MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? AppTheme.cupertinoDark.barBackgroundColor
              : AppTheme.cupertinoLight.barBackgroundColor,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              SafeArea(child: body),
              Positioned(
                right: 20,
                bottom: 28,
                child: _buildFab(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('중보기도'),
        actions: [
          IconButton(
            onPressed: _toggleViewMode,
            icon: Icon(
              viewMode == PrayerViewMode.list
                  ? FluentIcons.grid_24_regular
                  : FluentIcons.list_24_regular,
              size: 22,
            ),
          ),
        ],
      ),
      body: body,
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.error_circle_24_regular,
              size: 36,
              color: AppColors.error.withAlpha(150),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(prayerListProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.heart_24_regular,
              size: 44,
              color: AppColors.primary.withAlpha(120),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '아직 올라온 기도가 없어요',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '첫 번째로 나눠주세요',
            style: TextStyle(
              fontSize: 14,
              color: context.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    PrayerListState data,
    int index,
    Set<String> readIds,
  ) {
    if (index == data.items.length) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
    }

    final item = data.items[index];
    final date = DateTime.tryParse(item.createdAt);
    final dateStr = date != null
        ? DateFormat('M/d (E)', 'ko').format(date.toLocal())
        : '';
    final viewMode = ref.read(prayerViewModeProvider);

    if (viewMode == PrayerViewMode.card) {
      return _PrayerCardCompact(
        authorName: item.authorName,
        contentPreview: item.contentPreview,
        dateStr: dateStr,
        isAnonymous: item.isAnonymous,
        isRead: readIds.contains(item.prayerId),
        onTap: () {
          Haptic.selection();
          context.push(AppRoutes.prayerDetail(item.prayerId));
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _PrayerCard(
        authorName: item.authorName,
        contentPreview: item.contentPreview,
        dateStr: dateStr,
        isAnonymous: item.isAnonymous,
        isRead: readIds.contains(item.prayerId),
        onTap: () {
          Haptic.selection();
          context.push(AppRoutes.prayerDetail(item.prayerId));
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          await Haptic.light();
          if (!context.mounted) return;
          final result = await context.push<bool>(AppRoutes.prayerCreate);
          if (result ?? false) {
            await ref.read(prayerListProvider.notifier).refresh();
          }
        },
        child: const Icon(FluentIcons.compose_24_filled),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.authorName,
    required this.contentPreview,
    required this.dateStr,
    required this.isAnonymous,
    required this.isRead,
    required this.onTap,
  });

  final String authorName;
  final String contentPreview;
  final String dateStr;
  final bool isAnonymous;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = authorName.isEmpty ? '?' : authorName[0];
    final avatarColors = isAnonymous
        ? [AppColors.textTertiary, const Color(0xFFB0B8C4)]
        : [AppColors.primaryDark, AppColors.primary];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.cardShadowColor,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: avatarColors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      authorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isRead)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.textTertiary.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '읽음',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.textTertiary,
                          ),
                        ),
                      ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  contentPreview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact card for grid/card view
class _PrayerCardCompact extends StatelessWidget {
  const _PrayerCardCompact({
    required this.authorName,
    required this.contentPreview,
    required this.dateStr,
    required this.isAnonymous,
    required this.isRead,
    required this.onTap,
  });

  final String authorName;
  final String contentPreview;
  final String dateStr;
  final bool isAnonymous;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = authorName.isEmpty ? '?' : authorName[0];
    final avatarColors = isAnonymous
        ? [AppColors.textTertiary, const Color(0xFFB0B8C4)]
        : [AppColors.primaryDark, AppColors.primary];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.cardShadowColor,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: avatarColors),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authorName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Content
                Expanded(
                  child: Text(
                    contentPreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Date + read
                Row(
                  children: [
                    if (isRead)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.textTertiary.withAlpha(20),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '읽음',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textTertiary,
                          ),
                        ),
                      ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
