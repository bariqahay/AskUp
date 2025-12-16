-- =====================================================
-- ASKUP+ DATABASE SCHEMA UPDATES
-- Untuk fitur: Upvote, Anonymous Questions, Check-in
-- =====================================================

-- 1. UPDATE QUESTIONS TABLE
-- Tambah kolom untuk upvote dan anonymous
ALTER TABLE questions ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN DEFAULT false;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS upvotes_count INTEGER DEFAULT 0;

-- 2. CREATE QUESTION_UPVOTES TABLE
-- Untuk tracking siapa yang upvote
CREATE TABLE IF NOT EXISTS public.question_upvotes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL,
  student_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT question_upvotes_pkey PRIMARY KEY (id),
  CONSTRAINT question_upvotes_question_id_fkey 
    FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE,
  CONSTRAINT question_upvotes_student_id_fkey 
    FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT unique_upvote_per_student UNIQUE(question_id, student_id)
);

-- Index untuk performa
CREATE INDEX IF NOT EXISTS idx_question_upvotes_question_id 
  ON question_upvotes(question_id);
CREATE INDEX IF NOT EXISTS idx_question_upvotes_student_id 
  ON question_upvotes(student_id);

-- 3. RPC FUNCTIONS
-- Function untuk increment upvote
CREATE OR REPLACE FUNCTION increment_upvote(question_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE questions 
  SET upvotes_count = upvotes_count + 1 
  WHERE id = question_id;
END;
$$ LANGUAGE plpgsql;

-- Function untuk decrement upvote
CREATE OR REPLACE FUNCTION decrement_upvote(question_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE questions 
  SET upvotes_count = GREATEST(upvotes_count - 1, 0)
  WHERE id = question_id;
END;
$$ LANGUAGE plpgsql;

-- 3.1 CREATE POLL_VOTES TABLE (NEW)
-- Untuk tracking siapa yang vote di poll mana
CREATE TABLE IF NOT EXISTS public.poll_votes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL,
  option_id uuid NOT NULL,
  student_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT poll_votes_pkey PRIMARY KEY (id),
  CONSTRAINT poll_votes_poll_id_fkey 
    FOREIGN KEY (poll_id) REFERENCES polls (id) ON DELETE CASCADE,
  CONSTRAINT poll_votes_option_id_fkey 
    FOREIGN KEY (option_id) REFERENCES poll_options (id) ON DELETE CASCADE,
  CONSTRAINT poll_votes_student_id_fkey 
    FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT unique_vote_per_student_per_poll UNIQUE(poll_id, student_id)
);

-- Index untuk performa
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_student_id ON poll_votes(student_id);

-- 3.2 RPC Function untuk increment poll votes
CREATE OR REPLACE FUNCTION increment_poll_votes(option_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE poll_options 
  SET votes_count = votes_count + 1 
  WHERE id = option_id;
END;
$$ LANGUAGE plpgsql;

-- 4. ENABLE ROW LEVEL SECURITY (Optional)
-- Aktifkan RLS untuk keamanan
ALTER TABLE question_upvotes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all upvotes
CREATE POLICY "Anyone can view upvotes" ON question_upvotes
  FOR SELECT USING (true);

-- Policy: Users can insert their own upvotes
CREATE POLICY "Users can insert own upvotes" ON question_upvotes
  FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Policy: Users can delete their own upvotes
CREATE POLICY "Users can delete own upvotes" ON question_upvotes
  FOR DELETE USING (auth.uid() = student_id);

-- 5. VERIFY EXISTING TABLES
-- Pastikan session_participants sudah ada dengan constraint yang benar
-- (Ini sudah ada di schema Anda, hanya untuk verifikasi)

-- Check session_participants table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'session_participants';

-- Check unique constraint
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'session_participants';

-- =====================================================
-- TESTING QUERIES (JANGAN DIJALANKAN - HANYA CONTOH)
-- =====================================================

-- CATATAN: Query di bawah ini hanya contoh, ganti placeholder dengan ID yang valid
-- Uncomment dan ganti ID sesuai kebutuhan

/*
-- Test 1: Insert anonymous question dengan upvote count
INSERT INTO questions (session_id, student_id, content, is_anonymous, upvotes_count, status)
VALUES (
  'your-session-id-here',
  'your-student-id-here',
  'Test anonymous question',
  true,
  0,
  'pending'
);

-- Test 2: Insert upvote
INSERT INTO question_upvotes (question_id, student_id)
VALUES (
  'question-id-here',
  'student-id-here'
);

-- Test 3: Call increment function
SELECT increment_upvote('question-id-here');

-- Test 4: Check upvote count
SELECT id, content, upvotes_count, is_anonymous
FROM questions
WHERE session_id = 'your-session-id-here'
ORDER BY upvotes_count DESC;

-- Test 5: Check who upvoted
SELECT 
  q.content,
  u.name as upvoted_by,
  qu.created_at
FROM question_upvotes qu
JOIN questions q ON q.id = qu.question_id
JOIN users u ON u.id = qu.student_id
WHERE q.session_id = 'your-session-id-here';
*/

-- =====================================================
-- CLEANUP (Jika perlu rollback - JANGAN DIJALANKAN)
-- =====================================================

/*
DROP FUNCTION IF EXISTS decrement_upvote(uuid);
DROP FUNCTION IF EXISTS increment_upvote(uuid);
DROP TABLE IF EXISTS question_upvotes CASCADE;
ALTER TABLE questions DROP COLUMN IF EXISTS is_anonymous;
ALTER TABLE questions DROP COLUMN IF EXISTS upvotes_count;
*/
