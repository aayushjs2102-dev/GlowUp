import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API client for the GlowUp FastAPI backend.
class ApiService {
  /// Base URL – override with the host's LAN IP for physical devices.
  /// Android emulator uses 10.0.2.2 to reach the host loopback.
  static String get baseUrl {
    // Overridden with the local WiFi IP address so physical devices 
    // can securely connect to the backend running on the host machine.
    return 'http://192.168.1.38:8000';
  }

  // ──────────────────────── Token helpers ────────────────────────

  static const _tokenKey = 'glowup_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ──────────────────────── Auth ────────────────────────

  /// Register a new user.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(body['detail'] ?? 'Registration failed');
    }
    return body;
  }

  /// Login and receive a JWT.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw ApiException(body['detail'] ?? 'Login failed');
    }
    final token = body['access_token'] as String;
    await saveToken(token);
    return token;
  }

  /// Get the current user's profile.
  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated');

    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) {
      await clearToken();
      throw ApiException('Session expired');
    }
    return jsonDecode(res.body);
  }

  /// Update user profile (age, height, weight, language).
  static Future<Map<String, dynamic>> updateProfile({
    int? age,
    double? heightCm,
    double? weightKg,
    String? preferredLanguage,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated');

    final body = <String, dynamic>{};
    if (age != null) body['age'] = age;
    if (heightCm != null) body['height_cm'] = heightCm;
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (preferredLanguage != null) body['preferred_language'] = preferredLanguage;

    final res = await http.patch(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      await clearToken();
      throw ApiException('Session expired');
    }
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ApiException(err['detail'] ?? 'Profile update failed');
    }
    return jsonDecode(res.body);
  }
  // ──────────────────────── Localization ────────────────────────

  /// Fetch all supported languages from the backend.
  static Future<List<String>> getLanguages() async {
    final res = await http.get(Uri.parse('$baseUrl/languages'));
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch languages');
    }
    return List<String>.from(jsonDecode(res.body));
  }

  /// Translate a dictionary of UI strings via backend.
  static Future<Map<String, String>> translateUI(
    Map<String, String> strings,
    String targetLanguage,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/translate_ui'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target_language': targetLanguage,
        'strings': strings,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException('Translation failed');
    }
    return Map<String, String>.from(jsonDecode(res.body));
  }

  // ──────────────────────── Selfie Analysis ────────────────────────

  /// Upload a selfie image and get AI analysis results.
  static Future<Map<String, dynamic>> analyzeSelfie(File imageFile) async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze-selfie'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    // Detect MIME type from file extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'heic': 'image/jpeg', // HEIC from iOS → treat as JPEG
    };
    final mimeType = mimeMap[ext] ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(minutes: 3), // LLaVA can take a while locally
    );
    final resBody = await streamed.stream.bytesToString();

    if (streamed.statusCode == 401) {
      await clearToken();
      throw ApiException('Session expired');
    }
    if (streamed.statusCode != 200) {
      final err = jsonDecode(resBody);
      throw ApiException(err['detail'] ?? 'Analysis failed');
    }
    return jsonDecode(resBody);
  }
}

/// Simple exception wrapper for API errors.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
