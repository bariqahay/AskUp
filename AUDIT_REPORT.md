# 🔍 AUDIT REPORT - AskUp+ Application
**Date:** December 16, 2025
**Status:** Comprehensive Feature & Database Audit

---

## ✅ LECTURER FEATURES (WORKING)

### 1. **Login & Authentication**
- ✅ Email/password login via Supabase Auth
- ✅ Session persistence with SharedPreferences
- ✅ Auto-redirect to dashboard if logged in

### 2. **Dashboard** (`dashboard_screen.dart`)
- ✅ Load active sessions from database
- ✅ Load session history from database  
- ✅ Display student count per session
- ✅ Create new session dialog
- ✅ Navigate to session detail
- ✅ Pull-to-refresh
- ✅ Navigate to profile

### 3. **Session Detail** (`session_detail_screen.dart`)
- ✅ Display session info & QR code (with UUID format)
- ✅ Real-time stats: present count, new questions, active polls
- ✅ Real-time subscriptions (participants, questions, polls)
- ✅ Navigate to QA Management
- ✅ Navigate to Create Poll
- ✅ End session functionality
- ✅ Session status indicator (active/ended)

### 4. **QA Management** (`qa_management_screen.dart`)
- ✅ View all questions for session
- ✅ Filter by status (All/Pending/Answered)
- ✅ Search questions
- ✅ Answer questions
- ✅ Update question status
- ✅ Real-time question updates
- ✅ Display upvote counts

### 5. **Create Poll** (`create_poll_screen.dart`)
- ✅ Create multiple choice polls
- ✅ Add/remove options (2-10)
- ✅ Set time limit
- ✅ Toggle live results visibility
- ✅ Save poll to database with options

### 6. **Profile** (`profile_screen.dart`)
- ⚠️ Display profile info (HARDCODED)
- ⚠️ Settings toggles (NOT SAVED TO DB)
- ❌ Change password (NOT IMPLEMENTED)
- ❌ Update email (NOT IMPLEMENTED)

---

## ✅ STUDENT FEATURES (WORKING)

### 1. **Login & Authentication**
- ✅ Email/password login (direct database query)
- ✅ Retrieve student ID from users table
- ✅ Pass student ID to dashboard

### 2. **Dashboard** (`student_dashboard_screen.dart`)
- ✅ Display greeting & profile avatar
- ✅ JOIN SESSION BY CODE - **JUST FIXED** ✨
  - Query sessions table by session_code
  - Check session is active
  - Auto check-in to session_participants
  - Navigate with sessionId & studentId
- ✅ QR Scanner button (with studentId validation)
- ❌ Active sessions list (HARDCODED - needs database query)
- ❌ Stats display (HARDCODED)

### 3. **QR Scanner** (`qr_scanner_screen.dart`)
- ✅ Camera scanner with mobile_scanner
- ✅ Custom overlay (fixed transparent center)
- ✅ Process QR format: `askup://session/{UUID}`
- ✅ Validate session from database
- ✅ Auto check-in to session_participants
- ✅ Navigate to session detail with IDs

### 4. **Session Detail** (`student_session_detail_screen.dart`)
- ✅ **Q&A Tab:**
  - View all questions
  - Upvote/downvote questions (with database update)
  - Ask new question (anonymous option)
  - Real-time question updates
  
- ✅ **Polls Tab:**
  - View active polls
  - Select option (clickable UI - FIXED)
  - Submit vote (with duplicate check)
  - Display vote counts & percentages
  - Real-time poll updates
  
- ✅ **Check-in Tab:**
  - Display check-in status from session_participants
  - Show check-in time if present
  - Not checked in state

### 5. **Profile** (`student_profile_screen.dart`)
- ✅ Display profile info (HARDCODED)
- ✅ Activity stats (HARDCODED)
- ✅ Theme switcher (Light/Dark/System) - **FULLY WORKING** 🎨
- ✅ Notification preferences
- ⚠️ Settings NOT saved to database

---

## 🎨 THEME & UI (FULLY WORKING)

- ✅ Light theme with Material 3
- ✅ Dark theme with proper colors
- ✅ Theme persistence (SharedPreferences)
- ✅ Instant theme switching (no restart needed)
- ✅ All screens responsive to theme
- ✅ Splash screen with animation

---

## ❌ CRITICAL BUGS & MISSING FEATURES

### **HIGH PRIORITY:**
1. ❌ **Student Dashboard - Active Sessions**
   - Currently HARDCODED dummy data
   - Need to query: sessions table joined with session_participants
   - Filter by student_id

2. ❌ **Student Dashboard - Stats**
   - Currently shows "12 Questions, 8 Polls, 95%"
   - Need real queries:
     - Count questions by student_id
     - Count poll_votes by student_id
     - Calculate attendance percentage

3. ❌ **Navigate to Session Detail**
   - Hardcoded session cards don't pass sessionId/studentId
   - Need to fix navigation parameters

### **MEDIUM PRIORITY:**
4. ⚠️ **Profile Data**
   - Both lecturer & student profiles use hardcoded data
   - Need to load from users table
   - Settings changes not persisted

5. ⚠️ **Session History Performance**
   - Uses sequential queries for student count
   - Should use JOIN or batch query

---

## 📊 DATABASE SCHEMA REQUIREMENTS

### **Tables Needed:**

