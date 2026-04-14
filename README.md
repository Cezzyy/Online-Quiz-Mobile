# ACLC Online Quiz Application

A comprehensive Flutter mobile application designed for ACLC students to take online quizzes and track their academic progress.

## 📱 Features

### ✅ Implemented
- **Onboarding Flow**: Welcome slides with app introduction
- **Authentication**: 
  - Login screen with form validation
  - Biometric authentication (fingerprint/face recognition)
  - Session management with auto-lock on app background
- **Dashboard**: Home tab with quick stats and recent activity
- **Course Management**: 
  - Browse enrolled courses
  - View detailed course information
  - Track course progress
- **Quiz System**: 
  - Browse available quizzes with filters (All, Pending, Completed, Overdue)
  - Detailed quiz information screens
  - **Quiz taking interface with:**
    - Multiple question types (single choice, multiple choice, text)
    - Real-time timer with auto-submit
    - Progress tracking
    - Skeleton loading states
    - Exit protection (auto-submit on exit)
  - Quiz result screens with detailed analytics
- **Results Tracking**: 
  - Performance analytics dashboard
  - Quiz history with scores
  - Detailed answer review
- **User Profile**: 
  - Profile management with personal information
  - Edit profile functionality
  - Emergency contact management
  - Statistics and progress tracking
- **Notifications**: 
  - Local notifications for quiz deadlines
  - Notification center with read/unread status
- **Settings**: 
  - Theme customization (Light/Dark mode)
  - Notification preferences
  - About screen
  - Privacy policy
- **Teacher/Admin Features**:
  - Teacher dashboard with course and quiz management
  - Student performance tracking
  - Quiz creation and management
  - Course analytics
  - Admin dashboard with system overview
- **Analytics & Reporting**:
  - Student performance analytics
  - Quiz statistics and trends
  - Course progress tracking
  - Detailed attempt history
- **Backend Integration**: 
  - Supabase integration for data persistence
  - Real-time data synchronization
- **State Management**: 
  - Riverpod for state management
  - Providers for auth, profile, quiz, and settings

### 🚧 Restrictions
- **Registration Screen**: Currently users are created by admin, no self-registration UI
- **Offline Mode Support**: App requires internet connection for all operations
- **Push Notifications**: Currently using local notifications only
- **Multi-language Support**: Currently English only

## 🏗️ Architecture

### Folder Structure
The project follows a feature-based folder structure for better organization:

```
lib/
├── models/          # Data models (User, Course, Quiz, Question, etc.)
├── providers/       # Riverpod state management providers
├── services/        # Backend services (Supabase, notifications, etc.)
├── screens/         # UI screens organized by feature
│   ├── auth/        # Authentication screens
│   ├── home/        # Main navigation and dashboard
│   ├── courses/     # Course-related screens
│   ├── quizzes/     # Quiz-related screens (browse, take, results)
│   ├── results/     # Results and analytics
│   ├── profile/     # Profile management
│   ├── settings/    # Settings screens
│   └── notifications/ # Notification screens
├── utils/           # Utilities and constants
├── widgets/         # Reusable UI components
└── config/          # Configuration files (Supabase, etc.)
```

## 🎨 Design System

### Color Scheme
- **Primary**: #1565C0 (University Blue)
- **Secondary**: #0D47A1 (Dark Blue)
- **Accent**: #42A5F5 (Light Blue)
- **Success**: #43A047 (Green)
- **Error**: #E53935 (Red)

### UI/UX Features
- Material Design 3 theming
- Consistent university branding
- Responsive design with skeleton loaders
- Custom reusable widgets
- Intuitive navigation flow
- Bottom sheets for confirmations
- Gradient headers for visual hierarchy

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator
- Supabase account (for backend)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd online_quiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   - Create a `.env` file in the root directory
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Development Setup

1. **Check Flutter installation**
   ```bash
   flutter doctor
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

3. **Build for production**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

## 📱 Navigation Flow (Student)

```
Splash Screen → Onboarding (first time) → Login Screen → Biometric Lock → Main Screen
                                                                              ├── Home Tab
                                                                              ├── Courses Tab → Course Details
                                                                              ├── Quiz Tab → Quiz Details → Quiz Screen → Quiz Results
                                                                              ├── Results Tab → Quiz Results
                                                                              └── Profile Tab → Edit Profile/Settings
```

## 🔧 Technical Stack

- **Framework**: Flutter
- **Language**: Dart
- **UI**: Material Design 3
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL)
- **Local Storage**: Shared Preferences
- **Authentication**: Supabase Auth + Local Biometrics
- **Notifications**: Flutter Local Notifications

## 📋 Current Status

The application is in **production-ready state** with:
- ✅ Complete UI implementation for all major screens
- ✅ Full navigation flow between screens
- ✅ Backend integration with Supabase
- ✅ State management with Riverpod
- ✅ Authentication with biometric support
- ✅ Quiz taking functionality with timer
- ✅ Results tracking and analytics
- ✅ Profile management
- ✅ Notification system
- ✅ Teacher/Admin features

## 🔐 Security Features

- Biometric authentication (fingerprint/face recognition)
- Auto-lock on app background
- Session management
- Secure quiz taking (no exit without submit)
- Authentication required for quiz start

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions, please contact the development team or create an issue in the repository.

---

**Note**: This application uses Supabase as the backend service. Ensure you have proper database setup and credentials configured before running the application.
