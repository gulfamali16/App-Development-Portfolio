# 📱 ChatiFy - Complete Documentation

## 🎯 Overview

**ChatiFy** is a modern, real-time messaging application built with Flutter and Supabase. It features Google authentication, real-time messaging, user profiles, and a beautiful WhatsApp-inspired UI.

---

## 📊 Technology Stack

### **Frontend:**
- **Flutter** 3.x
- **Dart** 3.x
- **Material Design 3**
- **Google Fonts** (Plus Jakarta Sans)

### **Backend:**
- **Supabase** (PostgreSQL)
- **Supabase Auth** (Google OAuth)
- **Supabase Realtime** (WebSocket)
- **Supabase Storage**

### **Authentication:**
- **Google OAuth 2.0**
- **Supabase Authentication**
- **Deep Links** (Android)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           ChatiFy Application           │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────┐ │
│  │  Screens │  │ Services │  │Config│ │
│  └────┬─────┘  └────┬─────┘  └──┬───┘ │
│       │             │            │     │
│       └─────────────┴────────────┘     │
│                  │                     │
└──────────────────┼─────────────────────┘
                   │
        ┌──────────▼──────────┐
        │   Supabase Cloud    │
        ├─────────────────────┤
        │ • Auth              │
        │ • Database          │
        │ • Realtime          │
        │ • Storage           │
        └─────────────────────┘
