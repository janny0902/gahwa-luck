import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_shell.dart';

import '../../core/legal_links.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn(OAuthProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final redirect = kIsWeb ? Uri.base.origin : SupabaseBootstrap.redirectTo;
      await client.auth.signInWithOAuth(
        provider,
        redirectTo: redirect,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } catch (e) {
      setState(() => _error = '로그인 시작 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HanjiBackground(
      animated: true,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                '가화만사성',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '우리집 궁합 · 운세 · 사주',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.inkSoft),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.crimson, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _loading ? null : () => _signIn(OAuthProvider.google),
                child: const Text('Google로 계속하기'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : () => _signIn(OAuthProvider.kakao),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 52),
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.crimson, width: 1.4),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('카카오로 계속하기'),
              ),
              if (_loading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
              if (kDebugMode && kIsWeb) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeShell(preview: true),
                      ),
                    );
                  },
                  child: const Text('디자인 미리보기'),
                ),
              ],
              const Spacer(flex: 2),
              const Text(
                '로그인 시 개인정보 처리방침에 동의하게 됩니다.\n운세 결과는 오락 목적입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.4),
              ),
              TextButton(
                onPressed: () => openLegalPage(context, privacyPolicyUrl),
                style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                child: const Text('개인정보 처리방침'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
