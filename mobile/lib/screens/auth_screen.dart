import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import '../l10n/app_translations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _isLogin => _tabCtrl.index == 0;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_isLogin) {
        await ApiService.register(email: email, password: pass);
      }
      await ApiService.login(email: email, password: pass);

      if (!mounted) return;
      try {
        final profile = await ApiService.getMe();
        if (!mounted) return;
        if (profile['age'] != null && profile['height_cm'] != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppTranslations.tr('conn_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ──
                ShaderMask(
                  shaderCallback: (bounds) =>
                      context.glowColors.primaryGradient.createShader(bounds),
                  child: Text(
                    '✦ GlowUp',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-Powered Cosmetic Wellness',
                  style: TextStyle(
                    color: context.glowColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Glass card ──
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: context.glowColors.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: BoxDecoration(
                            gradient: context.glowColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: context.glowColors.textMuted,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(text: AppTranslations.tr('login')),
                            Tab(text: AppTranslations.tr('signup')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Fields
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: context.glowColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: AppTranslations.tr('email'),
                          hintText: 'you@example.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: context.glowColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: context.glowColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: AppTranslations.tr('password'),
                          hintText: '••••••••',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: context.glowColors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: context.glowColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.glowColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.glowColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: context.glowColors.error,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit
                      GradientButton(
                        onPressed: _loading ? null : _submit,
                        loading: _loading,
                        label: _isLogin ? AppTranslations.tr('signin') : AppTranslations.tr('create_account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
