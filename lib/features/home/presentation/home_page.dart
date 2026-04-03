import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

final _memberNameProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return await storage.getMemberName() ?? '청년부원';
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '원천청년부',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? AppTheme.cupertinoDark.barBackgroundColor
              : AppTheme.cupertinoLight.barBackgroundColor,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: _buildBody(context, ref),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('원천청년부')),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final memberName = ref.watch(_memberNameProvider).valueOrNull ?? '청년부원';
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        'assets/images/praying-image-black.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(170),
                            ],
                            stops: const [0.25, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$memberName님,\n오늘도 함께 기도해요',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '원천청년부',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textOnDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '메뉴',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4 equal cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ImageMenuCard(
                    imagePath: 'assets/images/group-praying-black.png',
                    label: '중보기도',
                    subtitle: '함께 기도해요',
                    onTap: () {
                      Haptic.light();
                      context.push(AppRoutes.prayerList);
                    },
                  ),
                  _MenuCard(
                    icon: FluentIcons.checkmark_circle_24_filled,
                    label: '출결',
                    subtitle: '출석 체크',
                    enabled: true,
                    iconColor: const Color(0xFF38A169),
                    onTap: () {
                      Haptic.light();
                      if (DateTime.now().weekday != DateTime.sunday) {
                        showAdaptiveConfirmDialog(
                          context,
                          title: '출석 체크',
                          content: '출석 체크는 주일(일요일)에만 가능합니다.\n그래도 이전 주차 출석을 확인하시겠습니까?',
                          confirmText: '확인하기',
                        ).then((confirmed) {
                          if (confirmed == true && context.mounted) {
                            context.push(AppRoutes.attendanceCheck);
                          }
                        });
                        return;
                      }
                      context.push(AppRoutes.attendanceCheck);
                    },
                  ),
                  _MenuCard(
                    icon: FluentIcons.music_note_2_24_filled,
                    label: '송리스트',
                    subtitle: '준비 중',
                    enabled: false,
                    iconColor: const Color(0xFF9CA3AF),
                    onTap: () => _showComingSoon(context),
                  ),
                  _MenuCard(
                    icon: FluentIcons.grid_24_filled,
                    label: '더보기',
                    subtitle: '준비 중',
                    enabled: false,
                    iconColor: const Color(0xFF9CA3AF),
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    Haptic.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('추후 추가될 예정이에요'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _ImageMenuCard extends StatelessWidget {
  const _ImageMenuCard({
    required this.imagePath,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            // Dark overlay for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(30),
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
            ),
            // Text
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            // Tap area
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: iconColor),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
