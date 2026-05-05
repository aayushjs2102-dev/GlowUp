# ✦ GlowUp

**GlowUp** is an AI-powered cosmetic wellness and skincare application. It analyzes your facial features and skin health using cutting-edge AI models to provide personalized, actionable, and aesthetic wellness routines. 

With a premium glassmorphism UI, dynamic light/dark mode support, and real-time multi-language translation, GlowUp delivers a truly high-end user experience.

![GlowUp Banner](https://img.shields.io/badge/GlowUp-AI_Skincare-indigo?style=for-the-badge)

## ✨ Features
* **AI Skincare Analysis**: Get instant personalized routines and cosmetic recommendations.
* **Premium Dynamic UI**: State-of-the-art Glassmorphism design with seamless system-wide Light and Dark mode switching.
* **Global Translation**: Real-time multi-language support covering all Google Translate languages natively.
* **Secure Authentication**: Encrypted user login, registration, and guest mode capabilities.
* **Cross-Platform**: Built with Flutter for smooth performance across iOS and Android natively.

## 🛠️ Technology Stack
* **Frontend**: Flutter (Dart)
* **Backend**: FastAPI (Python)
* **Database**: SQLite (SQLAlchemy)
* **AI & NLP**: Integrated LLM models for routine generation & Google Translate API for dynamic localization.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites
* [Python 3.9+](https://www.python.org/downloads/)
* [Flutter SDK](https://docs.flutter.dev/get-started/install)

### 1. Setup the Backend
The backend powers the AI generation, user authentication, and data storage.

```bash
# Clone the repository
git clone https://github.com/aayushjs2102-dev/GlowUp.git
cd GlowUp

# Activate virtual environment (if you are using one)
source venv/bin/activate

# Install required Python dependencies
pip install -r requirements.txt

# Start the FastAPI server
# Running on 0.0.0.0 allows physical mobile devices on your local network to connect
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
*The backend will be available at `http://localhost:8000` (or your local IP address `http://192.168.1.x:8000`).*

### 2. Setup the Mobile App
The mobile app handles the UI, Glassmorphism elements, and user interactions.

```bash
# Navigate to the mobile directory
cd mobile

# Fetch Flutter dependencies
flutter pub get

# Run the app on an emulator or connected device
flutter run
```

### 📱 Physical Device Testing (Android APK)
If you wish to test the application on a physical Android device:
1. Ensure your computer and phone are connected to the exact same Wi-Fi network.
2. Ensure the backend is running with the `--host 0.0.0.0` flag.
3. Build the APK by running:
```bash
flutter build apk
```
4. Transfer `mobile/build/app/outputs/flutter-apk/app-release.apk` to your phone and install.

---

## 🎨 Theme Architecture
GlowUp utilizes a custom `ThemeExtension` called `GlowThemeExtension` to provide deeply integrated dynamic colors.
- **Deep Obsidian (Dark)**: Indigo and Cyan gradients cast over deep blacks and semi-transparent dark glass surfaces.
- **Frosted Light (Light)**: Clean, sleek whites and slates overlaid with smooth drop-shadows and vibrant primary accents.

## 🌐 Localization
Languages are dynamically fetched and cached directly from Google Translate's API, meaning GlowUp supports every active Google Translate locale directly from the settings dropdown.

---
**Author:** Aayush
