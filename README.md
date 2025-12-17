# AskUp 📚
srs:
https://docs.google.com/document/d/1p6fkIg9jCMOiuKhdfGftiP_YNYa9kbJLvzdmZuiRncA/edit?usp=sharing
AskUp is a lightweight classroom interaction tool built for lectures. It enables real-time engagement between lecturers and students through Q&A sessions, polls, and session management.

## ✨ Features

### For Students
- 🔐 **Secure Authentication** - Login with email/password, remember me functionality
- 📊 **Interactive Dashboard** - View active sessions, join classes, and track participation
- ❓ **Q&A System** - Ask questions during sessions, upvote others' questions
- 📋 **Poll Participation** - Answer multiple choice, yes/no, and rating scale polls
- 👤 **Profile Management** - Edit profile, upload avatar, customize preferences
- 🌓 **Theme Support** - Switch between light and dark mode

### For Lecturers
- 🎓 **Session Management** - Create and manage classroom sessions with unique codes
- 📈 **Real-time Dashboard** - Monitor active sessions and participation metrics
- 💬 **Q&A Moderation** - Review, approve, and respond to student questions
- 📊 **Poll Creation** - Create multiple choice, yes/no, and rating scale polls
- 📂 **Session History** - Track past sessions and student engagement
- 👥 **Student Analytics** - View participation rates and engagement statistics
- 🎨 **Customizable Interface** - Light and dark theme support
- 🔒 **Password Management** - Change password, update email with verification

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.9.0+
- **Backend**: Supabase (PostgreSQL)
- **State Management**: StatefulWidget with setState
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (for avatars)
- **Theme**: Material Design 3
- **Image Picker**: image_picker package
- **Preferences**: shared_preferences package

## 📋 Prerequisites

Before running this project, make sure you have:

- Flutter SDK (version 3.9.0 or higher)
- Dart SDK (version 2.19.0 or higher)
- Android Studio / Xcode (for mobile development)
- Supabase account ([supabase.com](https://supabase.com))
- Git

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/askup.git
cd askup
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase

Create a new Supabase project and update the configuration:

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Copy your project URL and anon key
3. Update `lib/main.dart` with your credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 4. Setup Database Schema

Run the SQL scripts in the `database/` folder in your Supabase SQL editor:

```sql
-- Execute in order:
1. create_users_table.sql
2. create_classes_table.sql
3. create_sessions_table.sql
4. create_session_participants_table.sql
5. create_questions_table.sql
6. create_polls_table.sql
7. create_poll_options_table.sql
8. create_poll_votes_table.sql
9. login_lecturer_function.sql (RPC function)
```

### 5. Configure Deep Links

#### Android
Deep link already configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<data android:scheme="myapp" android:host="reset-password"/>
```

#### iOS
Deep link already configured in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>myapp</string>
</array>
```

### 6. Setup Storage Bucket

In Supabase Storage, create a public bucket named `avatars` for user profile pictures.

### 7. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── deep_link_handler.dart            # Deep link handler for password reset
├── screens/
│   ├── welcome_screen.dart           # Landing page
│   ├── student_login_screen.dart     # Student authentication
│   ├── lecturer_login_screen.dart    # Lecturer authentication
│   ├── student_dashboard_screen.dart # Student main interface
│   ├── dashboard_screen.dart         # Lecturer main interface
│   ├── student_profile_screen.dart   # Student profile management
│   ├── profile_screen.dart           # Lecturer profile management
│   ├── create_poll_screen.dart       # Poll creation interface
│   ├── qa_management_screen.dart     # Question moderation
│   ├── forgot_password_screen.dart   # Password reset request
│   ├── new_password_screen.dart      # Password reset confirmation
│   └── session_detail_screen.dart    # Session details view
├── widgets/
│   ├── theme_switcher.dart           # Dark/light mode toggle
│   ├── active_session_card.dart      # Session card component
│   ├── preference_toggle.dart        # Settings toggle component
│   └── account_button.dart           # Profile action button
└── themes/
    └── app_theme.dart                # Theme configuration

database/
├── create_users_table.sql
├── create_classes_table.sql
├── create_sessions_table.sql
├── create_questions_table.sql
├── create_polls_table.sql
└── ... (other SQL files)

android/                               # Android native code
ios/                                   # iOS native code
web/                                   # Web support files
```

## 🗄️ Database Schema

### Core Tables
- **users** - Student and lecturer accounts
- **classes** - Course/class information
- **sessions** - Active and past classroom sessions
- **session_participants** - Student participation tracking
- **questions** - Student questions during sessions
- **polls** - Poll questions
- **poll_options** - Multiple choice options
- **poll_votes** - Student poll responses

### Key Relationships
- Sessions belong to Classes
- Questions belong to Sessions and Users
- Polls belong to Sessions
- Poll Votes link Users to Poll Options

## 🎨 Theme System

The app supports both light and dark themes:

- **Theme Toggle**: Available in profile screens for both students and lecturers
- **Persistent**: Theme preference is saved using SharedPreferences
- **Consistent**: All screens adapt to the selected theme
- **Material 3**: Uses the latest Material Design guidelines

## 🔑 Key Features Implementation

### Authentication
- Email/password authentication using Supabase Auth
- Role-based access (student/lecturer)
- Remember me functionality with SharedPreferences
- Password reset via email with deep linking

### Session Management
- Create sessions with unique join codes
- Real-time participant tracking
- Session status management (active/ended)
- Session history with statistics

### Q&A System
- Anonymous or named questions
- Question upvoting
- Lecturer moderation (approve/reject)
- Filter by status (pending/approved/rejected)

### Poll System
- Multiple poll types (multiple choice, yes/no, rating scale)
- Real-time voting
- Results visualization
- Poll analytics

### Performance Optimizations
- Batch queries to prevent N+1 problems
- Efficient state management
- Image optimization for avatars
- Cached theme preferences

## 🔧 Configuration

### Supabase Configuration
- Enable Email Auth in Supabase Dashboard
- Configure email templates for password reset
- Set up Row Level Security (RLS) policies if needed
- Configure storage policies for avatar uploads

### Email Templates
Configure password reset email in Supabase:
- Redirect URL: `myapp://reset-password`
- Email template should include the reset link

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ✅ Web (Chrome, Safari, Firefox)

## 🐛 Troubleshooting

### Common Issues

**1. Supabase Connection Error**
```
Error: Failed to initialize Supabase
```
Solution: Check your Supabase URL and anon key in `main.dart`

**2. Image Upload Failed**
```
Error: Storage bucket not found
```
Solution: Create an `avatars` bucket in Supabase Storage with public access

**3. Deep Link Not Working**
```
Password reset link doesn't open app
```
Solution: Verify deep link configuration in AndroidManifest.xml and Info.plist

**4. Theme Not Persisting**
```
Theme resets after app restart
```
Solution: Ensure ThemeSwitcher is properly configured with SharedPreferences

**5. Login RPC Function Error**
```
Error: function login_lecturer does not exist
```
Solution: Run the `login_lecturer_function.sql` script in Supabase SQL editor

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase team for the backend infrastructure
- Material Design team for UI/UX guidelines
- College project contributors and testers

## 📞 Support

For questions or issues, please open an issue in the GitHub repository.

---

**Version**: 0.1.0 (College Project)  
**Last Updated**: December 2025  

Made with ❤️ for better classroom engagement
