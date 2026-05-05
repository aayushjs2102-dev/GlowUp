import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AppTranslations {
  static final ValueNotifier<String> currentLanguage = ValueNotifier('English');
  static const String _prefsKey = 'cached_translations';

  static String tr(String key) {
    final lang = currentLanguage.value;
    final map = _translations[lang] ?? _translations['English']!;
    return map[key] ?? _translations['English']![key] ?? key;
  }

  // Allow mutation for dynamic languages
  static Map<String, Map<String, String>> _translations = {
    'English': {
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'EMAIL',
      'password': 'PASSWORD',
      'signin': 'Sign In',
      'create_account': 'Create Account',
      'no_account': "Don't have an account?",
      'have_account': 'Already have an account?',
      'auth_error': 'Authentication failed.',
      'fill_fields': 'Please fill all fields',
      'conn_error': 'Connection error. Is the backend running?',
      'profile_title': 'Complete Your Profile',
      'profile_subtitle': 'Help us personalize your wellness analysis',
      'age': 'AGE',
      'height': 'HEIGHT (CM)',
      'weight': 'WEIGHT (KG)',
      'pref_lang': 'PREFERRED LANGUAGE',
      'continue_dash': 'Continue to Dashboard →',
      'error_saving': 'Error saving profile: ',
      'app_title': '✦ GlowUp',
      'selfie_analysis': 'Selfie Analysis',
      'upload_subtitle': 'Upload a selfie for AI-powered cosmetic wellness insights',
      'tap_change': 'Tap to change photo',
      'tap_upload': 'Tap to upload a selfie',
      'camera_gallery': 'Camera or Gallery • JPEG, PNG, WebP',
      'take_selfie': 'Take a Selfie',
      'use_camera': 'Use your camera',
      'choose_gallery': 'Choose from Gallery',
      'select_photo': 'Select an existing photo',
      'analyze_btn': '✦ Analyze Selfie',
      'analyzing': 'Analyzing…',
      'running_ai': 'Running local AI model — this may take 15-30 seconds…',
      'analysis_summary': 'Analysis Summary',
      'lifestyle_advice': 'Lifestyle Advice',
      'product_recs': 'Product Recommendations',
      'lang_updated': 'Language updated for next analysis',
      'lang_failed': 'Failed to update language: ',
      'logout': 'Logout'
    },
    'Hindi': {
      'login': 'लॉग इन',
      'signup': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'signin': 'साइन इन करें',
      'create_account': 'खाता बनाएं',
      'no_account': 'खाता नहीं है?',
      'have_account': 'पहले से ही खाता है?',
      'auth_error': 'प्रमाणीकरण विफल रहा।',
      'fill_fields': 'कृपया सभी फ़ील्ड भरें',
      'conn_error': 'कनेक्शन त्रुटि। क्या सर्वर चल रहा है?',
      'profile_title': 'अपनी प्रोफ़ाइल पूरी करें',
      'profile_subtitle': 'आपके विश्लेषण को निजीकृत करने में हमारी सहायता करें',
      'age': 'आयु',
      'height': 'ऊंचाई (सेमी)',
      'weight': 'वजन (किलो)',
      'pref_lang': 'पसंदीदा भाषा',
      'continue_dash': 'डैशबोर्ड पर जारी रखें →',
      'error_saving': 'प्रोफ़ाइल सहेजने में त्रुटि: ',
      'app_title': '✦ ग्लोअप',
      'selfie_analysis': 'सेल्फी विश्लेषण',
      'upload_subtitle': 'एआई-संचालित कॉस्मेटिक कल्याण अंतर्दृष्टि के लिए एक सेल्फी अपलोड करें',
      'tap_change': 'फोटो बदलने के लिए टैप करें',
      'tap_upload': 'सेल्फी अपलोड करने के लिए टैप करें',
      'camera_gallery': 'कैमरा या गैलरी • JPEG, PNG, WebP',
      'take_selfie': 'सेल्फी लें',
      'use_camera': 'अपने कैमरे का उपयोग करें',
      'choose_gallery': 'गैलरी से चुनें',
      'select_photo': 'एक मौजूदा फोटो चुनें',
      'analyze_btn': '✦ सेल्फी का विश्लेषण करें',
      'analyzing': 'विश्लेषण हो रहा है…',
      'running_ai': 'स्थानीय एआई मॉडल चल रहा है — इसमें 15-30 सेकंड लग सकते हैं…',
      'analysis_summary': 'विश्लेषण सारांश',
      'lifestyle_advice': 'जीवन शैली सलाह',
      'product_recs': 'उत्पाद सिफारिशें',
      'lang_updated': 'अगले विश्लेषण के लिए भाषा अपडेट की गई',
      'lang_failed': 'भाषा अपडेट करने में विफल: ',
      'logout': 'लॉग आउट'
    },
    'Malayalam': {
      'login': 'ലോഗിൻ',
      'signup': 'സൈൻ അപ്പ്',
      'email': 'ഇമെയിൽ',
      'password': 'പാസ്‌വേഡ്',
      'signin': 'സൈൻ ഇൻ ചെയ്യുക',
      'create_account': 'അക്കൗണ്ട് സൃഷ്ടിക്കുക',
      'no_account': 'അക്കൗണ്ട് ഇല്ലേ?',
      'have_account': 'ഇതിനകം അക്കൗണ്ട് ഉണ്ടോ?',
      'auth_error': 'ആധികാരികത ഉറപ്പാക്കുന്നതിൽ പരാജയപ്പെട്ടു.',
      'fill_fields': 'എല്ലാ ഫീൽഡുകളും പൂരിപ്പിക്കുക',
      'conn_error': 'കണക്ഷൻ പിശക്. സെർവർ പ്രവർത്തിക്കുന്നുണ്ടോ?',
      'profile_title': 'നിങ്ങളുടെ പ്രൊഫൈൽ പൂർത്തിയാക്കുക',
      'profile_subtitle': 'നിങ്ങളുടെ വിശകലനം വ്യക്തിഗതമാക്കാൻ ഞങ്ങളെ സഹായിക്കുക',
      'age': 'പ്രായം',
      'height': 'ഉയരം (CM)',
      'weight': 'ഭാരം (KG)',
      'pref_lang': 'തിരഞ്ഞെടുത്ത ഭാഷ',
      'continue_dash': 'ഡാഷ്‌ബോർഡിലേക്ക് തുടരുക →',
      'error_saving': 'പ്രൊഫൈൽ സംരക്ഷിക്കുന്നതിൽ പിശക്: ',
      'app_title': '✦ ഗ്ലോഅപ്പ്',
      'selfie_analysis': 'സെൽഫി വിശകലനം',
      'upload_subtitle': 'എഐ കോസ്മെറ്റിക് വെൽനസ് വിശകലനത്തിനായി ഒരു സെൽഫി അപ്‌ലോഡ് ചെയ്യുക',
      'tap_change': 'ഫോട്ടോ മാറ്റാൻ ടാപ്പ് ചെയ്യുക',
      'tap_upload': 'സെൽഫി അപ്‌ലോഡ് ചെയ്യാൻ ടാപ്പ് ചെയ്യുക',
      'camera_gallery': 'ക്യാമറ അല്ലെങ്കിൽ ഗാലറി • JPEG, PNG, WebP',
      'take_selfie': 'ഒരു സെൽഫി എടുക്കുക',
      'use_camera': 'നിങ്ങളുടെ ക്യാമറ ഉപയോഗിക്കുക',
      'choose_gallery': 'ഗാലറിയിൽ നിന്ന് തിരഞ്ഞെടുക്കുക',
      'select_photo': 'നിലവിലുള്ള ഒരു ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
      'analyze_btn': '✦ സെൽഫി വിശകലനം ചെയ്യുക',
      'analyzing': 'വിശകലനം ചെയ്യുന്നു…',
      'running_ai': 'ലോക്കൽ എഐ മോഡൽ പ്രവർത്തിക്കുന്നു — ഇതിന് 15-30 സെക്കൻഡ് എടുത്തേക്കാം…',
      'analysis_summary': 'വിശകലന സംഗ്രഹം',
      'lifestyle_advice': 'ജീവിതശൈലി ഉപദേശം',
      'product_recs': 'ഉൽപ്പന്ന ശുപാർശകൾ',
      'lang_updated': 'അടുത്ത വിശകലനത്തിനായി ഭാഷ അപ്‌ഡേറ്റുചെയ്‌തു',
      'lang_failed': 'ഭാഷ അപ്‌ഡേറ്റുചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു: ',
      'logout': 'ലോഗൗട്ട്'
    },
    'Tamil': {
      'login': 'உள்நுழைக',
      'signup': 'பதிவு செய்க',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'signin': 'உள்நுழையவும்',
      'create_account': 'கணக்கை உருவாக்கு',
      'no_account': 'கணக்கு இல்லையா?',
      'have_account': 'ஏற்கனவே கணக்கு உள்ளதா?',
      'auth_error': 'அங்கீகாரம் தோல்வியடைந்தது.',
      'fill_fields': 'அனைத்து புலங்களையும் நிரப்பவும்',
      'conn_error': 'இணைப்பு பிழை. சேவையகம் இயங்குகிறதா?',
      'profile_title': 'உங்கள் சுயவிவரத்தை முடிக்கவும்',
      'profile_subtitle': 'உங்கள் பகுப்பாய்வை தனிப்பயனாக்க எங்களுக்கு உதவுங்கள்',
      'age': 'வயது',
      'height': 'உயரம் (CM)',
      'weight': 'எடை (KG)',
      'pref_lang': 'விருப்பமான மொழி',
      'continue_dash': 'டாஷ்போர்டுக்கு தொடரவும் →',
      'error_saving': 'சுயவிவரத்தை சேமிப்பதில் பிழை: ',
      'app_title': '✦ குளோஅப்',
      'selfie_analysis': 'செல்ஃபி பகுப்பாய்வு',
      'upload_subtitle': 'ஏஐ ஒப்பனை ஆரோக்கிய நுண்ணறிவுகளுக்கு செல்ஃபியை பதிவேற்றவும்',
      'tap_change': 'புகைப்படத்தை மாற்ற தட்டவும்',
      'tap_upload': 'செல்ஃபியைப் பதிவேற்ற தட்டவும்',
      'camera_gallery': 'கேமரா அல்லது கேலரி • JPEG, PNG, WebP',
      'take_selfie': 'ஒரு செல்ஃபி எடுக்கவும்',
      'use_camera': 'உங்கள் கேமராவைப் பயன்படுத்தவும்',
      'choose_gallery': 'கேலரியில் இருந்து தேர்ந்தெடுக்கவும்',
      'select_photo': 'ஏற்கனவே உள்ள புகைப்படத்தைத் தேர்ந்தெடுக்கவும்',
      'analyze_btn': '✦ செல்ஃபியை பகுப்பாய்வு செய்க',
      'analyzing': 'பகுப்பாய்வு செய்கிறது…',
      'running_ai': 'உள்ளூர் ஏஐ மாதிரி இயங்குகிறது — இதற்கு 15-30 வினாடிகள் ஆகலாம்…',
      'analysis_summary': 'பகுப்பாய்வு சுருக்கம்',
      'lifestyle_advice': 'வாழ்க்க முறை ஆலோசனை',
      'product_recs': 'தயாரிப்பு பரிந்துரைகள்',
      'lang_updated': 'அடுத்த பகுப்பாய்விற்காக மொழி புதுப்பிக்கப்பட்டது',
      'lang_failed': 'மொழியைப் புதுப்பிப்பதில் தோல்வி: ',
      'logout': 'வெளியேறு'
    }
  };

  /// Load cached languages from local storage
  static Future<void> loadCachedTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        decoded.forEach((lang, translations) {
          if (!_translations.containsKey(lang)) {
            _translations[lang] = Map<String, String>.from(translations);
          }
        });
      } catch (e) {
        debugPrint('Failed to load cached translations: $e');
      }
    }
  }

  /// Ensure language is available. If not, download from backend and cache.
  static Future<void> ensureLanguage(String targetLang) async {
    if (_translations.containsKey(targetLang)) return;
    
    try {
      final baseEnglish = _translations['English']!;
      final translated = await ApiService.translateUI(baseEnglish, targetLang);
      
      _translations[targetLang] = translated;
      
      // Save cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_translations));
      
      // Trigger rebuild
      if (currentLanguage.value == targetLang) {
        currentLanguage.value = ''; // Force notification
        currentLanguage.value = targetLang;
      }
    } catch (e) {
      debugPrint('Error translating language $targetLang: $e');
      throw Exception('Failed to load language');
    }
  }
}
