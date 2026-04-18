import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/api/auth_event_bus.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _memberName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final storage = ref.read(secureStorageServiceProvider);
    final name = await storage.getMemberName();
    if (mounted) setState(() => _memberName = name ?? '');
  }

  Future<void> _openPrivacyPolicy() async {
    final uri =
        Uri.parse('https://douglasmin.github.io/flutter-woncheon-youth-app/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '로그아웃',
      content: '로그아웃 하시겠습니까?',
      confirmText: '로그아웃',
    );
    if (confirmed != true || !mounted) return;
    await ref.read(secureStorageServiceProvider).clearAll();
    AuthEventBus.instance.emit(AuthEvent.logout);
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '계정 삭제',
      content: '계정을 삭제하면 작성한 기도, 댓글, 반응이 모두 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final doubleConfirm = await showAdaptiveConfirmDialog(
      context,
      title: '정말 삭제하시겠습니까?',
      content: '삭제된 데이터는 복구할 수 없습니다.',
      confirmText: '영구 삭제',
      isDestructive: true,
    );
    if (doubleConfirm != true || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .dio
          .delete<Map<String, dynamic>>('/auth/account');
      await ref.read(secureStorageServiceProvider).clearAll();
      AuthEventBus.instance.emit(AuthEvent.logout);
    } on DioException catch (e) {
      if (mounted) {
        final msg = getApiErrorMessage(e, fallback: '계정 삭제에 실패했습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
              child: Text(
                '더보기',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: wc.text,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            // Profile card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: wc.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: wc.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: wc.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _memberName.isEmpty ? '?' : _memberName[0],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: wc.accentInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _memberName.isEmpty ? '...' : _memberName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: wc.text,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '원천청년부',
                            style: TextStyle(
                              fontSize: 12,
                              color: wc.textTer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionLabel('계정'),
            _Group(items: [
              _Row(
                icon: FluentIcons.shield_24_regular,
                label: '개인정보 처리방침',
                trailing: Text(
                  '외부 링크',
                  style: TextStyle(fontSize: 11, color: wc.textTer),
                ),
                onTap: _openPrivacyPolicy,
              ),
              _Row(
                icon: FluentIcons.sign_out_24_regular,
                label: '로그아웃',
                onTap: _handleLogout,
              ),
            ]),
            const SectionLabel('위험 영역', danger: true),
            _Group(items: [
              _Row(
                icon: FluentIcons.delete_24_regular,
                label: '계정 삭제',
                danger: true,
                onTap: _handleDeleteAccount,
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              child: Center(
                child: Text(
                  '원천청년부 · v1.0.0',
                  style: TextStyle(fontSize: 11, color: wc.textTer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.items});
  final List<_Row> items;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: wc.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: wc.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: wc.border,
                    ),
                  ),
                items[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                Haptic.light();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Center(
                  child: Icon(
                    icon,
                    size: 19,
                    color: danger ? wc.danger : wc.textSec,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: danger ? wc.danger : wc.text,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    FluentIcons.chevron_right_24_regular,
                    size: 16,
                    color: wc.textTer,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
