# HƯỚNG DẪN TRIỂN KHAI HỆ THỐNG HOSO365 LÊN NỀN TẢNG VERCEL & SUPABASE
**Trường THPT Lê Hồng Phong (quận Hà Đông, Hà Nội)**
*Phương án 2: Mô hình Serverless / Cloud BaaS Hoàn Toàn Miễn Phí (Chi phí: 0 VNĐ/tháng)*

---

## 1. TỔNG QUAN KIẾN TRÚC PHƯƠNG ÁN 2

```
                           +-------------------------------------+
                           |      Trình duyệt Giáo viên (50 GV)  |
                           |   PC / Laptop / Điện thoại di động  |
                           +-------------------------------------+
                                              |
                                              | (HTTPS / SSL Miễn phí)
                                              v
                           +-------------------------------------+
                           |       VERCEL / NETLIFY EDGE         |
                           |   (Host website, CDN cực nhanh)     |
                           |   Subdomain: hoso.thptlehongphong...|
                           +-------------------------------------+
                                     /                   \
                                    /                     \
        (Dữ liệu sổ sách, báo giảng)                       (File giáo án, Word, PDF)
                                  v                         v
        +-----------------------------------+    +------------------------------------+
        |         SUPABASE CLOUD            |    |       SUPABASE STORAGE BUCKET      |
        |  - PostgreSQL Database (500 MB)   |    |    - Bucket: 'giao-an-tai-lieu'    |
        |  - Đồng bộ Realtime               |    |    - Miễn phí 1 GB - 10 GB         |
        |  - Bảo mật Row Level Security     |    |    - Không tốn phí băng thông tải  |
        +-----------------------------------+    +------------------------------------+
```

* **Chi phí duy trì:** **0 VNĐ / tháng** (gói Free vĩnh viễn của Vercel và Supabase).
* **Số lượng phục vụ:** Dư sức phục vụ 50 giáo viên trường THPT Lê Hồng Phong truy cập đồng thời.
* **Bảo mật:** Tự động kích hoạt chứng chỉ SSL/HTTPS (bắt buộc để USB Token IntrustCA ký số hợp lệ).

---

## 2. BƯỚC 1: KHỞI TẠO CƠ SỞ DỮ LIỆU & LƯU TRỮ TRÊN SUPABASE (3 PHÚT)

