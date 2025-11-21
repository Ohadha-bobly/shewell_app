
# SheWell App

SheWell is a cross-platform wellness and community app built with Flutter and Supabase. It helps users track their mood, connect with a supportive community, find clinics, and chat with an AI assistant.

## Features

- **User Authentication**: Secure sign up, login, and password reset using Supabase Auth.
- **Profile Management**: Users can update their profile, upload a profile picture, and select a theme.
- **Mood & Wellness Tracker**: Log daily mood, sleep hours, and cycle information. View analytics of wellness logs.
- **Community**: Join a supportive community, view and interact with posts.
- **Clinic Finder**: Search and view clinics with details and services offered.
- **AI Chatbot**: Chat with a Google-powered AI assistant for wellness support.
- **Responsive UI**: Works on web, Android, iOS, Windows, Mac, and Linux.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A [Supabase](https://supabase.com/) project
- (Optional) Google API key for Gemini AI

### Setup
1. **Clone the repository:**
	```sh
	git clone <your-repo-url>
	cd shewell_app
	```
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Configure environment variables:**
	- Set your Supabase URL and Anon Key in `lib/secrets.dart` or via Dart environment variables.
	- For Google AI, set your Gemini API key in `lib/secrets.dart` or as an environment variable.

4. **Run the app:**
	```sh
	flutter run -d chrome   # For web
	flutter run -d android  # For Android
	flutter run -d ios      # For iOS
	flutter run -d windows  # For Windows
	flutter run -d macos    # For Mac
	flutter run -d linux    # For Linux
	```

### Supabase Setup
- Create tables: `users`, `wellness_logs`, `community_posts`, etc.
- Enable Row Level Security (RLS) and add policies for authenticated access.
- Set up storage buckets for profile pictures.

### Google API Setup (Chatbot)
- Get a Gemini API key from Google AI.
- Add the key to your environment or `lib/secrets.dart`.

## Folder Structure

```
lib/
  main.dart
  secrets.dart
  models/
  screens/
  services/
  widgets/
  ...
assets/
  ...
```

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](LICENSE)

## Contact
For support, open an issue or contact the maintainer.
