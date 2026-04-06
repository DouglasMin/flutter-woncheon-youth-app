import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

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

  Future<void> _handleLogout() async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '로그아웃',
      content: '로그아웃 하시겠습니까?',
      confirmText: '로그아웃',
    );
    if (confirmed != true || !mounted) return;

    final storage = ref.read(secureStorageServiceProvider);
    await storage.clearAll();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '계정 삭제',
      content:
          '계정을 삭제하면 작성한 기도, 댓글, 반응이 모두 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    // 2차 확인
    final doubleConfirm = await showAdaptiveConfirmDialog(
      context,
      title: '정말 삭제하시겠습니까?',
      content: '삭제된 데이터는 복구할 수 없습니다.',
      confirmText: '영구 삭제',
      isDestructive: true,
    );
    if (doubleConfirm != true || !mounted) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete<Map<String, dynamic>>('/auth/account');

      final storage = ref.read(secureStorageServiceProvider);
      await storage.clearAll();

      if (mounted) {
        context.go(AppRoutes.login);
      }
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
    final content = SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _memberName.isEmpty ? '?' : _memberName[0],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _memberName.isEmpty ? '...' : _memberName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '원천청년부',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings items
          _SettingsItem(
            icon: FluentIcons.sign_out_24_regular,
            label: '로그아웃',
            onTap: _handleLogout,
          ),

          const SizedBox(height: 32),

          // Danger zone
          Text(
            '위험 영역',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsItem(
            icon: FluentIcons.delete_24_regular,
            label: '계정 삭제',
            color: AppColors.error,
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '설정',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  ? AppTheme.cupertinoDark.barBackgroundColor
                  : AppTheme.cupertinoLight.barBackgroundColor,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: content,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.textPrimary;

    return InkWell(
      onTap: () {
        Haptic.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
            const Spacer(),
            Icon(
              FluentIcons.chevron_right_24_regular,
              size: 18,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
