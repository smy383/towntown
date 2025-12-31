import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                const Text(
                  'TownTown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '마을 기반 SNS 메타버스',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 80),

                // Login buttons
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.status == AuthStatus.loading) {
                      return const Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            '로그인 중...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        // Google Login
                        _SocialLoginButton(
                          label: 'Google로 시작하기',
                          iconPath: null,
                          icon: Icons.g_mobiledata,
                          color: Colors.white,
                          textColor: Colors.black87,
                          onPressed: () =>
                              _handleLogin(context, auth.signInWithGoogle),
                        ),
                        const SizedBox(height: 12),

                        // Apple Login (iOS/macOS/Web only)
                        if (_showAppleLogin())
                          _SocialLoginButton(
                            label: 'Apple로 시작하기',
                            iconPath: null,
                            icon: Icons.apple,
                            color: Colors.white,
                            textColor: Colors.black87,
                            onPressed: () =>
                                _handleLogin(context, auth.signInWithApple),
                          ),
                        if (_showAppleLogin()) const SizedBox(height: 12),

                        // Kakao Login
                        _SocialLoginButton(
                          label: '카카오로 시작하기',
                          iconPath: null,
                          icon: Icons.chat_bubble,
                          color: const Color(0xFFFEE500),
                          textColor: const Color(0xFF191919),
                          onPressed: () =>
                              _handleLogin(context, auth.signInWithKakao),
                        ),

                        // Error message
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style:
                                        const TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => auth.clearError(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const Spacer(),

                // Footer
                Text(
                  'By continuing, you agree to our Terms of Service',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _showAppleLogin() {
    if (kIsWeb) return true;
    if (!kIsWeb && Platform.isIOS) return true;
    if (!kIsWeb && Platform.isMacOS) return true;
    return false;
  }

  Future<void> _handleLogin(
      BuildContext context, Future<bool> Function() loginMethod) async {
    final success = await loginMethod();
    if (success && context.mounted) {
      // Navigation is handled by auth state listener in main.dart
    }
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final String? iconPath;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.label,
    this.iconPath,
    this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 28, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