1. Truy cập [https://supabase.com](https://supabase.com) và bấm **"Start your project"** (Đăng nhập bằng tài khoản Google hoặc GitHub).
2. Bấm **"New Project"**:
   * **Name:** `HoSo365-THPT-LeHongPhong`
   * **Database Password:** Đặt mật khẩu an toàn (lưu lại mật khẩu này).
   * **Region:** Chọn **Southeast Asia (Singapore)** (gần Việt Nam nhất, tốc độ cao nhất).
   * **Pricing Plan:** Chọn **Free tier ($0/month)**.
   * Bấm **"Create new project"** và chờ khoảng 1–2 phút để hệ thống tạo xong.
3. Chạy file khởi tạo dữ liệu:
   * Ở thanh menu bên trái Supabase, chọn mục **SQL Editor** (biểu tượng `>_`).
   * Mở file [`supabase_schema.sql`](file:///d:/CLAUDE/HoSo365/supabase_schema.sql) trong thư mục dự án, sao chép toàn bộ nội dung và dán vào ô SQL Editor.
   * Bấm nút **Run** (màu xanh lá).
   * *Kết quả:* Toàn bộ các bảng (`school_configs`, `profiles`, `lessons`, `weekly_plans`, `lesson_materials`, `audit_logs`) và Bucket lưu trữ file `giao-an-tai-lieu` sẽ được tạo tự động 100%.
4. Lấy thông tin kết nối API:
   * Vào **Project Settings** (biểu tượng bánh răng ở góc dưới bên trái) $\rightarrow$ chọn **API**.
   * Sao chép 2 thông số:
     * **Project URL**: dạng `https://[mã-dự-án].supabase.co`
     * **Project API keys (anon public)**: chuỗi ký tự dài bắt đầu bằng `eyJ...`

---

## 3. BƯỚC 2: TRIỂN KHAI WEBSITE LÊN VERCEL (2 PHÚT)

### Cách A: Triển khai siêu nhanh qua giao diện kéo-thả (Không cần gõ lệnh)
1. Truy cập [https://vercel.com](https://vercel.com) và đăng nhập (bằng GitHub hoặc tài khoản Google).
2. Cài đặt tiện ích Vercel CLI hoặc đẩy thư mục `d:\CLAUDE\HoSo365` lên một kho lưu trữ **GitHub** (chế độ Private hoặc Public).
3. Tại trang chủ Vercel, bấm **"Add New..."** $\rightarrow$ **"Project"** $\rightarrow$ Chọn Repository GitHub vừa tạo.
4. Tại mục **Build and Output Settings**: Giữ nguyên mặc định (thư mục gốc).
5. Bấm **"Deploy"**.
6. Chỉ sau 30 giây, Vercel sẽ cung cấp một đường link truy cập trực tuyến miễn phí có HTTPS (Ví dụ: `https://hoso365-lehongphong.vercel.app`).

### Cách B: Triển khai qua Netlify (Kéo thả thư mục)
1. Truy cập [https://app.netlify.com](https://app.netlify.com).
2. Kéo thả toàn bộ thư mục `d:\CLAUDE\HoSo365` vào ô **"Want to deploy a new site without connecting to Git? Drag and drop your project folder here"**.
3. Netlify tự động nhận diện file `netlify.toml` và cấp ngay link trực tiếp có HTTPS.

---

## 4. BƯỚC 3: KẾT NỐI HỆ THỐNG VỚI SUPABASE & KÍCH HOẠT LƯU TRỮ

1. Mở trang web HoSo365 đã triển khai trên Vercel.
2. Đăng nhập với vai trò **Ban Giám Hiệu** $\rightarrow$ Vào menu **Cài Đặt Hệ Thống**.
3. Cuộn xuống mục **"5. Kết Nối Nền Tảng Cloud BaaS (Supabase & Storage)"**:
   * Dán **Supabase Project URL** vừa lấy ở Bước 1.
   * Dán **Supabase Anon Key** vừa lấy ở Bước 1.
   * Bucket lưu trữ file: Giữ nguyên `giao-an-tai-lieu`.
   * Bấm nút **"Kiểm tra kết nối Supabase (Ping Test)"** $\rightarrow$ Hệ thống báo thành công màu xanh!
   * Bấm **"Lưu Cấu Hình Vận Hành"**.

> **Lưu ý tiện lợi:** Hệ thống có cơ chế tự thích ứng linh hoạt:
> * Khi **chưa nhập key Supabase**: Website vẫn hoạt động bình thường ở chế độ lưu trữ cục bộ (Offline / LocalStorage demo).
> * Khi **đã nhập key Supabase**: Toàn bộ lịch báo giảng, sổ đầu bài, và các file giáo án tải lên sẽ lập tức được đồng bộ lên máy chủ đám mây Supabase an toàn.

---

## 5. BƯỚC 4: GẮN TÊN MIỀN TRƯỜNG THPT LÊ HỒNG PHONG (TÙY CHỌN)

Nếu nhà trường muốn giáo viên truy cập qua tên miền chính thức của trường (Ví dụ: `hoso.thptlehongphong.edu.vn`):
1. Trong Vercel: Vào **Project Settings** $\rightarrow$ **Domains** $\rightarrow$ Nhập `hoso.thptlehongphong.edu.vn`.
2. Vercel sẽ hiển thị bản ghi CNAME (ví dụ: `cname.vercel-dns.com`).
3. Giáo viên quản trị mạng của trường đăng nhập vào trang quản lý tên miền của trường (tại Viettel, VNPT hoặc Mắt Bão) và thêm 1 bản ghi:
   * **Host:** `hoso`
   * **Type:** `CNAME`
   * **Value:** `cname.vercel-dns.com`
4. Sau 5-10 phút, tên miền sẽ hoạt động với chứng chỉ bảo mật SSL xanh chính chủ hoàn toàn miễn phí.

---

## 6. HƯỚNG DẪN 50 GIÁO VIÊN SỬ DỤNG 4 CÔNG VIỆC CHÍNH

### 1. Báo giảng tuần (Lịch báo giảng):
* Giáo viên vào tab **Lịch báo giảng tuần**.
* Có 2 cách:
  * **Cách 1 (Khuyên dùng):** Bấm **"Tải file mẫu Excel"** $\rightarrow$ Điền phân phối tiết (hỗ trợ cả tiết Chính khóa, `TC1, TC2...` tăng cường, `CĐ1, CĐ2...` chuyên đề) $\rightarrow$ Bấm **"Nhập từ Excel (.xlsx)"** $\rightarrow$ Hệ thống tự động nhận diện và đồng bộ sang Sổ đầu bài.
  * **Cách 2:** Bấm **"Thêm tiết kế hoạch"** để thêm từng tiết trực tiếp trên web.
* Bấm **"Ký nộp Tổ trưởng"** để hoàn tất quy trình.

### 2. Kiểm tra Thời khóa biểu:
* Lịch báo giảng hiển thị trực quan theo từng ngày (Thứ 2 đến Thứ 7), từng tiết (1 đến 5 buổi sáng, 6 đến 10 buổi chiều) kèm theo phòng học và thiết bị dạy học cần chuẩn bị.

### 3. Ký số Sổ đầu bài điện tử (IntrustCA):
* Tại trang chủ, hệ thống nhắc nhở tiết học vừa kết thúc.
* Bấm **"Điền & Ký ngay (10s)"**:
  * Tên bài và tiết PPCT tự động điền từ Lịch báo giảng.
  * Sĩ số và học sinh nghỉ vắng tự động đồng bộ từ **eNetViet**.
  * Điểm số tự động cộng chuẩn bước nhảy 0.5; nếu vắng $\ge 3$ học sinh sẽ tự khoá Chuyên cần = 0.
  * Cắm USB Token **IntrustCA** vào máy tính $\rightarrow$ Bấm **"Ký số & Hoàn tất tiết học"** (chuẩn mã hoá an toàn quốc gia).

### 4. Tải file tài liệu, giáo án lên báo cáo:
* Giáo viên vào tab **Kế hoạch bài dạy & Giáo án (CV 5512)**.
* Bấm **"Tải lên tệp Giáo án / Tài liệu báo cáo"**.
* Kéo thả file Word (`.docx`), PDF (`.pdf`), PowerPoint (`.pptx`) hoặc Excel (`.xlsx`) $\rightarrow$ File tự động tải lên Supabase Storage với dung lượng tối đa 50MB/file.
* Tổ trưởng chuyên môn và Ban Giám Hiệu có thể xem, tải về và bấm **"Ký duyệt số"** ngay trên giao diện.
