import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'l10n/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await AppTranslations.loadCachedTranslations();
  final savedLang = prefs.getString('preferredLanguage') ?? 'English';
  AppTranslations.currentLanguage.value = savedLang;
  
  await AppThemeNotifier.load();

  // Force dark status bar icons on dark background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const GlowUpApp());
}

class GlowUpApp extends StatelessWidget {
  const GlowUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLanguage,
      builder: (context, lang, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeNotifier.themeMode,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'GlowUp',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: buildGlowTheme(Brightness.light),
              darkTheme: buildGlowTheme(Brightness.dark),
              home: const _EntryGate(),
            );
          },
        );
      },
    );
  }
}

/// Checks for an existing JWT and routes accordingly.
class _EntryGate extends StatefulWidget {
  const _EntryGate();

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final token = await ApiService.getToken();
    if (!mounted) return;

    Widget dest;
    if (token != null) {
      try {
        await ApiService.getMe();
        dest = const DashboardScreen();
      } catch (_) {
        await ApiService.clearToken();
        dest = const AuthScreen();
      }
    } else {
      dest = const AuthScreen();
    }

    if (mounted) {
      setState(() => _destination = dest);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_destination != null) {
      // Navigate after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _destination != null) {
          final dest = _destination!;
          _destination = null;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => dest),
            (_) => false,
          );
        }
      });
    }

    // Splash-like loading while checking auth
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  context.glowColors.primaryGradient.createShader(b),
              child: Icon(Icons.auto_awesome, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.glowColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
