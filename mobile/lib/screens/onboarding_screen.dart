import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import '../l10n/app_translations.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _language = 'English';

  List<String> _languages = ['English', 'Hindi', 'Malayalam', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await ApiService.getLanguages();
      if (mounted) setState(() => _languages = langs);
    } catch (_) {}
  }

  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final age = int.tryParse(_ageCtrl.text.trim());
      final height = double.tryParse(_heightCtrl.text.trim());
      final weight = double.tryParse(_weightCtrl.text.trim());

      await ApiService.updateProfile(
        age: age,
        heightCm: height,
        weightKg: weight,
        preferredLanguage: _language,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('age', _ageCtrl.text.trim());
      await prefs.setString('height', _heightCtrl.text.trim());
      await prefs.setString('weight', _weightCtrl.text.trim());
      await prefs.setString('preferredLanguage', _language);
      
      await AppTranslations.ensureLanguage(_language);
      AppTranslations.currentLanguage.value = _language;

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.tr('error_saving')}$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
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
                // ── Header ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: context.glowColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppTranslations.tr('profile_title'),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: context.glowColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.tr('profile_subtitle'),
                  style: TextStyle(color: context.glowColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 32),

                // ── Glass form ──
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildField(
                        ctrl: _ageCtrl,
                        label: AppTranslations.tr('age'),
                        hint: '25',
                        icon: Icons.cake_outlined,
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        ctrl: _heightCtrl,
                        label: AppTranslations.tr('height'),
                        hint: '170',
                        icon: Icons.height,
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        ctrl: _weightCtrl,
                        label: AppTranslations.tr('weight'),
                        hint: '65',
                        icon: Icons.monitor_weight_outlined,
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Language dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: InputDecoration(
                          labelText: AppTranslations.tr('pref_lang'),
                          prefixIcon: Icon(
                            Icons.language,
                            color: context.glowColors.textMuted,
                            size: 20,
                          ),
                        ),
                        dropdownColor: context.glowColors.surface,
                        style: TextStyle(
                          color: context.glowColors.textPrimary,
                          fontSize: 14,
                        ),
                        items: _languages
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _language = v!),
                      ),
                      const SizedBox(height: 28),

                      _isLoading
                          ? CircularProgressIndicator(color: context.glowColors.accent)
                          : GradientButton(
                              onPressed: _save,
                              label: AppTranslations.tr('continue_dash'),
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

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(color: context.glowColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: context.glowColors.textMuted, size: 20),
      ),
    );
  }
}
