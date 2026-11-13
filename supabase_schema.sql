-- =========================================================================
-- HỆ THỐNG HỒ SƠ GIÁO DỤC 365 (HoSo365) - TRƯỜNG THPT LÊ HỒNG PHONG (HÀ NỘI)
-- SUPABASE POSTGRESQL SCHEMA (PHƯƠNG ÁN 2: SERVERLESS / BAAS MIỄN PHÍ)
-- =========================================================================

-- Kích hoạt extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BẢNG CẤU HÌNH NHÀ TRƯỜNG & THAM SỐ LÃNH ĐẠO (school_configs)
CREATE TABLE IF NOT EXISTS school_configs (
    id TEXT PRIMARY KEY DEFAULT 'default',
    school_name TEXT NOT NULL DEFAULT 'Trường THPT Lê Hồng Phong (Hà Đông)',
    school_code TEXT NOT NULL DEFAULT 'THPT_LEHONGPHONG_HN',
    academic_year TEXT NOT NULL DEFAULT '2026-2027',
    total_weeks INT NOT NULL DEFAULT 35,
    semester1_weeks INT NOT NULL DEFAULT 18,
    semester2_weeks INT NOT NULL DEFAULT 17,
    daily_lock_time TEXT NOT NULL DEFAULT '17:30',
    emergency_unlock_window_hours INT NOT NULL DEFAULT 24,
    enetviet_sync BOOLEAN NOT NULL DEFAULT true,
    ca_provider TEXT NOT NULL DEFAULT 'IntrustCA',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BẢNG TÀI KHOẢN GIÁO VIÊN & PHÂN QUYỀN (profiles)
CREATE TABLE IF NOT EXISTS profiles (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT,
    role TEXT NOT NULL CHECK (role IN ('bgh', 'tt_toan', 'gv_minh', 'gv_lan', 'gv_hoa', 'admin')),
    role_title TEXT NOT NULL,
    subjects TEXT[] DEFAULT '{}',
    is_homeroom BOOLEAN DEFAULT false,
    homeroom_class TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. BẢNG SỔ ĐẦU BÀI ĐIỆN TỬ (lessons)
CREATE TABLE IF NOT EXISTS lessons (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    period INT NOT NULL CHECK (period BETWEEN 1 AND 10),
    class_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    ppct TEXT NOT NULL, -- Hỗ trợ: '28', 'TC1', 'TC2', 'CĐ1', 'CĐ2'
    sub_subject TEXT DEFAULT '—', -- 'Chính khóa', 'Tăng cường', 'Chuyên đề học tập'
    title TEXT NOT NULL,
    teacher_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
    teacher_name TEXT NOT NULL,
    attendance JSONB NOT NULL DEFAULT '{"total": 40, "present": 40, "absent": 0, "absentNames": "", "source": "eNetViet Auto"}',
    comment TEXT DEFAULT '',
    scores JSONB NOT NULL DEFAULT '{"ht": 4, "kl": 3, "vs": 2, "cc": 1, "total": 10, "xl": "Tốt"}',
    status TEXT NOT NULL DEFAULT 'empty' CHECK (status IN ('empty', 'pending', 'signed')),
    signed_at TIMESTAMPTZ,
    signed_cert TEXT,
    versions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. BẢNG LỊCH BÁO GIẢNG TUẦN (weekly_plans)
CREATE TABLE IF NOT EXISTS weekly_plans (
    id TEXT PRIMARY KEY,
    teacher_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
    academic_year TEXT NOT NULL DEFAULT '2026-2027',
    week INT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    approved_by_tcm TEXT,
    approved_at TIMESTAMPTZ,
    rows JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. BẢNG HỒ SƠ GIÁO ÁN & TÀI LIỆU BÁO CÁO (lesson_materials)
CREATE TABLE IF NOT EXISTS lesson_materials (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    teacher_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_name TEXT NOT NULL,
    subject TEXT NOT NULL,
    grade INT NOT NULL DEFAULT 10,
    week INT NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INT DEFAULT 0, -- Kích thước bytes
    file_type TEXT DEFAULT 'application/pdf',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    tcm_reviewer TEXT,
    activities JSONB DEFAULT '{"warmup": "", "knowledge": "", "practice": "", "application": ""}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. BẢNG NHẬT KÝ KIỂM TOÁN VẾT KÝ SỐ (audit_logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL,
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT DEFAULT '127.0.0.1',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================================
-- KHỞI TẠO BUCKET STORAGE TRÊN SUPABASE (giao-an-tai-lieu)
-- =========================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'giao-an-tai-lieu',
    'giao-an-tai-lieu',
    true,
    52428800, -- Giới hạn 50MB/file
    ARRAY[
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- Cho phép mọi người đọc file giáo án công khai (Public Read)
CREATE POLICY "Public Read Lesson Materials"
ON storage.objects FOR SELECT
USING (bucket_id = 'giao-an-tai-lieu');

-- Cho phép upload file vào bucket
CREATE POLICY "Allow Upload Lesson Materials"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'giao-an-tai-lieu');

-- Cho phép cập nhật/xóa file
CREATE POLICY "Allow Update/Delete Lesson Materials"
ON storage.objects FOR ALL
USING (bucket_id = 'giao-an-tai-lieu');

-- =========================================================================
-- KÍCH HOẠT BẢO MẬT ROW LEVEL SECURITY (RLS) & CHÍNH SÁCH
-- =========================================================================
ALTER TABLE school_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Cho phép đọc toàn bộ dữ liệu công khai (hoặc cho giáo viên đăng nhập)
CREATE POLICY "Public read school_configs" ON school_configs FOR ALL USING (true);
CREATE POLICY "Public read profiles" ON profiles FOR ALL USING (true);
CREATE POLICY "Public manage lessons" ON lessons FOR ALL USING (true);
CREATE POLICY "Public manage weekly_plans" ON weekly_plans FOR ALL USING (true);
CREATE POLICY "Public manage lesson_materials" ON lesson_materials FOR ALL USING (true);
CREATE POLICY "Public manage audit_logs" ON audit_logs FOR ALL USING (true);

-- =========================================================================
-- DỮ LIỆU MẪU BAN ĐẦU (SEED DATA - TRƯỜNG THPT LÊ HỒNG PHONG)
-- =========================================================================
INSERT INTO school_configs (id, school_name, school_code, academic_year, total_weeks)
VALUES ('default', 'Trường THPT Lê Hồng Phong (Hà Đông, Hà Nội)', 'THPT_LEHONGPHONG_HN', '2026-2027', 35)
ON CONFLICT (id) DO NOTHING;

INSERT INTO profiles (id, full_name, role, role_title, subjects, is_homeroom, homeroom_class)
VALUES 
    ('bgh', 'Thầy Lê Hoàng Long', 'bgh', 'Phó Hiệu trưởng phụ trách chuyên môn', ARRAY['Toán'], false, NULL),
    ('tt_toan', 'Thầy Trần Quốc Hưng', 'tt_toan', 'Tổ trưởng chuyên môn Toán', ARRAY['Toán'], true, '11A1'),
    ('gv_minh', 'Thầy Nguyễn Văn Minh', 'gv_minh', 'Giáo viên bộ môn Toán', ARRAY['Toán'], true, '10A1'),
    ('gv_lan', 'Cô Phạm Thị Lan', 'gv_lan', 'Giáo viên bộ môn Ngữ văn', ARRAY['Ngữ văn'], true, '10A2'),
    ('gv_hoa', 'Cô Đỗ Thị Mai Hoa', 'gv_hoa', 'Giáo viên môn Tiếng Anh', ARRAY['Tiếng Anh'], true, '10A3')
ON CONFLICT (id) DO NOTHING;

INSERT INTO audit_logs (user_name, action, details)
VALUES 
    ('Hệ thống', 'Khởi tạo cơ sở dữ liệu Supabase cho Trường THPT Lê Hồng Phong', '{"env": "Production Serverless"}'::jsonb);
