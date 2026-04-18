import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class RegisterRequestPage extends ConsumerStatefulWidget {
  const RegisterRequestPage({super.key});

  @override
  ConsumerState<RegisterRequestPage> createState() =>
      _RegisterRequestPageState();
}

class _RegisterRequestPageState extends ConsumerState<RegisterRequestPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = '이름을 입력해주세요.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = '연락처를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await Haptic.medium();

    try {
      await ref.read(apiClientProvider).dio.post<Map<String, dynamic>>(
        '/auth/register-request',
        data: {'name': name, 'phone': phone, 'note': note},
      );
      setState(() => _success = true);
      await Haptic.light();
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() {
        _errorMessage = getApiErrorMessage(e, fallback: '요청에 실패했습니다.');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    if (_success) {
      return Scaffold(
        backgroundColor: wc.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go(AppRoutes.login),
                    padding: EdgeInsets.zero,
                    icon: Icon(FluentIcons.dismiss_24_regular,
                        color: wc.textSec, size: 26),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: wc.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FluentIcons.checkmark_24_regular,
                            size: 36,
                            color: wc.accentInk,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '등록 요청을 보냈어요',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: wc.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '관리자 승인 후\n로그인이 가능해져요. (보통 1–2일)',
                          style: TextStyle(
                            fontSize: 14,
                            color: wc.textSec,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                WCButton(
                  onPressed: () => context.go(AppRoutes.login),
                  tone: WCButtonTone.soft,
                  child: const Text('로그인 화면으로'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: Icon(FluentIcons.chevron_left_24_regular,
                    color: wc.textSec, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                '새신자 등록 요청',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: wc.text,
                  letterSpacing: -0.6,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '정보를 남겨주시면 담당자가\n확인 후 연락드릴게요.',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSec,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              _field(
                controller: _nameController,
                hint: '이름',
                action: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _phoneController,
                hint: '연락처 (카카오 ID 또는 전화번호)',
                action: TextInputAction.next,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _noteController,
                hint: '간단한 소개 (예: 소개해주신 분, 사는 동네, 한 줄 자기소개)',
                minLines: 4,
                maxLines: 6,
                action: TextInputAction.newline,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: wc.danger, fontSize: 13),
                ),
              ],
              const Spacer(),
              WCButton(
                onPressed: _isLoading ? null : _handleSubmit,
                disabled: _isLoading,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: wc.bg,
                        ),
                      )
                    : const Text('요청 보내기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputAction action = TextInputAction.next,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final wc = context.wc;
    return TextField(
      controller: controller,
      textInputAction: action,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: wc.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: wc.surface,
        hintStyle: TextStyle(color: wc.textTer, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.accent, width: 1.5),
        ),
      ),
    );
  }
}
