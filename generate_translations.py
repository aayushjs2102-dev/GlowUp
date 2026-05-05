import urllib.request
import urllib.parse
import json
import time

url_langs = 'https://translate.googleapis.com/translate_a/l?client=gtx'
req = urllib.request.Request(url_langs, headers={'User-Agent': 'Mozilla/5.0'})
resp = urllib.request.urlopen(req)
langs_data = json.loads(resp.read().decode('utf-8'))
langs = langs_data['tl']

strings_to_translate = {
    'email_label': 'EMAIL',
    'pass_label': 'PASSWORD',
    'name_label': 'FULL NAME',
    'sign_in': 'Sign In',
    'sign_up': 'Create Account',
    'no_account': 'Don\'t have an account?',
    'have_account': 'Already have an account?',
    'auth_error': 'Authentication failed.',
    'fill_fields': 'Please fill all fields',
    'error_saving': 'Error saving profile: ',
    'profile_title': 'Complete Your Profile',
    'profile_subtitle': 'Help us personalize your wellness analysis',
    'age': 'AGE',
    'height': 'HEIGHT (CM)',
    'weight': 'WEIGHT (KG)',
    'pref_lang': 'PREFERRED LANGUAGE',
    'continue_dash': 'Continue to Dashboard →',
    'lang_updated': 'Language updated for next analysis',
    'lang_failed': 'Failed to update language: ',
    'conn_error': 'Connection error. Is the backend running?',
    'logout': 'Logout',
    'selfie_analysis': 'Selfie Analysis',
    'upload_subtitle': 'Upload a selfie for AI-powered cosmetic wellness insights',
    'analyze_btn': '✦ Analyze Selfie',
    'analyzing': 'Analyzing…',
    'running_ai': 'Running local AI model — this may take 15-30 seconds…',
    'analysis_summary': 'Analysis Summary',
    'lifestyle_advice': 'Lifestyle Advice',
    'product_recs': 'Product Recommendations',
    'tap_change': 'Tap to change photo',
    'tap_upload': 'Tap to upload a selfie',
    'camera_gallery': 'Camera or Gallery • JPEG, PNG, WebP',
    'take_selfie': 'Take a Selfie',
    'use_camera': 'Use your camera',
    'choose_gallery': 'Choose from Gallery',
    'select_photo': 'Select an existing photo'
}

keys = list(strings_to_translate.keys())
values = list(strings_to_translate.values())
joined_text = "\n".join(values)

result = {}

test_langs = list(langs.items())[:3]

for code, name in test_langs:
    try:
        url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=' + code + '&dt=t&q=' + urllib.parse.quote(joined_text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        res = urllib.request.urlopen(req)
        data = json.loads(res.read().decode('utf-8'))
        
        translated_values = []
        for d in data[0]:
            if d[0] is not None:
                translated_values.extend([s.strip() for s in d[0].split('\n') if s.strip()])
                
        if len(translated_values) == len(keys):
            result[name] = dict(zip(keys, translated_values))
            print(f"Success: {name}")
        else:
            print(f"Failed parsing {name}: len {len(translated_values)} vs {len(keys)}")
            print(translated_values)
            
        time.sleep(0.5)
    except Exception as e:
        print(f"Error {name}: {e}")

