import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/mock/mock_auth_repository.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/auth/presentation/auth_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '이름과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Haptic.medium();

    try {
      late final Map<String, dynamic> data;
      if (kMockMode) {
        final mockRepo = ref.read(mockAuthRepositoryProvider);
        data = await mockRepo.login(name: name, password: password);
      } else {
        final authRepo = ref.read(authRepositoryProvider);
        data = await authRepo.login(name: name, password: password);
      }
      final isFirstLogin = data['isFirstLogin'] as bool? ?? false;

      if (!mounted) return;

      if (isFirstLogin) {
        context.go(AppRoutes.changePassword);
      } else {
        context.go(AppRoutes.home);
      }
    } on MockApiException catch (e) {
      await Haptic.heavy();
      setState(() => _errorMessage = e.message);
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() {
        _errorMessage = getApiErrorMessage(e, fallback: '로그인에 실패했습니다.');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [AppColors.darkSurface, AppColors.darkSurface]
                : const [Color(0xFFECECEA), AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/woncheon_lgo.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '원천청년부',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '함께 기도하고, 함께 성장해요',
                        style: TextStyle(
                          fontSize: 15,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: context.cardShadowColor,
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AdaptiveTextField(
                              controller: _nameController,
                              placeholder: '이름',
                              textInputAction: TextInputAction.next,
                              focusNode: _nameFocus,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            AdaptiveTextField(
                              controller: _passwordController,
                              placeholder: '비밀번호',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              focusNode: _passwordFocus,
                              onSubmitted: (_) => _handleLogin(),
                            ),

                            // Error
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _errorMessage != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withAlpha(15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),

                            AdaptiveButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                              child: const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
