import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

final _memberNameProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return await storage.getMemberName() ?? '청년부원';
});

// Curated verses — rotated per day. (short preview + full text + reference)
const List<Map<String, String>> _verseData = [
  {
    'short': '내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라',
    'full': '내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라',
    'ref': '빌립보서 4:13',
  },
  {
    'short': '수고하고 무거운 짐 진 자들아 다 내게로 오라',
    'full':
        '수고하고 무거운 짐 진 자들아 다 내게로 오라 내가 너희를 쉬게 하리라 나는 마음이 온유하고 겸손하니 나의 멍에를 메고 내게 배우라 그리하면 너희 마음이 쉼을 얻으리니',
    'ref': '마태복음 11:28–29',
  },
  {
    'short': '여호와는 나의 목자시니 내게 부족함이 없으리로다',
    'full': '여호와는 나의 목자시니 내게 부족함이 없으리로다 그가 나를 푸른 초장에 누이시며 쉴 만한 물 가로 인도하시는도다',
    'ref': '시편 23:1–2',
  },
  {
    'short': '두려워 말라 내가 너와 함께 함이라',
    'full':
        '두려워 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와주리라',
    'ref': '이사야 41:10',
  },
  {
    'short': '너희는 먼저 그의 나라와 그의 의를 구하라',
    'full':
        '그러므로 염려하여 이르기를 무엇을 먹을까 무엇을 마실까 하지 말라 … 너희는 먼저 그의 나라와 그의 의를 구하라 그리하면 이 모든 것을 너희에게 더하시리라',
    'ref': '마태복음 6:33',
  },
  {
    'short': '네 짐을 여호와께 맡겨 버리라 그가 너를 붙드시고',
    'full': '네 짐을 여호와께 맡겨 버리라 그가 너를 붙드시고 의인의 요동함을 영원히 허락하지 아니하시리로다',
    'ref': '시편 55:22',
  },
  {
    'short': '아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로',
    'full':
        '아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로 너희 구할 것을 감사함으로 하나님께 아뢰라 그리하면 모든 지각에 뛰어나신 하나님의 평강이 그리스도 예수 안에서 너희 마음과 생각을 지키시리라',
    'ref': '빌립보서 4:6–7',
  },
  {
    'short': '네 마음을 다하여 여호와를 신뢰하고',
    'full': '네 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라 너는 범사에 그를 인정하라 그리하면 네 길을 지도하시리라',
    'ref': '잠언 3:5–6',
  },
  {
    'short': '강하고 담대하라 두려워하지 말며 놀라지 말라',
    'full':
        '내가 네게 명한 것이 아니냐 강하고 담대하라 두려워하지 말며 놀라지 말라 네가 어디로 가든지 네 하나님 여호와가 너와 함께 하느니라',
    'ref': '여호수아 1:9',
  },
  {
    'short': '사랑은 오래 참고 사랑은 온유하며',
    'full': '사랑은 오래 참고 사랑은 온유하며 시기하지 아니하며 사랑은 자랑하지 아니하며 교만하지 아니하며',
    'ref': '고린도전서 13:4',
  },
  {
    'short': '너는 청년의 때에 너의 창조주를 기억하라',
    'full': '너는 청년의 때 곧 곤고한 날이 이르기 전, 나는 아무 낙이 없다고 할 해가 가까이 오기 전에 너의 창조주를 기억하라',
    'ref': '전도서 12:1',
  },
  {
    'short': '너희는 세상의 빛이라',
    'full':
        '너희는 세상의 빛이라 산 위에 있는 동네가 숨겨지지 못할 것이요 이런 사람의 착한 행실을 보고 하늘에 계신 너희 아버지께 영광을 돌리게 하라',
    'ref': '마태복음 5:14–16',
  },
  {
    'short': '항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라',
    'full': '항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라',
    'ref': '데살로니가전서 5:16–18',
  },
  {
    'short': '마음이 상한 자를 고치시며 그들의 상처를 싸매시는도다',
    'full': '여호와께서는 마음이 상한 자를 고치시며 그들의 상처를 싸매시는도다',
    'ref': '시편 147:3',
  },
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _verseIdx;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    _verseIdx = dayOfYear % _verseData.length;
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    var next = _verseIdx;
    final rng = math.Random();
    while (next == _verseIdx && _verseData.length > 1) {
      next = rng.nextInt(_verseData.length);
    }
    setState(() => _verseIdx = next);
  }

  void _openVerseSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VerseSheet(verse: _verseData[_verseIdx]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final memberName = ref.watch(_memberNameProvider).valueOrNull ?? '청년부원';
    final now = DateTime.now();
    final dateLabel =
        '${now.year}년 ${now.month}월 ${now.day}일 (${koreanWeekday(now)})';
    final hour = now.hour;
    final greet = hour < 12
        ? '좋은 아침이에요'
        : hour < 18
        ? '평안한 오후예요'
        : '평안한 저녁이에요';
    final verse = _verseData[_verseIdx];
    final isSunday = now.weekday == DateTime.sunday;

    return WCPageScaffold(
      header: WCHeader(
        eyebrow: dateLabel,
        title: '$memberName님, $greet',
        titleWidget: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$memberName님,\n',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: wc.text,
                  letterSpacing: -0.6,
                  height: 1.3,
                  fontFamily: AppTheme.pretendard,
                ),
              ),
              TextSpan(
                text: greet,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: wc.textSec,
                  letterSpacing: -0.6,
                  height: 1.3,
                  fontFamily: AppTheme.pretendard,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerseHeroCard(
            verse: verse,
            onShuffle: _shuffle,
            onTap: _openVerseSheet,
          ),
          const SizedBox(height: WCSpacing.sm),
          // Quick actions
          Row(
            children: [
              Expanded(
                child: WCActionTile(
                  icon: FluentIcons.hand_left_24_regular,
                  title: '기도 나누기',
                  subtitle: '함께 기도해요',
                  onTap: () {
                    Haptic.light();
                    context.go(AppRoutes.prayerList);
                  },
                ),
              ),
              const SizedBox(width: WCSpacing.sm),
              Expanded(
                child: WCActionTile(
                  icon: FluentIcons.people_24_regular,
                  title: '우리 목장',
                  subtitle: isSunday ? '오늘 주일이에요' : '목장원과 기도해요',
                  accent: isSunday,
                  onTap: () {
                    Haptic.light();
                    context.go(AppRoutes.attendanceCheck);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: WCSpacing.sectionGap),
          // Coming soon
          Text(
            '준비 중',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: wc.textSec,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: WCSpacing.xs),
          Row(
            children: [
              const Expanded(
                child: WCActionTile(
                  icon: FluentIcons.music_note_2_24_regular,
                  title: '송 리스트',
                  subtitle: '예배 찬양 모음',
                  disabled: true,
                ),
              ),
              const SizedBox(width: WCSpacing.sm),
              Expanded(
                child: WCActionTile(
                  icon: FluentIcons.megaphone_24_regular,
                  title: '공지사항',
                  subtitle: '청년부 소식',
                  onTap: () {
                    Haptic.light();
                    context.push(AppRoutes.notices);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VerseHeroCard extends StatelessWidget {
  const VerseHeroCard({
    required this.verse,
    required this.onShuffle,
    required this.onTap,
    super.key,
  });

  final Map<String, String> verse;
  final VoidCallback onShuffle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ref = verse['ref'] ?? '';
    return Semantics(
      button: true,
      label: ref.isEmpty ? '오늘의 말씀 카드' : '오늘의 말씀 카드, $ref',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(WCRadius.sheet),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1.38,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/praying-image-black.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.48, 1],
                      colors: [
                        Color(0x33000000),
                        Color(0x66000000),
                        Color(0xE6000000),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.36),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: WCSpacing.md,
                  left: WCSpacing.md,
                  right: WCSpacing.md,
                  child: Row(
                    children: [
                      const _HeroBadge(text: '오늘의 말씀'),
                      const Spacer(),
                      _HeroIconButton(
                        tooltip: '말씀 바꾸기',
                        icon: FluentIcons.arrow_shuffle_24_regular,
                        onTap: onShuffle,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: WCSpacing.lg,
                  right: WCSpacing.lg,
                  bottom: WCSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '"${verse['short']}"',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          fontFamily: AppTheme.pretendard,
                          shadows: const [
                            Shadow(
                              blurRadius: 18,
                              color: Colors.black54,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WCSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ref,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: WCSpacing.sm),
                          const _HeroCta(),
                        ],
                      ),
                    ],
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(WCRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white70, blurRadius: 8)],
              ),
            ),
            const SizedBox(width: WCSpacing.xs),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WCRadius.pill),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '말씀 열기',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: WCSpacing.xxs),
            Icon(
              FluentIcons.chevron_right_24_regular,
              size: 14,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseSheet extends StatelessWidget {
  const _VerseSheet({required this.verse});
  final Map<String, String> verse;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Container(
      decoration: BoxDecoration(
        color: wc.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        10,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: wc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '오늘의 말씀',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: wc.accent,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${verse['full']}"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: wc.text,
              letterSpacing: -0.3,
              height: 1.7,
              fontFamily: AppTheme.pretendard,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            verse['ref'] ?? '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: wc.textSec,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: WCButton(
                  tone: WCButtonTone.soft,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: '"${verse['full']}" — ${verse['ref']}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('복사되었어요')));
                    }
                  },
                  child: const Text('복사'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WCButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
