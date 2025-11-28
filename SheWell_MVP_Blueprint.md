# SheWell MVP v2 Blueprint

###  Empowering Women’s Wellness through Technology

## 1️⃣ App Overview

Goal:
Help women track mental and physical health, access self-care resources, and ask health-related questions via an AI-powered chatbot, now enhanced with user authentication and Firebase integration.

Target SDGs:
- SDG 3: Good Health and Well-being
- SDG 5: Gender Equality

## 2️⃣ Core Features

A. Wellness Tracker
- Track mood, sleep, and menstrual cycle
- Entries saved locally (Hive) and synced to Firestore per user
- Optional weekly trends using fl_chart

B. AI Chatbot
- Ask about mental health, reproductive health, or self-care
- Powered by OpenAI GPT API
- Chat history saved per user in Firestore
- Chat UI: ListView, TextField, ElevatedButton

C. Resources Directory
- List of clinics, hotlines, and NGOs with contact info
- Scrollable list using ListView and Card
- Data fetched from Firestore
- Optional location filter

D. Notifications / Reminders
- Daily reminder to log mood
- Optional menstrual cycle alerts
- Uses flutter_local_notifications
- Can extend with Firebase Cloud Messaging (FCM)

E. Authentication 
- Supabase Authentication (Email/Password, optional Google Sign-In)
- Secure login and signup flow
- User data (mood logs, chat history) tied to their Firebase UID
- Simple Profile page to view account info and logout

## 3️⃣ Screens & Navigation

Screen | Purpose | Key Widgets
-------|----------|-------------
Splash / Auth Check | Check login state | FutureBuilder, CircularProgressIndicator
Login | User sign-in | TextField, ElevatedButton
Signup | Create new account | TextField, ElevatedButton
Home / Tracker | Track wellness | Card, DropdownButton, ElevatedButton
Chatbot | Ask AI | ListView, TextField, ElevatedButton
community | Clinics, hotlines, NGOs | ListView, Card, ListTile
Profile / Settings | Manage notifications, logout | SwitchListTile, ListTile, ElevatedButton

Navigation:
BottomNavigationBar → Tracker | Chatbot | Resources | Profile

## 4️⃣ Data Models

class MoodLog {
  final String userId;
  final DateTime date;
  final String mood;
  final double sleepHours;
  final String? cycleInfo;
}

class ChatMessage {
  final String userId;
  final String message;
  final bool isUser;
  final DateTime timestamp;
}

class Resource {
  final String name;
  final String type;
  final String contact;
}

## 5️⃣ Packages to Use

Package | Purpose
--------|----------
firebase_core | Initialize Firebase
firebase_auth | Authentication
cloud_firestore | Store user data & logs
firebase_messaging | Push notifications
flutter_local_notifications | Local reminders
http | API calls to OpenAI
flutter_dotenv | Store API keys
Hive / SharedPreferences | Local offline storage
provider | State management
fl_chart | Mood/sleep trends visualization

## 6️⃣ Firebase Setup

Firebase Project Setup Steps:
1. Create a Firebase project: https://console.firebase.google.com
2. Add Android app (package name: e.g. com.shewell.app)
3. Download and add google-services.json → /android/app/
4. Add iOS config (if applicable)
5. Add Firebase dependencies:
   - firebase_core
   - firebase_auth
   - cloud_firestore
6. Initialize Firebase in main.dart:
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
7. Enable Email/Password Auth in Firebase Console
8. Create Firestore collections:
   - /users/{userId}
   - /moodLogs/{userId}
   - /chatMessages/{userId}
   - /resources/

## 7️⃣ MVP Workflow

1. Launch app → Check if user logged in
2. If not → show Login/Signup
3. After login → show Home (Tracker)
4. Log daily mood/sleep/cycle → save in Firestore
5. Ask AI chatbot → get GPT response → save in Firestore
6. Browse Resources Directory
7. Receive Daily Notifications to log mood

## 8️⃣ Future Enhancements (Post-MVP)

Feature | Description
---------|-------------
Premium Plan | Unlock unlimited chatbot use, insights, and reminders
Google Sign-In | Easier login with Google accounts
AI Health Summaries | Weekly reports on mood and wellness
Profile Pictures | Upload & store in Firebase Storage
Cloud Sync | Backup all data securely

## 9️⃣ Architecture Overview

Layer | Purpose
-------|----------
Frontend (Flutter) | Screens, navigation, UI logic
Backend (Firebase) | Auth, Firestore, Messaging
AI Layer (OpenAI API) | Smart responses for chatbot
Local Storage | Offline cache with Hive
State Management | Provider for app-wide state

## 🔚 Summary

SheWell MVP v2 provides a secure, cloud-backed foundation for women’s wellness tracking, AI-driven guidance, and accessible health resources. It’s modular, scalable, and ready for the next step — Firestore data sync + premium expansion.
