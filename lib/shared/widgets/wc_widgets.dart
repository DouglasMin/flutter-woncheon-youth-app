import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';

/// Tonal pill badge. `anon` tone is used for anonymous content affordance.
enum WCPillTone { neutral, accent, anon, success, danger }

class WCPill extends StatelessWidget {
  const WCPill({
    required this.child,
    this.tone = WCPillTone.neutral,
    this.small = false,
    this.leading,
    super.key,
  });

  final Widget child;
  final WCPillTone tone;
  final bool small;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final (bg, fg, bd) = switch (tone) {
      WCPillTone.neutral => (wc.surfaceAlt, wc.textSec, wc.border),
      WCPillTone.accent => (wc.accentSoft, wc.accentInk, Colors.transparent),
      WCPillTone.anon => (wc.anon, wc.anonText, wc.anonBorder),
      WCPillTone.success => (wc.accentSoft, wc.success, Colors.transparent),
      WCPillTone.danger => (wc.danger.withAlpha(30), wc.danger, Colors.transparent),
    };
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          DefaultTextStyle(
            style: TextStyle(
              fontSize: small ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.2,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// "익명" pill with mask icon baked in.
class AnonPill extends StatelessWidget {
  const AnonPill({this.small = false, super.key});
  final bool small;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return WCPill(
      tone: WCPillTone.anon,
      small: small,
      leading: Icon(
        FluentIcons.eye_off_16_regular,
        size: small ? 11 : 13,
        color: wc.anonText,
      ),
      child: const Text('익명'),
    );
  }
}

enum WCButtonTone { primary, soft, ghost, accent, danger }

class WCButton extends StatelessWidget {
  const WCButton({
    required this.onPressed,
    required this.child,
    this.tone = WCButtonTone.primary,
    this.full = true,
    this.small = false,
    this.disabled = false,
    this.leading,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final WCButtonTone tone;
  final bool full;
  final bool small;
  final bool disabled;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final (rawBg, rawFg, rawBd) = switch (tone) {
      WCButtonTone.primary => (wc.text, wc.bg, Colors.transparent),
      WCButtonTone.soft => (wc.surfaceAlt, wc.text, wc.border),
      WCButtonTone.ghost => (Colors.transparent, wc.text, wc.border),
      WCButtonTone.accent => (wc.accent, wc.bg, Colors.transparent),
      WCButtonTone.danger =>
        (Colors.transparent, wc.danger, Colors.transparent),
    };
    final bg = disabled ? rawBg.withValues(alpha: 0.4) : rawBg;
    final fg = disabled ? rawFg.withValues(alpha: 0.5) : rawFg;
    final bd = disabled ? rawBd.withValues(alpha: 0.4) : rawBd;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed?.call();
              },
        child: Container(
          width: full ? double.infinity : null,
          padding: small
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bd),
          ),
          child: Row(
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: -0.3,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WCCard extends StatelessWidget {
  const WCCard({
    required this.child,
    this.anon = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    super.key,
  });

  final Widget child;
  final bool anon;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: anon ? wc.anon : wc.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: anon ? wc.anonBorder : wc.border, width: 1),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(radius),
        child: body,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.danger = false, super.key});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: danger ? wc.danger : wc.textSec,
        ),
      ),
    );
  }
}

/// Animated 🙏 pray button — emits floating emoji bursts when tapped.
class PrayButton extends StatefulWidget {
  const PrayButton({
    required this.count,
    required this.reacted,
    required this.onTap,
    super.key,
  });

  final int count;
  final bool reacted;
  final VoidCallback onTap;

  @override
  State<PrayButton> createState() => _PrayButtonState();
}

class _PrayButtonState extends State<PrayButton>
    with TickerProviderStateMixin {
  final _bursts = <_Burst>[];

  void _spawnBurst() {
    final burst = _Burst(
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
      dx: math.Random().nextDouble() * 20 - 10,
    );
    burst.controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _bursts.remove(burst));
        burst.controller.dispose();
      }
    });
    setState(() => _bursts.add(burst));
    burst.controller.forward();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    _spawnBurst();
    widget.onTap();
  }

  @override
  void dispose() {
    for (final b in _bursts) {
      b.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final reacted = widget.reacted;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Material(
          color: reacted ? wc.accentSoft : wc.surface,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(14, 10, 18, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: reacted ? Colors.transparent : wc.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: reacted ? 1.1 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Text(
                      '🙏',
                      style: TextStyle(fontSize: reacted ? 22 : 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: reacted ? wc.accentInk : wc.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final b in _bursts)
          Positioned(
            top: -8,
            child: FadeTransition(
              opacity: b.opacity,
              child: AnimatedBuilder(
                animation: b.controller,
                builder: (context, child) {
                  final v = b.controller.value;
                  final dy = -v * 80;
                  final scale =
                      v < 0.6 ? 0.6 + v * 1.0 : 1.2 - (v - 0.6) * 0.8;
                  return Transform.translate(
                    offset: Offset(b.dx, dy),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: const Text('🙏', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Burst {
  _Burst({required this.controller, required this.dx})
      : opacity = TweenSequence<double>([
          TweenSequenceItem(
            tween: ConstantTween<double>(1),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1, end: 0)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
        ]).animate(controller);

  final AnimationController controller;
  final double dx;
  final Animation<double> opacity;
}

/// Unread dot — small accent-colored circle.
class UnreadDot extends StatelessWidget {
  const UnreadDot({this.size = 7, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: wc.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Filter chip styled per design (pill, flipped colors when active).
class WCFilterChip extends StatelessWidget {
  const WCFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Material(
      color: active ? wc.text : wc.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? wc.text : wc.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? wc.bg : wc.textSec,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Korean weekday short label for a given date.
/// Dart's `DateTime.weekday` is Mon=1..Sun=7.
String koreanWeekday(DateTime date) {
  const mondayFirst = ['월', '화', '수', '목', '금', '토', '일'];
  return mondayFirst[date.weekday - 1];
}

/// Relative time formatter matching design's `formatRelative` util.
String formatRelative(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diffH = n.difference(date).inHours;
  if (diffH < 1) return '방금 전';
  if (diffH < 24) return '$diffH시간 전';
  final diffD = diffH ~/ 24;
  if (diffD < 7) return '$diffD일 전';
  return '${date.month}/${date.day} (${koreanWeekday(date)})';
}
