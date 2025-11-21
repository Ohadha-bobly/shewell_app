# SheWell App - Setup Instructions

## ⚠️ Important: Flutter in Replit

**Note:** Flutter is not fully supported in Replit's web-based environment. The Replit Agent documentation states: "Replit Agent does not support Flutter, but you can build mobile applications using Expo React Native."

This project structure has been created for a Flutter/Dart application, but you'll need to run it in a local development environment or use alternative deployment options.

## Current Project Structure

The following files have been created:

- **lib/main.dart** - Main application entry point
- **lib/secrets.dart** - API key management
- **lib/services/** - Theme service, storage service
- **lib/screens/** - All application screens including new Clinic Finder
- **lib/models/** - Data models (Clinic model)
- **lib/widgets/** - Reusable widgets
- **pubspec.yaml** - Dependencies configuration
- **web/** - Web configuration files

## To Run This Flutter App Locally

1. **Install Flutter SDK**:
   ```bash
   # Download Flutter from https://flutter.dev/docs/get-started/install
   # Add Flutter to your PATH
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set Environment Variables**:
   Create a file to run with environment variables:
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000 \
     --dart-define=SUPABASE_URL=your_supabase_url \
     --dart-define=SUPABASE_ANON_KEY=your_supabase_key \
     --dart-define=GEMINI_API_KEY=your_gemini_key \
     --dart-define=GOOGLE_MAPS_API_KEY=your_maps_key
   ```

## Required Environment Variables

- **SUPABASE_URL**: Your Supabase project URL
- **SUPABASE_ANON_KEY**: Your Supabase anonymous key
- **GEMINI_API_KEY**: Google Gemini API key for chatbot functionality  
- **GOOGLE_MAPS_API_KEY**: Google Maps API key for clinic finder (optional)

## Supabase Setup (CRITICAL - Required for App to Work!)

### Step 1: Create Storage Bucket

Go to **Storage** in your Supabase dashboard and create a new bucket:

- **Bucket Name**: `profile_pictures`
- **Public Bucket**: ✅ Yes (enabled)
- **File Size Limit**: 5MB (or your preference)
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`

### Step 2: Create Database Tables

Run these SQL commands in **SQL Editor** in your Supabase dashboard:

#### 1. Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  name TEXT,
  email TEXT UNIQUE,
  profile_url TEXT,
  online BOOLEAN DEFAULT FALSE,
  last_seen TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Wellness Logs Table
```sql
CREATE TABLE wellness_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  mood TEXT,
  sleep_hours NUMERIC,
  cycle_info TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 3. Messages Table
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id TEXT,
  sender_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. Communities Tables
```sql
CREATE TABLE communities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE community_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id UUID REFERENCES communities(id),
  user_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(community_id, user_id)
);

CREATE TABLE community_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id UUID REFERENCES communities(id),
  user_id UUID REFERENCES users(id),
  text TEXT,
  anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE community_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id),
  user_id UUID REFERENCES users(id),
  text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE community_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id),
  user_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);
```

#### 5. Clinics Table (Optional - for clinic finder feature)
```sql
CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  address TEXT,
  latitude NUMERIC,
  longitude NUMERIC,
  phone TEXT,
  website TEXT,
  services TEXT[],
  operating_hours TEXT,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Step 3: Create Auth Trigger (CRITICAL!)

This trigger automatically creates a user record when someone signs up:

```sql
-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger that fires after a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### Step 4: Enable Row Level Security (RLS) Policies

**CRITICAL:** Without these policies, users won't be able to access data!

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view all profiles"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Wellness logs policies
CREATE POLICY "Users can view own wellness logs"
  ON wellness_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wellness logs"
  ON wellness_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wellness logs"
  ON wellness_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wellness logs"
  ON wellness_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Messages table policies
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Communities table policies
CREATE POLICY "Anyone can view communities"
  ON communities FOR SELECT
  USING (true);

-- Community members policies
CREATE POLICY "Anyone can view community members"
  ON community_members FOR SELECT
  USING (true);

CREATE POLICY "Users can join communities"
  ON community_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave communities"
  ON community_members FOR DELETE
  USING (auth.uid() = user_id);

-- Community posts policies
CREATE POLICY "Anyone can view community posts"
  ON community_posts FOR SELECT
  USING (true);

CREATE POLICY "Members can create posts"
  ON community_posts FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM community_members
      WHERE community_id = community_posts.community_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own posts"
  ON community_posts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
  ON community_posts FOR DELETE
  USING (auth.uid() = user_id);

-- Community comments policies
CREATE POLICY "Anyone can view comments"
  ON community_comments FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can comment"
  ON community_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON community_comments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON community_comments FOR DELETE
  USING (auth.uid() = user_id);

-- Community likes policies
CREATE POLICY "Anyone can view likes"
  ON community_likes FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can like posts"
  ON community_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts"
  ON community_likes FOR DELETE
  USING (auth.uid() = user_id);

-- Clinics table policies (public read access)
CREATE POLICY "Anyone can view clinics"
  ON clinics FOR SELECT
  USING (true);
```

### Step 5: Configure Storage Bucket Policies

Go to **Storage** → **Policies** for the `profile_pictures` bucket:

```sql
-- Allow authenticated users to upload their own profile pictures
CREATE POLICY "Users can upload own profile picture"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile_pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own profile pictures
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile_pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to all profile pictures
CREATE POLICY "Public can view profile pictures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile_pictures');
```

### Step 6: Enable Realtime (Optional but Recommended)

For real-time features (messages, community posts), enable Realtime:

1. Go to **Database** → **Replication**
2. Enable replication for these tables:
   - `messages`
   - `community_posts`
   - `community_comments`
   - `community_likes`
   - `users` (for online status)

## New Features Added

### Clinic Finder Screen
- Interactive clinic list with search functionality
- Clinic details screen with contact information
- Call and website launch integration
- Sample clinic data provided in `lib/models/clinic.dart`
- Ready for Google Maps integration (requires API key)

### Modernized UI
- Material Design 3 components
- Smooth animations using flutter_animate package
- Enhanced visual hierarchy
- Better spacing and modern look
- Multiple theme options

## Alternative: Convert to React Native

Since Replit Agent better supports React Native, you may want to consider converting this app to Expo React Native which is fully supported in Replit.

## Support

For Flutter development help:
- Official docs: https://flutter.dev/docs
- Supabase Flutter: https://supabase.com/docs/reference/dart/introduction

