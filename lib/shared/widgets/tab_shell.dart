import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

/// Bottom 4-tab shell wrapping the main navigation branches.
class TabShell extends StatelessWidget {
  const TabShell({required this.navigationShell, super.key});

  /// StatefulNavigationShell exposed via go_router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Scaffold(
      backgroundColor: wc.bg,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: WCTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class WCTabBar extends StatelessWidget {
  const WCTabBar({required this.currentIndex, required this.onTap, super.key});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        WCSpacing.pageX,
        0,
        WCSpacing.pageX,
        WCSpacing.xs,
      ),
      child: Container(
        height: 66,
        padding: const EdgeInsets.all(WCSpacing.xxs),
        decoration: BoxDecoration(
          color: wc.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(WCRadius.sheet),
          border: Border.all(color: wc.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _Item(
              icon: FluentIcons.home_24_regular,
              iconActive: FluentIcons.home_24_filled,
              label: '홈',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _Item(
              icon: FluentIcons.hand_left_24_regular,
              iconActive: FluentIcons.hand_left_24_filled,
              label: '기도',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _Item(
              icon: FluentIcons.people_24_regular,
              iconActive: FluentIcons.people_24_filled,
              label: '목장',
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _Item(
              icon: FluentIcons.more_horizontal_24_regular,
              iconActive: FluentIcons.more_horizontal_24_filled,
              label: '더보기',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final color = active ? wc.accentInk : wc.textTer;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(WCRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(WCRadius.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 58,
              decoration: BoxDecoration(
                color: active ? wc.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(WCRadius.pill),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active ? iconActive : icon, size: 21, color: color),
                  const SizedBox(height: WCSpacing.xxs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: color,
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
