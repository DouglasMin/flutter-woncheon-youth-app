import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';

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
      bottomNavigationBar: _WCTabBar(
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

class _WCTabBar extends StatelessWidget {
  const _WCTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(
            top: 8,
            left: 8,
            right: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: wc.bg.withValues(alpha: 0.93),
            border: Border(
              top: BorderSide(color: wc.border, width: 0.5),
            ),
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
                icon: FluentIcons.calendar_24_regular,
                iconActive: FluentIcons.calendar_24_filled,
                label: '출석',
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
    final color = active ? wc.text : wc.textTer;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? iconActive : icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
