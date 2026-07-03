import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';

/// Tonal pill badge. `anon` tone is used for anonymous content affordance.
enum WCPillTone { neutral, accent, anon, success, danger }

abstract final class WCSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const pageX = lg;
  static const sectionGap = xl;
  static const cardGap = sm;
  static const bottomNavClearance = 120.0;
}

abstract final class WCRadius {
  static const control = 14.0;
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

enum WCCardDensity { regular, compact }

class WCPageScaffold extends StatelessWidget {
  const WCPageScaffold({
    required this.child,
    this.header,
    this.scrollable = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: WCSpacing.pageX,
    ),
    this.bottomPadding = WCSpacing.bottomNavClearance,
    super.key,
  });

  final Widget? header;
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry contentPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) header!,
        Padding(padding: contentPadding, child: child),
        SizedBox(height: bottomPadding),
      ],
    );

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}

class WCHeader extends StatelessWidget {
  const WCHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.titleWidget,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      WCSpacing.pageX,
      WCSpacing.md,
      WCSpacing.pageX,
      WCSpacing.md,
    ),
    super.key,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: TextStyle(
                fontSize: 12,
                color: wc.textTer,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: WCSpacing.xs),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child:
                    titleWidget ??
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: wc.text,
                        letterSpacing: -0.7,
                        height: 1.2,
                      ),
                    ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: WCSpacing.sm),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: WCSpacing.xs),
            Text(subtitle!, style: TextStyle(fontSize: 13, color: wc.textTer)),
          ],
        ],
      ),
    );
  }
}

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
      WCPillTone.danger => (
        wc.danger.withAlpha(30),
        wc.danger,
        Colors.transparent,
      ),
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
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
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
      WCButtonTone.danger => (
        Colors.transparent,
        wc.danger,
        Colors.transparent,
      ),
    };
    final bg = disabled ? rawBg.withValues(alpha: 0.4) : rawBg;
    final fg = disabled ? rawFg.withValues(alpha: 0.5) : rawFg;
    final bd = disabled ? rawBd.withValues(alpha: 0.4) : rawBd;

    return Semantics(
      button: true,
      enabled: !disabled && onPressed != null,
      child: Material(
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
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
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
      ),
    );
  }
}

class WCCard extends StatelessWidget {
  const WCCard({
    required this.child,
    this.anon = false,
    this.onTap,
    this.padding,
    this.density = WCCardDensity.regular,
    this.radius = WCRadius.card,
    super.key,
  });

  final Widget child;
  final bool anon;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final WCCardDensity density;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final resolvedPadding =
        padding ??
        switch (density) {
          WCCardDensity.regular => const EdgeInsets.all(WCSpacing.md),
          WCCardDensity.compact => const EdgeInsets.fromLTRB(
            WCSpacing.md,
            WCSpacing.sm + 2,
            WCSpacing.md,
            WCSpacing.sm + 2,
          ),
        };
    final body = Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: anon ? wc.anon : wc.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: anon ? wc.anonBorder : wc.border),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(radius),
          child: body,
        ),
      ),
    );
  }
}

class WCLoadingView extends StatelessWidget {
  const WCLoadingView({this.label, this.compact = false, super.key});

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final platform = Theme.of(context).platform;
    final indicator = platform == TargetPlatform.iOS
        ? const CupertinoActivityIndicator(radius: 12)
        : SizedBox(
            width: compact ? 18 : 24,
            height: compact ? 18 : 24,
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2 : 2.4,
              color: wc.accent,
            ),
          );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: WCSpacing.pageX,
          vertical: compact ? WCSpacing.md : WCSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (label != null) ...[
              const SizedBox(height: WCSpacing.sm),
              Text(
                label!,
                style: TextStyle(fontSize: 13, color: wc.textTer),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WCStateView extends StatelessWidget {
  const WCStateView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final hasAction = actionLabel != null && onAction != null;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: WCSpacing.pageX,
          vertical: compact ? WCSpacing.lg : 72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                color: wc.surfaceAlt,
                borderRadius: BorderRadius.circular(WCRadius.card),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: compact ? 22 : 26, color: wc.textTer),
            ),
            const SizedBox(height: WCSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: wc.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: WCSpacing.xs),
              Text(
                message!,
                style: TextStyle(fontSize: 13, color: wc.textTer, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: WCSpacing.md),
              WCButton(
                onPressed: onAction,
                small: true,
                full: false,
                tone: WCButtonTone.soft,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WCActionTile extends StatelessWidget {
  const WCActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.accent = false,
    this.disabled = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool accent;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final enabled = !disabled && onTap != null;
    final fg = enabled ? wc.text : wc.textTer;
    final subColor = accent && enabled ? wc.accent : wc.textTer;
    final bg = disabled ? wc.surface.withValues(alpha: 0.58) : wc.surface;
    final iconBg = accent && enabled ? wc.accentSoft : wc.surfaceAlt;
    final iconFg = accent && enabled ? wc.accentInk : fg;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '$title, $subtitle',
      child: Opacity(
        opacity: disabled ? 0.72 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(WCRadius.card),
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(WCRadius.card),
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WCRadius.card),
                border: Border.all(
                  color: disabled
                      ? wc.border.withValues(alpha: 0.72)
                      : wc.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconFg),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: accent && enabled
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: subColor,
                        ),
                      ),
                    ],
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

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.danger = false, super.key});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WCSpacing.pageX,
        WCSpacing.lg,
        WCSpacing.pageX,
        WCSpacing.xs,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
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

class _PrayButtonState extends State<PrayButton> with TickerProviderStateMixin {
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
          child: Semantics(
            button: true,
            selected: reacted,
            label: '함께 기도하기, ${widget.count}명',
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
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
                  final scale = v < 0.6 ? 0.6 + v * 1.0 : 1.2 - (v - 0.6) * 0.8;
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
        TweenSequenceItem(tween: ConstantTween<double>(1), weight: 60),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeOut)),
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
      decoration: BoxDecoration(color: wc.accent, shape: BoxShape.circle),
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
      child: Semantics(
        button: true,
        selected: active,
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
