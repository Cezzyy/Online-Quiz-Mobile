# ACLC Quiz Mobile Application

A comprehensive mobile quiz application built with Flutter for ACLC (AMA Computer Learning Center) students and faculty. This application provides an intuitive platform for creating, managing, and taking quizzes with role-based access control.

## 🚀 Features

### ✅ Implemented Features

#### Authentication & User Management
- **Multi-role Authentication**: Support for Students, Teachers, and Administrators
- **Secure Login System**: Email-based authentication with password protection
- **Role-based Access Control**: Different interfaces and permissions for each user type
- **User Profile Management**: View and edit personal information with contact details
- **Session Management**: Persistent login sessions with secure logout

#### Student Features
- **Dashboard**: Overview of enrolled courses, upcoming quizzes, and recent activities
- **Course Browsing**: View available courses with detailed information
- **Quiz Taking**: Interactive quiz interface with multiple-choice questions
- **Real-time Progress**: Live progress tracking during quiz attempts with timer
- **Results Viewing**: Quiz results with score and performance feedback
- **Notifications**: System notifications for important updates

#### Teacher Features
- **Course Management**: View and manage assigned courses with student statistics
- **Quiz Creation**: Create and manage quizzes with multiple-choice questions
- **Student Management**: View enrolled students with detailed information
- **Results Analytics**: View student quiz attempts and performance data
- **Course Statistics**: Track student enrollment, quiz count, and submission metrics

#### Admin Features
- **System Dashboard**: Overview of platform usage and user statistics
- **User Management**: Monitor system users and their activities
- **Platform Analytics**: System-wide metrics and performance overview

#### Technical Features
- **Dark Mode**: Full dark mode support with automatic theme switching
- **Responsive Design**: Optimized for various screen sizes and orientations
- **State Management**: Efficient state management using Riverpod
- **Mock Data**: Comprehensive sample data for development and testing
- **Modern UI**: Material Design 3 with custom theming and animations

### 🔄 In Development

#### Enhanced Quiz Features
- **Advanced Question Types**: Support for True/False, short answer, and essay questions
- **Time Limits**: Configurable time limits for quizzes
- **Quiz Scheduling**: Set availability windows for quizzes

#### Backend Integration
- **API Integration**: Connect to backend services for data persistence
- **Real-time Sync**: Synchronize data across devices and users
- **File Upload**: Support for image uploads in questions and answers
- **Data Export**: Export quiz results and analytics

#### Enhanced User Experience
- **Push Notifications**: Real-time notifications for quiz availability and deadlines
- **Search & Filter**: Advanced search and filtering for courses and quizzes
- **Bulk Operations**: Import/export capabilities for quiz data

### 📋 Planned Features

#### Advanced Assessment Tools
- **Proctoring Features**: Anti-cheating measures and monitoring tools

#### Analytics & Reporting
- **Learning Analytics**: Detailed insights into learning patterns and progress
- **Performance Trends**: Historical performance tracking and analysis
- **Custom Reports**: Generate custom reports for administrators and teachers
- **Data Visualization**: Interactive charts and graphs for better insights

#### Integration & API
- **RESTful API**: Comprehensive API for third-party integrations

## 🏗️ Architecture

### Folder Structure
The project follows a feature-based folder structure for better organization:

```
lib/
├── screens/          # UI screens organized by feature
│   ├── auth/         # Authentication screens
│   ├── home/         # Dashboard and main screens
│   ├── courses/      # Course-related screens
│   ├── quizzes/      # Quiz-taking screens
│   ├── quiz/         # Quiz management (teacher)
│   ├── results/      # Results and analytics
│   ├── profile/      # User profile screens
│   ├── notifications/# Notification screens
│   ├── settings/     # Settings screens
│   └── onboarding/   # App introduction
├── widgets/          # Reusable UI components
│   ├── custom_text_field.dart
│   ├── dialog.dart
│   ├── empty_state_widget.dart
│   ├── filter_tab_widget.dart
│   ├── info_card.dart
│   └── stat_card.dart
├── models/           # Data models for all entities
│   ├── user.dart
│   ├── course.dart
│   ├── quiz.dart
│   ├── question.dart
│   ├── attempt.dart
│   └── ... (other models)
├── providers/        # Riverpod state management
│   ├── auth_provider.dart
│   ├── course_provider.dart
│   ├── quiz_provider.dart
│   └── ... (other providers)
├── data/             # Data layer
│   └── mock_data.dart
├── utils/            # Utility functions and constants
│   ├── app_theme.dart
│   └── app_routes.dart
└── main.dart         # Application entry point
```

