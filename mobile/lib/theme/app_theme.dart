import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme state manager
class AppThemeNotifier {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool('isLightMode') ?? false;
    themeMode.value = isLight ? ThemeMode.light : ThemeMode.dark;
  }

  static Future<void> toggle() async {
    final isLight = themeMode.value == ThemeMode.light;
    themeMode.value = isLight ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightMode', !isLight);
  }
}

/// ThemeExtension to define custom colors cleanly
class GlowThemeExtension extends ThemeExtension<GlowThemeExtension> {
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color success;
  final Color error;
  final Color amazon;
  final Color flipkart;
  final LinearGradient primaryGradient;
  final bool isLight;

  const GlowThemeExtension({
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.success,
    required this.error,
    required this.amazon,
    required this.flipkart,
    required this.primaryGradient,
    required this.isLight,
  });

  @override
  GlowThemeExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? accent,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? success,
    Color? error,
    Color? amazon,
    Color? flipkart,
    LinearGradient? primaryGradient,
    bool? isLight,
  }) {
    return GlowThemeExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      error: error ?? this.error,
      amazon: amazon ?? this.amazon,
      flipkart: flipkart ?? this.flipkart,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      isLight: isLight ?? this.isLight,
    );
  }

  @override
  GlowThemeExtension lerp(ThemeExtension<GlowThemeExtension>? other, double t) {
    if (other is! GlowThemeExtension) return this;
    return GlowThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      amazon: Color.lerp(amazon, other.amazon, t)!,
      flipkart: Color.lerp(flipkart, other.flipkart, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      isLight: t < 0.5 ? isLight : other.isLight,
    );
  }
}

extension GlowContext on BuildContext {
  GlowThemeExtension get glowColors => Theme.of(this).extension<GlowThemeExtension>()!;
}

final _darkGlow = GlowThemeExtension(
  primary: const Color(0xFF4F46E5),      
  primaryLight: const Color(0xFF818CF8), 
  accent: const Color(0xFF06B6D4),       
  bg: const Color(0xFF0A0C10),           
  surface: const Color(0xFF12141A),      
  surface2: const Color(0xFF1C1F26),     
  border: const Color(0xFF2A2D3A),
  textPrimary: const Color(0xFFF3F4F6),  
  textMuted: const Color(0xFF9CA3AF),    
  success: const Color(0xFF10B981),      
  error: const Color(0xFFF43F5E),        
  amazon: const Color(0xFFFF9900),
  flipkart: const Color(0xFF2874F0),
  primaryGradient: const LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
  ),
  isLight: false,
);

final _lightGlow = GlowThemeExtension(
  primary: const Color(0xFF4338CA),      
  primaryLight: const Color(0xFF6366F1), 
  accent: const Color(0xFF0891B2),       
  bg: const Color(0xFFF9FAFB),           
  surface: const Color(0xFFFFFFFF),      
  surface2: const Color(0xFFF3F4F6),     
  border: const Color(0xFFE5E7EB),
  textPrimary: const Color(0xFF111827),  
  textMuted: const Color(0xFF6B7280),    
  success: const Color(0xFF10B981),      
  error: const Color(0xFFE11D48),        
  amazon: const Color(0xFFFF9900),
  flipkart: const Color(0xFF2874F0),
  primaryGradient: const LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF0891B2)],
  ),
  isLight: true,
);

ThemeData buildGlowTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final base = isLight ? ThemeData.light(useMaterial3: true) : ThemeData.dark(useMaterial3: true);
  final glow = isLight ? _lightGlow : _darkGlow;

  return base.copyWith(
    scaffoldBackgroundColor: glow.bg,
    extensions: [glow],
    colorScheme: (isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
      primary: glow.primary,
      secondary: glow.accent,
      surface: glow.surface,
      error: glow.error,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: glow.textPrimary,
      displayColor: glow.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: glow.bg.withValues(alpha: 0.85),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: glow.textPrimary),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: glow.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glow.surface.withValues(alpha: isLight ? 0.8 : 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: glow.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: glow.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: glow.accent, width: 1.5),
      ),
      hintStyle: TextStyle(color: glow.textMuted, fontSize: 14),
      labelStyle: TextStyle(
        color: glow.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.height,
    this.width,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final glow = context.glowColors;
    
    return Container(
      margin: margin,
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glow.isLight 
                ? glow.primary.withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glow.isLight 
                  ? Colors.white.withValues(alpha: 0.7) 
                  : glow.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: glow.isLight 
                    ? Colors.white.withValues(alpha: 0.8) 
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glow.isLight
                    ? [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.5),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final glow = context.glowColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : glow.primaryGradient,
        color: onPressed == null ? glow.surface2 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: glow.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
