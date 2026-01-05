# bloom 🌸

**bloom** is a modern, AI-powered mental health and wellness companion built with Flutter. It helps users track their emotional well-being through mood logging, journaling, and guided breathing exercises, while providing a supportive AI-driven chat experience.

## ✨ Key Features

-   **🤖 AI Mental Health Chat**: Engage in supportive and empathetic conversations with an AI assistant powered by Google Gemini.
-   **📊 Mood Tracking & Trends**: Log your daily mood and visualize patterns over time with interactive charts (powered by `fl_chart`).
-   **📓 Secure Journaling**: A private space to record your thoughts and reflections, stored locally for privacy.
-   **🧘 Breathing Exercises**: Guided breathing sessions to help reduce stress and improve focus.
-   **🆘 Emergency Support**: Quick access to mental health resources and emergency contacts.
-   **🎨 Personalization**: Tailored experience based on user details (age, gender, etc.) collected during onboarding.

## 🛠️ Technology Stack

-   **Framework**: [Flutter](https://flutter.dev/) (Cross-platform UI toolkit)
-   **Language**: [Dart](https://dart.dev/)
-   **AI Engine**: [Google Gemini AI](https://ai.google.dev/) (via `firebase_ai` and `flutter_ai_toolkit`)
-   **Backend/Cloud**: [Firebase](https://firebase.google.com/) (Core services)
-   **Local Database**: [Hive](https://docs.hivedb.dev/) (NoSQL database for local storage)
-   **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
-   **Animations**: [Lottie](https://pub.dev/packages/lottie) & [Liquid Swipe](https://pub.dev/packages/liquid_swipe)
-   **Icons**: [Bootstrap Icons](https://pub.dev/packages/bootstrap_icons) & [Cupertino Icons](https://pub.dev/packages/cupertino_icons)

## 📁 Project Structure

```text
lib/
├── constants/         # App-wide constants and theme configurations
├── data/              # Static data and assets references
├── models/            # Data models and Hive TypeAdapters (Mood, User, Chat, etc.)
├── presentation/      # UI components and screen implementations
├── screens/           # Main application screens (Dashboard, Chat, Journal, etc.)
├── services/          # Business logic and external services (DB, Gemini, Connectivity)
├── widgets/           # Reusable custom widgets
└── main.dart          # Application entry point and initialization logic
```

## 🚀 Getting Started

### Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
-   [Dart SDK](https://dart.dev/get-started/sdk)
-   Android Studio / VS Code with Flutter extensions

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Florastein/bloom.git
    cd bloom
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Hive adapters:**
    If you modify any models, run the build runner to generate TypeAdapters:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

## 🔐 Privacy & Security

Bloom prioritizes user privacy. Most data, including journal entries and mood logs, are stored locally on your device using Hive. AI interactions leverage Firebase and Gemini, ensuring a modern and responsive experience.

## 📄 License

This project is for private use and is not intended for public distribution on `pub.dev`.
