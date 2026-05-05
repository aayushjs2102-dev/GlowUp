import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../l10n/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  File? _image;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  final _picker = ImagePicker();
  
  late AnimationController _scannerCtrl;

  List<String> _languages = ['English', 'Hindi', 'Malayalam', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _scannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _checkAuth();
    _loadLanguages();
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await ApiService.getLanguages();
      if (mounted) setState(() => _languages = langs);
    } catch (_) {}
  }

  Future<void> _checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getMe();
      if (mounted) {
        setState(() {
          final lang = profile['preferred_language'] as String?;
          if (lang != null) {
            AppTranslations.ensureLanguage(lang).then((_) {
              if (mounted) setState(() {});
            });
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _updateLanguage(String lang) async {
    setState(() => _loading = true);
    try {
      await AppTranslations.ensureLanguage(lang);
      
      AppTranslations.currentLanguage.value = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferredLanguage', lang);

      // Update backend profile without waiting for UI
      ApiService.updateProfile(preferredLanguage: lang).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslations.tr('lang_updated'))),
          );
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppTranslations.tr('lang_failed')}$e')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load language translations')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await ApiService.analyzeSelfie(_image!);
      setState(() => _result = data);
    } on ApiException catch (e) {
      if (e.message.contains('expired') || e.message.contains('authenticated')) {
        await ApiService.clearToken();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
          );
        }
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppTranslations.tr('conn_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => context.glowColors.primaryGradient.createShader(b),
          child: Text(
            '✦ GlowUp',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: context.glowColors.textMuted),
            color: context.glowColors.surface,
            tooltip: AppTranslations.tr('pref_lang'),
            onSelected: _updateLanguage,
            itemBuilder: (BuildContext context) {
              return _languages.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: TextStyle(
                      color: choice == AppTranslations.currentLanguage.value 
                          ? context.glowColors.primary 
                          : context.glowColors.textPrimary,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppThemeNotifier.themeMode,
            builder: (context, mode, child) {
              final isLight = mode == ThemeMode.light;
              return IconButton(
                icon: Icon(
                  isLight ? Icons.dark_mode : Icons.light_mode,
                  color: context.glowColors.textMuted,
                ),
                onPressed: AppThemeNotifier.toggle,
                tooltip: isLight ? 'Dark Mode' : 'Light Mode',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.logout, color: context.glowColors.textMuted),
            onPressed: _logout,
            tooltip: AppTranslations.tr('logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Text(
                AppTranslations.tr('selfie_analysis'),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  foreground: Paint()
                    ..shader = context.glowColors.primaryGradient
                        .createShader(const Rect.fromLTWH(0, 0, 250, 40)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.tr('upload_subtitle'),
                style: TextStyle(color: context.glowColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Image Area ──
              _buildImageArea(),
              const SizedBox(height: 20),

              // ── Analyze Button ──
              GradientButton(
                onPressed: _image != null && !_loading ? _analyze : null,
                loading: _loading,
                label: _loading ? AppTranslations.tr('analyzing') : AppTranslations.tr('analyze_btn'),
              ),

              if (_loading) ...[
                const SizedBox(height: 12),
                Text(
                  AppTranslations.tr('running_ai'),
                  style: TextStyle(color: context.glowColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.glowColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.glowColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: context.glowColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // ── Results ──
              if (_result != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(
                  icon: Icons.analytics_outlined,
                  title: AppTranslations.tr('analysis_summary'),
                  content: _result!['analysis_summary'] ?? '',
                  accent: context.glowColors.primary,
                ),
                const SizedBox(height: 16),
                _buildResultCard(
                  icon: Icons.self_improvement,
                  title: AppTranslations.tr('lifestyle_advice'),
                  content: _result!['lifestyle_advice'] ?? '',
                  accent: context.glowColors.accent,
                ),
                const SizedBox(height: 16),
                _buildProductsSection(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: () => _showImagePickerSheet(),
      child: GlassContainer(
        height: 280,
        borderRadius: 18,
        child: _image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  if (_loading)
                    AnimatedBuilder(
                      animation: _scannerCtrl,
                      builder: (context, child) {
                        return Positioned(
                          top: _scannerCtrl.value * 260, // approximate height scanning
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.glowColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: context.glowColors.accent.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (_loading)
                    Container(
                      color: context.glowColors.primary.withValues(alpha: 0.15),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.tr('tap_change'),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.glowColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: context.glowColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.tr('tap_upload'),
                    style: TextStyle(
                      color: context.glowColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.tr('camera_gallery'),
                    style: TextStyle(color: context.glowColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.glowColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.glowColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.glowColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: context.glowColors.primary),
                ),
                title: Text(
                  AppTranslations.tr('take_selfie'),
                  style: TextStyle(
                    color: context.glowColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  AppTranslations.tr('use_camera'),
                  style: TextStyle(color: context.glowColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.glowColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: context.glowColors.accent),
                ),
                title: Text(
                  AppTranslations.tr('choose_gallery'),
                  style: TextStyle(
                    color: context.glowColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  AppTranslations.tr('select_photo'),
                  style: TextStyle(color: context.glowColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String title,
    required String content,
    required Color accent,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.glowColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              color: context.glowColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    final products =
        _result!['otc_product_recommendations'] as List<dynamic>? ?? [];
    if (products.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.glowColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: context.glowColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.tr('product_recs'),
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.glowColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...products.map((p) => _buildProductTile(p)),
        ],
      ),
    );
  }

  Widget _buildProductTile(dynamic product) {
    final name = product is Map ? (product['product'] ?? '') : '$product';
    final links = product is Map ? product['links'] as Map<String, dynamic>? : null;
    final amazon = links?['amazon_in'] ?? links?['amazon'];
    final flipkart = links?['flipkart'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.glowColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.glowColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: context.glowColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (amazon != null || flipkart != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (amazon != null)
                  Expanded(
                    child: _shopButton(
                      label: 'Amazon',
                      url: amazon,
                      color: context.glowColors.amazon,
                      icon: Icons.shopping_cart_outlined,
                    ),
                  ),
                if (amazon != null && flipkart != null)
                  const SizedBox(width: 10),
                if (flipkart != null)
                  Expanded(
                    child: _shopButton(
                      label: 'Flipkart',
                      url: flipkart,
                      color: context.glowColors.flipkart,
                      icon: Icons.store_outlined,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _shopButton({
    required String label,
    required String url,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
