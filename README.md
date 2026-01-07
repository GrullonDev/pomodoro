# Pomodoro Enfoque ⏱️

![Flutter Version](https://img.shields.io/badge/Flutter-3.38.3-%2302569B?logo=flutter) ![Dart Version](https://img.shields.io/badge/Dart-3.10.x-%230175C2?logo=dart) ![License](https://img.shields.io/badge/license-MIT-green) ![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

**Pomodoro Enfoque** is a productivity application designed to help individuals and teams achieve deep focus cycles using the Pomodoro technique. It combines a clean **Glassmorphism UI** with robust functionality to reinforce sustainable habits.

> "Deep, sustained focus, measured and fed back, turns time into tangible progress."

---

## 📌 Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Tech Stack](#tech-stack)
4. [Architecture](#architecture)
5. [Getting Started](#getting-started)
6. [Folder Structure](#folder-structure)
7. [Screenshots](#screenshots)
8. [Contributing](#contributing)
9. [License](#license)

---

## Project Overview

This project aims to create a focused, pleasant, and extensible productivity tool. It goes beyond a simple timer by integrating metrics, subtle auditory feedback (ticking sounds), and a distraction-free "Glassmorphism" interface.

Recent updates have introduced:
- **Biometric Authentication:** Secure your sessions with Fingerprint/FaceID.
- **Glassmorphism UI:** A modern, frosted-glass aesthetic with animated gradients.
- **Task Management:** Integrate your to-do list directly with your focus sessions.

## Key Features

| Feature | Description | Status |
| :--- | :--- | :---: |
| **Pomodoro Timer** | Customizable work/break intervals with visual progress. | ✅ |
| **Glassmorphism UI** | Modern, premium interface with animated gradients and blur effects. | ✅ |
| **Biometric Auth** | Secure access using device biometrics (Fingerprint/FaceID). | ✅ |
| **Task Management** | Create tasks, estimate sessions, and track progress. | ✅ |
| **Auditory Feedback** | Optional ticking sound and distinct notification tones. | ✅ |
| **Persistent Notification** | Live timer updates in the notification shade. | ✅ |
| **Local History** | Track completed sessions and daily progress locally. | ✅ |
| **Smart Onboarding** | Guided introduction for new users. | ✅ |
| **Dynamic Theming** | Rich, deep teal/ocean gradient themes for better focus. | ✅ |

## Tech Stack

*   **SDK:** Flutter 3.38.3 / Dart 3.10.x
*   **State Management:** `flutter_bloc`
*   **Local Persistence:** `shared_preferences`
*   **Audio:** `audioplayers`
*   **Biometrics:** `local_auth`
*   **Notifications:** `flutter_local_notifications`
*   **Architecture:** Clean Architecture (Domain / Data / Presentation)
*   **Dependency Injection:** Custom Service Locator

## Architecture

The project follows a lightweight **Clean Architecture** principle to ensure scalability and testability.

| Layer | Responsibility | Components |
| :--- | :--- | :--- |
| **Presentation** | UI definition and State Management. | Widgets, Screens, BLoCs (`TimerBloc`) |
| **Domain** | Business Logic and Interfaces. | Entities (`TaskItem`), Use Cases, Repository Interfaces |
| **Data** | Data retrieval and storage. | Repositories (`SessionRepository`), DTOs, Local Sources |
| **Service** | External system integration. | Audio, Notifications, Biometrics |

**Key Principles:**
*   **Separation of Concerns:** UI doesn't know about data sources.
*   **Dependency Inversion:** Use cases depend on interfaces, not implementations.
*   **Testability:** Business logic can be unit tested in isolation.

## Getting Started

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.38.3 recommended via [FVM](https://fvm.app/))
*   Android Studio / VS Code
*   Android Emulator or Physical Device

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/GrullonDev/pomodoro.git
    cd pomodoro
    ```

2.  **Setup Environment (using FVM is recommended):**
    ```bash
    dart pub global activate fvm
    fvm install 3.38.3
    fvm use 3.38.3
    ```

3.  **Install Dependencies:**
    ```bash
    fvm flutter pub get
    ```

4.  **Run the App:**
    ```bash
    fvm flutter run
    ```

## Folder Structure

```
lib/
├── core/
│   ├── auth/           # Biometric and Auth logic
│   ├── data/           # Core Repositories & Data Sources
│   ├── di/             # Dependency Injection Setup
│   ├── domain/         # Core Entities & Use Cases
│   ├── theme/          # Theme logic & Colors
│   └── timer/          # Timer implementation (BLoC & Screen)
├── features/
│   ├── habit/          # Timer Setup & Configuration Screen
│   ├── summary/        # Session Completion Summary
│   └── tasks/          # Task Management Feature
├── l10n/               # Localization (ARB files)
└── utils/              # Shared Widgets (GlassContainer, etc.)
```

## Contributing

We welcome contributions! Please follow these steps to contribute:

1.  **Fork** the repository.
2.  **Create a Branch** for your feature or fix (`git checkout -b feat/amazing-feature`).
3.  **Commit** your changes following conventional commits (`feat: add new timer style`).
4.  **Push** to the branch (`git push origin feat/amazing-feature`).
5.  **Open a Pull Request** targeting the `develop` branch.

### Guidelines
*   Ensure `flutter analyze` passes without errors.
*   Write clean, documented code.
*   Add tests for new business logic.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Developed with ❤️ by Jorge Grullón**