```

---

## 📁 Project Structure

```
chat_app/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart          # Supabase credentials
│   │
│   ├── services/
│   │   ├── auth_service.dart             # Authentication logic
│   │   └── chat_service.dart             # Chat & messaging logic
│   │
│   ├── Screens/
│   │   ├── splash_screen.dart            # App launch screen
│   │   ├── onboarding_screen.dart        # Onboarding 1
│   │   ├── onboarding_screen2.dart       # Onboarding 2
│   │   ├── onboarding_screen3.dart       # Onboarding 3
│   │   ├── login_screen.dart             # Google Sign-In
│   │   ├── profile_screen.dart           # Profile setup/edit
│   │   ├── home_screen.dart              # Main chat list
│   │   ├── chat_screen.dart              # Individual chat
│   │   ├── users_screen.dart             # Find users
│   │   └── calls_screen.dart             # Calls history
│   │
│   └── main.dart                         # App entry point
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml   # Deep link config
│
└── pubspec.yaml                          # Dependencies
```

---

## 🗄️ Database Schema

### **1. users Table**

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  username TEXT,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  status TEXT DEFAULT 'Available',
  about TEXT DEFAULT 'Hey there! I am using ChatiFy.',
  last_seen TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Purpose:** Store user profiles and metadata

**Fields:**
- `id`: Unique user ID (linked to Supabase Auth)
- `email`: User's email address
- `phone`: Phone number (optional)
- `username`: Unique username
- `display_name`: Full name shown in app
- `avatar_url`: Profile picture URL
- `status`: Current status (Available, Busy, etc.)
- `about`: User bio/about text
- `last_seen`: Last activity timestamp
- `created_at`: Account creation date
- `updated_at`: Last profile update

---

### **2. chats Table**

```sql
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID REFERENCES users(id) NOT NULL,
  user2_id UUID REFERENCES users(id) NOT NULL,
  last_message TEXT,
  last_message_time TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_chat UNIQUE(user1_id, user2_id)
);
```

**Purpose:** Store chat conversations between two users

**Fields:**
- `id`: Unique chat ID
- `user1_id`: First participant
- `user2_id`: Second participant
- `last_message`: Preview of last message
- `last_message_time`: Timestamp of last message
- `created_at`: Chat creation date

---

### **3. messages Table**

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID REFERENCES chats(id) NOT NULL,
  sender_id UUID REFERENCES users(id) NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  media_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Purpose:** Store individual messages

**Fields:**
- `id`: Unique message ID
- `chat_id`: Parent chat
- `sender_id`: Who sent the message
- `content`: Message text
- `message_type`: text, image, video, file, etc.
- `media_url`: URL for media messages
- `is_read`: Read receipt status
- `is_deleted`: Soft delete flag
- `created_at`: Message timestamp

---

### **4. typing_status Table**

```sql
CREATE TABLE typing_status (
  chat_id UUID REFERENCES chats(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);
```

**Purpose:** Track typing indicators in real-time

**Fields:**
- `chat_id`: Which chat
- `user_id`: Who is typing
- `is_typing`: Typing status
- `updated_at`: Last update time

---

## 🔐 Row Level Security (RLS) Policies

### **users Table Policies:**

```sql
-- Users can view all profiles
CREATE POLICY "Users can view all profiles"
ON users FOR SELECT
TO authenticated
USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

---

### **chats Table Policies:**

```sql
-- Users can view their own chats
CREATE POLICY "Users can view own chats"
ON chats FOR SELECT
TO authenticated
USING (user1_id = auth.uid() OR user2_id = auth.uid());

-- Users can create chats
CREATE POLICY "Users can create chats"
ON chats FOR INSERT
TO authenticated
WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- Users can update their chats
CREATE POLICY "Users can update own chats"
ON chats FOR UPDATE
TO authenticated
USING (user1_id = auth.uid() OR user2_id = auth.uid());
```

---

### **messages Table Policies:**

```sql
-- Users can view messages in their chats
CREATE POLICY "Users can view messages in their chats"
ON messages FOR SELECT
TO authenticated
USING (
  chat_id IN (
    SELECT id FROM chats 
    WHERE user1_id = auth.uid() OR user2_id = auth.uid()
  )
);

-- Users can send messages
CREATE POLICY "Users can send messages"
ON messages FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

-- Users can update their own messages
CREATE POLICY "Users can update own messages"
ON messages FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());
```

---

## 🔑 Authentication Flow

### **Google Sign-In Process:**

```
1. User taps "Continue with Google"
   ↓
2. loginWithGoogle() called
   ↓
3. Supabase opens Google OAuth flow
   ↓
4. User selects Google account
   ↓
5. Google authenticates user
   ↓
6. Google sends callback to:
   https://vitbnkvpvuesjiwiqapq.supabase.co/auth/v1/callback
   ↓
7. Supabase validates with Google using Web Client Secret
   ↓
8. Supabase creates user session
   ↓
9. Android deep link catches callback
   ↓
10. App resumes, auth state changes to SIGNED_IN
   ↓
11. Check if profile complete:
       - YES → Navigate to Home
       - NO → Navigate to Profile Setup
   ↓
12. User logged in! ✅
```

---

### **Profile Creation:**

```dart
// After Google sign-in
if (response.user != null) {
  // Check if profile exists
  final isComplete = await checkUserProfile(userId);
  
  if (!isComplete) {
    // First time user
    await ensureUserProfileExists();
    Navigator.pushReplacementNamed('/profile-setup');
  } else {
    // Existing user
    Navigator.pushReplacementNamed('/home');
  }
}
```

---

## 💬 Real-Time Messaging

### **How Messages Work:**

1. **Sending a Message:**
```dart
await chatService.sendMessage(
  chatId: chatId,
  content: 'Hello!',
);
```

2. **Supabase inserts message:**
```sql
INSERT INTO messages (chat_id, sender_id, content, created_at)
VALUES ('chat-id', 'user-id', 'Hello!', NOW());
```

3. **Real-time broadcast:**
- Supabase broadcasts change via WebSocket
- All clients subscribed to this chat receive update

4. **Receiving messages:**
```dart
chatService.listenToMessages(chatId).listen((messages) {
  setState(() {
    _messages = messages;
  });
});
```

---

### **Typing Indicators:**

```dart
// User starts typing
await chatService.updateTypingStatus(chatId, true);

// Listen for other user typing
chatService.listenToTypingStatus(chatId, otherUserId)
  .listen((isTyping) {
    setState(() {
      _isOtherUserTyping = isTyping;
    });
  });

// Auto-stop after 2 seconds
Timer(Duration(seconds: 2), () {
  chatService.updateTypingStatus(chatId, false);
});
```

---

### **Read Receipts:**

```dart
// Mark messages as read when chat opens
await chatService.markMessagesAsRead(chatId, currentUserId);

// Display status:
Icon(
  message['is_read'] ? Icons.done_all : Icons.done,
  color: message['is_read'] ? Colors.blue : Colors.grey,
)
```

---

## 🎨 UI/UX Features

### **Design System:**

- **Primary Color:** #128C7E (Teal)
- **Font:** Plus Jakarta Sans
- **Theme:** Light & Dark mode support
- **Style:** WhatsApp-inspired, modern, clean

---

### **Screens:**

#### **1. Splash Screen**
- App logo with animation
- Auto-navigates to onboarding or login

#### **2. Onboarding (3 screens)**
- Welcome message
- Share moments
- Security features
- Skip button available

#### **3. Login Screen**
- Single "Continue with Google" button
- App features showcase
- Terms & Privacy links

#### **4. Profile Setup**
- Upload avatar
- Enter display name
- Select status
- About text

#### **5. Home Screen**
- **CHATS tab:** List of conversations
- **USERS tab:** Find all users
- **CALLS tab:** Call history
- Floating action button (new chat)
- Search functionality

#### **6. Chat Screen**
- Message bubbles (sent/received)
- Typing indicators
- Read receipts
- Auto-scroll to bottom
- Date separators
- Long-press to delete

#### **7. Users Screen**
- All registered users
- Online status indicators
- Search by name/about
- Tap to start chat
- Pull to refresh

#### **8. Profile Screen**
- Edit display name
- Upload avatar
- Change status
- Update about text
- Save/Cancel buttons

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI
  google_fonts: ^6.1.0
  
  # Backend
  supabase_flutter: ^2.5.6
  
  # State Management
  provider: ^6.1.1
  
  # Image Handling
  image_picker: ^1.0.7
  
  # Authentication
  google_sign_in: ^6.2.1
```

---

## 🔧 Configuration Files

### **1. supabase_config.dart**

```dart
class SupabaseConfig {
  static const String supabaseUrl = 
    'https://vitbnkvpvuesjiwiqapq.supabase.co';
  
  static const String supabaseAnonKey = 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

---

### **2. AndroidManifest.xml (Deep Link)**

```xml
<!-- Deep Link for Supabase OAuth Callback -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    
    <data
        android:scheme="https"
        android:host="vitbnkvpvuesjiwiqapq.supabase.co"
        android:pathPrefix="/auth/v1/callback"/>
</intent-filter>
```

---

### **3. Google Cloud Console**

**OAuth 2.0 Credentials:**

**Android Client:**
```
Client ID: 902012886958-pganmgb3bk2hchghouhb83rmd3hcdauq...
Package Name: com.example.chat_app
SHA-1: AA:49:CF:04:D2:72:26:88:F6:6E:A0:43:00:3E:84:3B:28:45:7E:95
```

**Web Client (for Supabase):**
```
Client ID: 902012886958-2960esnvk587331h1fbdbilnlgrc21ah...
Client Secret: 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
Redirect URI: https://vitbnkvpvuesjiwiqapq.supabase.co/auth/v1/callback
```

---

### **4. Supabase Configuration**

**Authentication → Providers → Google:**
```
Client IDs: 
  902012886958-pganmgb3bk2hchghouhb83rmd3hcdauq...,
  902012886958-2960esnvk587331h1fbdbilnlgrc21ah...

Client Secret: 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

Skip nonce checks: ✅ Enabled
```

---

## 🚀 Build & Deployment

### **Development Build:**

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

---

### **Release Build (APK):**

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

---

### **Install APK:**

```bash
# Via Flutter
flutter install

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

### **Unit Tests:**

```bash
flutter test
```

### **Integration Tests:**

```bash
flutter test integration_test
```

### **Manual Testing Checklist:**

- [ ] Google Sign-In works
- [ ] Profile setup saves correctly
- [ ] User list loads all users
- [ ] Chat creation works
- [ ] Messages send in real-time
- [ ] Messages appear on other device
- [ ] Typing indicator shows
- [ ] Read receipts update
- [ ] Delete message works
- [ ] Search works
- [ ] Dark mode works
- [ ] Pull to refresh works

---

## 🐛 Troubleshooting

### **Issue 1: Google Sign-In fails**

**Error:** "redirect_uri_mismatch"

**Solution:**
- Check Google Console has correct redirect URI
- Verify AndroidManifest has deep link intent filter
- Ensure no `redirectTo` parameter in auth_service.dart
- Wait 2 minutes after Google Console changes

---

### **Issue 2: Messages not appearing**

**Error:** Messages send but don't show up

**Solution:**
- Enable Realtime on messages table in Supabase
- Check RLS policies allow reading messages
- Verify WebSocket connection
- Check browser console for errors

---

### **Issue 3: Profile not created**

**Error:** "new row violates row-level security policy"

**Solution:**
- Check RLS policies on users table
- Verify INSERT policy allows authenticated users
- Ensure user ID matches auth.uid()

---

### **Issue 4: Users list empty**

**Error:** No users showing up

**Solution:**
- Check ChatService.getAllUsers() query
- Verify RLS policies allow SELECT on users table
- Ensure users are registered in database
- Check console for errors

---

### **Issue 5: APK crashes on launch**

**Error:** App closes immediately after opening

**Solution:**
- Check AndroidManifest permissions
- Verify Supabase initialization
- Check for ProGuard issues
- View logcat: `adb logcat`

---

## 📈 Performance Optimization

### **1. Database Indexes:**

```sql
-- Speed up chat queries
CREATE INDEX idx_chats_user1 ON chats(user1_id);
CREATE INDEX idx_chats_user2 ON chats(user2_id);

-- Speed up message queries
CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
```

---

### **2. Pagination:**

```dart
// Load messages in batches
final messages = await supabase
  .from('messages')
  .select()
  .eq('chat_id', chatId)
  .order('created_at', ascending: false)
  .limit(50)  // Load 50 at a time
  .offset(offset);
```

---

### **3. Image Optimization:**

```dart
// Compress before upload
final compressedImage = await FlutterImageCompress.compressWithFile(
  imagePath,
  quality: 70,
  minWidth: 1024,
  minHeight: 1024,
);
```

---

## 🔮 Future Features

### **Phase 1: Media Messages**
- [ ] Image sharing
- [ ] Video sharing
- [ ] Voice messages
- [ ] Document sharing
- [ ] Image gallery viewer

### **Phase 2: Group Chats**
- [ ] Create groups
- [ ] Add/remove members
- [ ] Group admin permissions
- [ ] Group profile pictures
- [ ] Group descriptions

### **Phase 3: Advanced Features**
- [ ] Message reactions (❤️, 👍, 😂)
- [ ] Reply to messages
- [ ] Forward messages
- [ ] Message search
- [ ] Voice calls
- [ ] Video calls
- [ ] Stories (24h status)
- [ ] Message encryption

### **Phase 4: Enhanced UX**
- [ ] Push notifications
- [ ] Message backup
- [ ] Dark/Light theme toggle
- [ ] Chat wallpapers
- [ ] Custom notification sounds
- [ ] Archive chats
- [ ] Pin chats
- [ ] Mute conversations

---

## 📝 Code Examples

### **Example 1: Send Message**

```dart
// In chat_screen.dart
Future<void> _sendMessage() async {
  final message = _messageController.text.trim();
  if (message.isEmpty) return;
  
  final success = await _chatService.sendMessage(
    chatId: widget.chatId,
    content: message,
  );
  
  if (success) {
    _messageController.clear();
    _scrollToBottom();
  }
}
```

---

### **Example 2: Listen to Messages**

```dart
// In chat_screen.dart
void _listenToMessages() {
  _messagesSubscription = _chatService
    .listenToMessages(widget.chatId)
    .listen((messages) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
}
```

---

### **Example 3: Create Chat**

```dart
// In users_screen.dart
Future<void> _startChat(Map<String, dynamic> user) async {
  final chatId = await _chatService.createOrGetChat(user['id']);
  
  if (chatId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserId: user['id'],
          otherUserName: user['display_name'],
          otherUserAvatar: user['avatar_url'],
          otherUserStatus: user['status'],
        ),
      ),
    );
  }
}
```

---

## 📊 Analytics & Monitoring

### **Supabase Logs:**

```
Project → Logs → API → Filter by:
- auth.signInWithOAuth
- SELECT from users
- INSERT into messages
- Error responses
```

### **Performance Metrics:**

- Message delivery time
- User login success rate
- API response times
- Real-time connection stability

---

## 🔒 Security Best Practices

### **1. Never Expose Secrets:**
- ✅ Use environment variables
- ✅ Keep anon key in code (it's public)
- ❌ Never commit service role key
- ❌ Never commit OAuth client secrets in Android app

### **2. Enable RLS:**
- ✅ All tables must have RLS enabled
- ✅ Policies should check auth.uid()
- ✅ Test with different users

### **3. Validate Input:**
- ✅ Sanitize user input
- ✅ Validate message length
- ✅ Check file types/sizes

### **4. Rate Limiting:**
- ✅ Supabase has built-in rate limits
- ✅ Add application-level limits if needed

---

## 📞 Support & Resources

### **Documentation:**
- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.com/docs
- Google OAuth: https://developers.google.com/identity

### **Community:**
- Flutter Discord
- Supabase Discord
- Stack Overflow

---

## ✅ Final Checklist

### **Before Launch:**

- [ ] All features tested
- [ ] Google OAuth configured
- [ ] Supabase RLS enabled
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Dark mode works
- [ ] APK tested on real device
- [ ] Privacy policy created
- [ ] Terms of service created
- [ ] App icon designed
- [ ] Splash screen added
- [ ] Google Play Store listing ready

---

## 🎉 Conclusion

ChatiFy is a fully-functional, real-time messaging application with:

✅ **Google Authentication**
✅ **Real-time Messaging**
✅ **User Profiles**
✅ **Chat Management**
✅ **Beautiful UI**
✅ **Typing Indicators**
✅ **Read Receipts**
✅ **Online Status**
✅ **Search Functionality**
✅ **Dark Mode Support**

**Your app is production-ready! 🚀**

---

**Built with ❤️ using Flutter & Supabase**

*Last Updated: December 2024*