```sql
-- 1. users table
users (
  id UUID PRIMARY KEY,
  email TEXT,
  password TEXT,  -- hashed
  name TEXT,
  role TEXT,  -- 'lecturer' or 'student'
  department TEXT,
  employee_id TEXT,
  avatar_url TEXT,
  push_notifications BOOLEAN,
  email_updates BOOLEAN,
  created_at TIMESTAMPTZ
)

-- 2. classes table
classes (
  id UUID PRIMARY KEY,
  lecturer_id UUID REFERENCES users(id),
  title TEXT,
  code TEXT,  -- class code (e.g., "CS101")
  created_at TIMESTAMPTZ
)

-- 3. sessions table
sessions (
  id UUID PRIMARY KEY,
  class_id UUID REFERENCES classes(id),
  title TEXT,
  description TEXT,
  session_code TEXT UNIQUE,  -- 6-char code for joining
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  status TEXT,  -- 'active' or 'ended'
  created_at TIMESTAMPTZ
)

-- 4. session_participants table (CHECK-IN)
session_participants (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, student_id)
)

-- 5. questions table
questions (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id),
  content TEXT,
  is_anonymous BOOLEAN DEFAULT FALSE,
  upvotes_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',  -- 'pending', 'answered'
  answer TEXT,
  answered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
)

-- 6. question_upvotes table
question_upvotes (
  id UUID PRIMARY KEY,
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(question_id, student_id)
)

-- 7. polls table
polls (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  question TEXT,
  poll_type TEXT DEFAULT 'multiple_choice',
  time_limit INTEGER,
  show_results_live BOOLEAN DEFAULT TRUE,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
)

-- 8. poll_options table
poll_options (
  id UUID PRIMARY KEY,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  option_text TEXT,
  votes_count INTEGER DEFAULT 0,
  option_order INTEGER
)

-- 9. poll_votes table (NEED TO CREATE)
poll_votes (
  id UUID PRIMARY KEY,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  option_id UUID REFERENCES poll_options(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(poll_id, student_id)
)
```

### **RPC Functions Needed:**

```sql
-- 1. Increment upvote (ALREADY CREATED)
CREATE OR REPLACE FUNCTION increment_upvote(question_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE questions 
  SET upvotes_count = upvotes_count + 1
  WHERE id = question_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Decrement upvote (ALREADY CREATED)
CREATE OR REPLACE FUNCTION decrement_upvote(question_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE questions 
  SET upvotes_count = GREATEST(upvotes_count - 1, 0)
  WHERE id = question_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Increment poll votes (NEED TO CREATE)
CREATE OR REPLACE FUNCTION increment_poll_votes(option_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE poll_options 
  SET votes_count = votes_count + 1 
  WHERE id = option_id;
END;
$$ LANGUAGE plpgsql;
```

### **Indexes for Performance:**
```sql
CREATE INDEX idx_session_participants_session ON session_participants(session_id);
CREATE INDEX idx_session_participants_student ON session_participants(student_id);
CREATE INDEX idx_questions_session ON questions(session_id);
CREATE INDEX idx_question_upvotes_question ON question_upvotes(question_id);
CREATE INDEX idx_question_upvotes_student ON question_upvotes(student_id);
CREATE INDEX idx_polls_session ON polls(session_id);
CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_student ON poll_votes(student_id);
```

---

## 🚀 NEXT STEPS TO COMPLETE

### **1. Fix Student Active Sessions** (CRITICAL)
```dart
// Need to implement in student_dashboard_screen.dart
Future<void> _loadActiveSessions() async {
  final sessions = await supabase
    .from('sessions')
    .select('*, classes!inner(*), session_participants!inner(student_id)')
    .eq('session_participants.student_id', widget.studentId)
    .eq('status', 'active');
  
  // Update UI with real data
}
```

### **2. Fix Student Stats** (CRITICAL)
```dart
// Count questions
final questionsCount = await supabase
  .from('questions')
  .select('id', count: CountOption.exact)
  .eq('student_id', widget.studentId);

// Count poll votes
final pollsCount = await supabase
  .from('poll_votes')
  .select('id', count: CountOption.exact)
  .eq('student_id', widget.studentId);

// Calculate attendance
```

### **3. Create Missing Database Items**
- [ ] Create `poll_votes` table
- [ ] Create `increment_poll_votes` RPC function
- [ ] Run `database_updates.sql` in Supabase SQL Editor
- [ ] Create test accounts with `test_accounts.sql`

### **4. Fix Profile Screens**
- [ ] Load user data from database
- [ ] Save settings changes to users table
- [ ] Implement change password
- [ ] Implement update email

---

## 📝 SUMMARY

**Working Well:**
- ✅ All core lecturer features (create session, manage QA, create polls)
- ✅ Student join via QR scanner
- ✅ Student join via code (JUST FIXED)
- ✅ Real-time updates everywhere
- ✅ Dark mode & themes
- ✅ Upvote system
- ✅ Poll voting system
- ✅ Check-in system

**Needs Fixing:**
- ❌ Student dashboard active sessions (hardcoded)
- ❌ Student stats (hardcoded)
- ❌ Profile data loading
- ⚠️ Database: create poll_votes table & RPC function

**Performance:**
- 🐌 Session history student count (sequential queries)

---

**Author:** GitHub Copilot AI
**Last Updated:** December 16, 2025