### Key Architecture Principles
- **Separation of Concerns**: Clear separation between UI, business logic, and data
- **State Management**: Centralized state management using Riverpod
- **Reusable Components**: Modular widget design for consistency
- **Role-based Architecture**: Different interfaces for different user types
- **Mock Data Integration**: Comprehensive sample data for development

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
- Responsive design
- Custom reusable widgets
- Intuitive navigation flow

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/Online-Quiz-Mobile.git
   cd Online-Quiz-Mobile/online_quiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Demo Accounts

The application includes mock data with the following test accounts:

**Admin Account:**
- Email: `admin.aclc@quiz.com`
- Password: `admin123`

**Teacher Account:**
- Email: `donald.francisco@university.edu`
- Password: `teacher123`

**Student Account:**
- Email: `jan.rosalijos@student.edu`
- Password: `student123`

### Development Setup

1. **Enable developer options** on your device
2. **Connect your device** via USB or use an emulator
3. **Verify device connection**
   ```bash
   flutter devices
   ```
4. **Run in debug mode**
   ```bash
   flutter run --debug
   ```

### Code Quality

Run code analysis to ensure code quality:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

### Build for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📱 Navigation Flow

### Student Flow
```
Onboarding → Login → Student Dashboard
                ↓
            Main Navigation:
            ├── Home (Dashboard)
            ├── Courses
            ├── Quiz
            ├── Results  
            └── Profile
```

### Teacher Flow
```
Onboarding → Login → Teacher Dashboard
                ↓
            Main Navigation:
            ├── Home (Dashboard)
            ├── Courses (Management)
            ├── Quizzes (Creation)
            ├── Results (Analytics)
            └── Profile
```

### Admin Flow
```
Onboarding → Login → Admin Dashboard
                ↓
            Admin Interface:
            ├── User Management
            ├── System Analytics
            ├── Platform Overview
            └── Settings
```

### Screen Hierarchy
- **Onboarding**: App introduction with ACLC branding
- **Authentication**: Role-based login system
- **Role-based Navigation**: Different interfaces per user type
  - **Student Interface**: Course browsing, quiz taking, results viewing
  - **Teacher Interface**: Course management, quiz creation, student analytics
  - **Admin Interface**: System management and user oversight
- **Shared Features**: Profile management, notifications, settings

## 🛠️ Technical Stack

### Frontend
- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **State Management**: Riverpod 2.6.1
- **UI Components**: Material Design 3
- **Navigation**: Flutter Navigator
- **Local Storage**: SharedPreferences 2.2.2
- **Icons**: Cupertino Icons 1.0.8

### Data Layer
- **Data Models**: Comprehensive model classes for all entities
- **Mock Data**: Sample data for development and testing
- **Providers**: Riverpod providers for state management

### Development Tools
- **IDE**: VS Code / Android Studio
- **Version Control**: Git
- **Testing**: Flutter Test Framework
- **Code Quality**: Flutter Lints 5.0.0
- **Analysis**: Flutter Analyze

### Planned Backend Integration
- **API**: RESTful services
- **Database**: SQL Server
- **Authentication**: JWT tokens
- **File Storage**: Cloud storage for images
- **Real-time**: WebSocket connections

## 📋 Current Status

This project is currently in the **active development phase** with a solid foundation and core features implemented:

✅ **Core Infrastructure**: Complete app architecture with role-based navigation
✅ **Authentication System**: Multi-role login with persistent sessions
✅ **User Interfaces**: Separate interfaces for Students, Teachers, and Admins
✅ **Quiz System**: Full quiz taking functionality with timer and progress tracking
✅ **Course Management**: Course browsing and management for all user types
✅ **Results & Analytics**: Quiz results display and performance tracking
✅ **Profile Management**: User profile viewing and editing capabilities
✅ **State Management**: Comprehensive Riverpod implementation
✅ **Mock Data**: Complete sample data for all features
✅ **Theme System**: Dark/light mode support with Material Design 3

🚧 **In Progress**:
- Backend API integration
- Enhanced quiz question types
- Real-time notifications
- Data export capabilities
- Advanced analytics features

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

**Note**: This application currently uses mock data for demonstration purposes. All screens and functionality are implemented for UI/UX testing and will be connected to a backend service in future iterations.
