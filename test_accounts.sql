-- =====================================================
-- TEST ACCOUNTS - ASKUP+
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- 1. BUAT AKUN LECTURER (DOSEN)
INSERT INTO users (email, name, role, password, department, employee_id)
VALUES 
  ('dosen@askup.com', 'Prof. Budi Santoso', 'lecturer', 'dosen123', 'Computer Science', 'EMP001'),
  ('lecturer@test.com', 'Dr. Siti Nurhaliza', 'lecturer', 'lecturer123', 'Information Systems', 'EMP002')
ON CONFLICT (email) DO NOTHING;

-- 2. BUAT AKUN STUDENT (MAHASISWA)
INSERT INTO users (email, name, role, password)
VALUES 
  ('mahasiswa@askup.com', 'Andi Wijaya', 'student', 'mhs123'),
  ('student@test.com', 'Budi Pratama', 'student', 'student123'),
  ('test@student.com', 'Citra Dewi', 'student', 'test123')
ON CONFLICT (email) DO NOTHING;

-- 3. VERIFY AKUN YANG SUDAH DIBUAT
SELECT id, email, name, role, password, created_at 
FROM users 
WHERE role IN ('lecturer', 'student')
ORDER BY role, created_at DESC;

-- =====================================================
-- KREDENSIAL LOGIN
-- =====================================================

/*
LECTURER:
---------
Email: dosen@askup.com
Password: dosen123

Email: lecturer@test.com
Password: lecturer123

STUDENT:
--------
Email: mahasiswa@askup.com
Password: mhs123

Email: student@test.com
Password: student123

Email: test@student.com
Password: test123
*/

-- =====================================================
-- QUERY UTILITY
-- =====================================================

-- Lihat semua users
SELECT id, email, name, role FROM users ORDER BY created_at DESC;

-- Lihat hanya lecturer
SELECT id, email, name, department, employee_id FROM users WHERE role = 'lecturer';

-- Lihat hanya student
SELECT id, email, name FROM users WHERE role = 'student';

-- Hapus user tertentu (jika perlu)
-- DELETE FROM users WHERE email = 'email@example.com';
