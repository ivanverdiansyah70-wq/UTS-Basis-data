-- =========================================================
-- SkillConnect - Latihan Query SQL (untuk dihafal)
-- Jalankan setelah skillconnect.sql. Urutan dari mudah ke sulit.
-- Pola umum SELECT (urutan penulisan WAJIB):
--   SELECT ... FROM ... JOIN ... ON ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT ...
-- =========================================================
USE skillconnect;

-- =========================================================
-- LEVEL 1: SELECT DASAR (1 tabel)
-- =========================================================

-- 1.1 Tampilkan semua kategori
SELECT * FROM kategori;

-- 1.2 Tampilkan nama dan email semua mahasiswa
SELECT nama, email FROM users WHERE role = 'mahasiswa';

-- 1.3 Job yang masih open, budget terbesar di atas
SELECT judul, budget, deadline
FROM job
WHERE status = 'open'
ORDER BY budget DESC;

-- 1.4 Job dengan budget antara 500 ribu dan 1,5 juta
SELECT judul, budget FROM job WHERE budget BETWEEN 500000 AND 1500000;

-- 1.5 Cari job yang judulnya mengandung kata 'Desain'
SELECT judul, status FROM job WHERE judul LIKE '%Desain%';

-- 1.6 Client bertipe UMKM atau Komunitas
SELECT * FROM client WHERE tipe_client IN ('UMKM', 'Komunitas');

-- 1.7 5 job terbaru
SELECT judul, created_at FROM job ORDER BY created_at DESC LIMIT 5;


-- =========================================================
-- LEVEL 2: JOIN (menggabungkan tabel lewat FK)
-- =========================================================

-- 2.1 Job beserta nama client dan kategorinya
SELECT j.judul, u.nama AS nama_client, k.nama_kategori, j.budget, j.status
FROM job j
JOIN users u    ON j.id_client = u.id_user
JOIN kategori k ON j.id_kategori = k.id_kategori;

-- 2.2 Daftar skill tiap mahasiswa
SELECT u.nama, s.nama_skill, ms.level
FROM mahasiswa_skill ms
JOIN users u ON ms.id_mahasiswa = u.id_user
JOIN skill s ON ms.id_skill = s.id_skill
ORDER BY u.nama;

-- 2.3 Siapa saja yang melamar job nomor 1?
SELECT u.nama, l.harga_tawaran, l.status
FROM lamaran l
JOIN users u ON l.id_mahasiswa = u.id_user
WHERE l.id_job = 1;

-- 2.4 Detail proyek: judul job, client, mahasiswa, harga deal (JOIN 4 tabel)
SELECT p.id_proyek, j.judul,
       uc.nama AS client, um.nama AS mahasiswa,
       p.harga_deal, p.status
FROM proyek p
JOIN lamaran l ON p.id_lamaran = l.id_lamaran
JOIN job j     ON l.id_job = j.id_job
JOIN users uc  ON j.id_client = uc.id_user
JOIN users um  ON l.id_mahasiswa = um.id_user;

-- 2.5 LEFT JOIN: semua mahasiswa beserta jumlah portfolio (termasuk yang 0)
SELECT u.nama, COUNT(pf.id_portfolio) AS jumlah_portfolio
FROM mahasiswa m
JOIN users u          ON m.id_mahasiswa = u.id_user
LEFT JOIN portfolio pf ON m.id_mahasiswa = pf.id_mahasiswa
GROUP BY u.nama;

-- 2.6 Isi chat untuk job nomor 1 (pengirim -> penerima)
SELECT ps.waktu_kirim, a.nama AS dari, b.nama AS ke, ps.isi_pesan
FROM pesan ps
JOIN users a ON ps.id_pengirim = a.id_user
JOIN users b ON ps.id_penerima = b.id_user
WHERE ps.id_job = 1
ORDER BY ps.waktu_kirim;


-- =========================================================
-- LEVEL 3: AGREGASI (COUNT, SUM, AVG, MAX, MIN + GROUP BY + HAVING)
-- =========================================================

-- 3.1 Jumlah user per role
SELECT role, COUNT(*) AS jumlah FROM users GROUP BY role;

-- 3.2 Jumlah job dan rata-rata budget per kategori
SELECT k.nama_kategori, COUNT(j.id_job) AS jumlah_job, AVG(j.budget) AS rata_budget
FROM kategori k
LEFT JOIN job j ON k.id_kategori = j.id_kategori
GROUP BY k.nama_kategori
ORDER BY jumlah_job DESC;

-- 3.3 Total pendapatan (pembayaran lunas)
SELECT SUM(jumlah) AS total_pendapatan FROM pembayaran WHERE status = 'lunas';

-- 3.4 Rata-rata rating yang diterima tiap mahasiswa
SELECT u.nama, ROUND(AVG(r.rating), 2) AS rata_rating, COUNT(*) AS jumlah_review
FROM review r
JOIN users u ON r.id_penerima = u.id_user
WHERE u.role = 'mahasiswa'
GROUP BY u.nama
ORDER BY rata_rating DESC;

-- 3.5 HAVING: mahasiswa yang melamar lebih dari 10 kali
SELECT u.nama, COUNT(*) AS jumlah_lamaran
FROM lamaran l
JOIN users u ON l.id_mahasiswa = u.id_user
GROUP BY u.nama
HAVING COUNT(*) > 10;

-- 3.6 Pendapatan per bulan
SELECT DATE_FORMAT(tanggal_bayar, '%Y-%m') AS bulan, SUM(jumlah) AS pendapatan
FROM pembayaran
WHERE status = 'lunas'
GROUP BY bulan
ORDER BY bulan;


-- =========================================================
-- LEVEL 4: SUBQUERY
-- =========================================================

-- 4.1 Job dengan budget di atas rata-rata
SELECT judul, budget FROM job
WHERE budget > (SELECT AVG(budget) FROM job);

-- 4.2 Mahasiswa yang belum pernah melamar job apa pun
SELECT nama FROM users
WHERE role = 'mahasiswa'
  AND id_user NOT IN (SELECT id_mahasiswa FROM lamaran);

-- 4.3 Mahasiswa yang punya skill 'Laravel'
SELECT nama FROM users
WHERE id_user IN (
    SELECT ms.id_mahasiswa FROM mahasiswa_skill ms
    JOIN skill s ON ms.id_skill = s.id_skill
    WHERE s.nama_skill = 'Laravel'
);

-- 4.4 Rekomendasi: job open yang skill-nya cocok dengan skill mahasiswa id 5 (Dewi)
SELECT DISTINCT j.judul, j.budget
FROM job j
JOIN job_skill js ON j.id_job = js.id_job
WHERE j.status = 'open'
  AND js.id_skill IN (SELECT id_skill FROM mahasiswa_skill WHERE id_mahasiswa = 5);

-- 4.5 Client yang belum pernah posting job
SELECT u.nama, c.nama_instansi
FROM client c
JOIN users u ON c.id_client = u.id_user
WHERE c.id_client NOT IN (SELECT id_client FROM job);


-- =========================================================
-- LEVEL 5: DML (INSERT, UPDATE, DELETE) - skenario alur sistem
-- Dibungkus TRANSACTION + ROLLBACK supaya data asli tidak berubah.
-- Ganti ROLLBACK dengan COMMIT jika ingin perubahan disimpan.
-- =========================================================
START TRANSACTION;

-- 5.1 Client (id 17) posting job baru
INSERT INTO job (id_client, id_kategori, judul, deskripsi, budget, deadline)
VALUES (17, 1, 'Desain Menu Kafe', 'Butuh desain menu A3 dua sisi.', 400000, '2026-11-30');

-- 5.2 Mahasiswa (id 3) melamar job tersebut
INSERT INTO lamaran (id_job, id_mahasiswa, harga_tawaran, pesan_lamaran)
VALUES (LAST_INSERT_ID(), 3, 375000, 'Saya siap mengerjakan dalam 5 hari.');

-- 5.3 Client menerima lamaran -> update status lamaran dan job
UPDATE lamaran SET status = 'diterima' WHERE id_lamaran = LAST_INSERT_ID();
UPDATE job SET status = 'in_progress' WHERE judul = 'Desain Menu Kafe';

-- 5.4 Admin menonaktifkan akun
UPDATE users SET status_akun = 'nonaktif' WHERE id_user = 28;

-- 5.5 Mahasiswa menghapus salah satu portfolionya
DELETE FROM portfolio WHERE id_portfolio = 1;

SELECT * FROM job ORDER BY id_job DESC LIMIT 1;  -- cek hasil
ROLLBACK;


-- =========================================================
-- LEVEL 6: VIEW untuk Power BI
-- View = query yang disimpan dan bisa dipanggil seperti tabel.
-- =========================================================

-- 6.1 Pendapatan per bulan
CREATE OR REPLACE VIEW v_pendapatan_bulanan AS
SELECT DATE_FORMAT(tanggal_bayar, '%Y-%m') AS bulan,
       COUNT(*)    AS jumlah_transaksi,
       SUM(jumlah) AS total_pendapatan
FROM pembayaran
WHERE status = 'lunas'
GROUP BY DATE_FORMAT(tanggal_bayar, '%Y-%m');

-- 6.2 Ringkasan job per kategori
CREATE OR REPLACE VIEW v_job_per_kategori AS
SELECT k.nama_kategori,
       COUNT(j.id_job) AS jumlah_job,
       SUM(j.status = 'completed') AS job_selesai,
       ROUND(AVG(j.budget), 0) AS rata_budget
FROM kategori k
LEFT JOIN job j ON k.id_kategori = j.id_kategori
GROUP BY k.nama_kategori;

-- 6.3 Peringkat freelancer (proyek selesai, pendapatan, rating)
CREATE OR REPLACE VIEW v_top_freelancer AS
SELECT u.id_user AS id_mahasiswa, u.nama, m.universitas, m.jurusan,
       (SELECT COUNT(*) FROM proyek p JOIN lamaran l ON p.id_lamaran = l.id_lamaran
         WHERE l.id_mahasiswa = m.id_mahasiswa AND p.status = 'selesai') AS proyek_selesai,
       (SELECT COALESCE(SUM(b.jumlah), 0) FROM pembayaran b
         JOIN proyek p  ON b.id_proyek = p.id_proyek
         JOIN lamaran l ON p.id_lamaran = l.id_lamaran
         WHERE l.id_mahasiswa = m.id_mahasiswa AND b.status = 'lunas') AS total_pendapatan,
       (SELECT ROUND(AVG(r.rating), 2) FROM review r
         WHERE r.id_penerima = m.id_mahasiswa) AS rata_rating
FROM mahasiswa m
JOIN users u ON m.id_mahasiswa = u.id_user;

-- 6.4 Skill paling dicari vs jumlah mahasiswa yang punya
CREATE OR REPLACE VIEW v_skill_populer AS
SELECT s.nama_skill, k.nama_kategori,
       (SELECT COUNT(*) FROM job_skill js WHERE js.id_skill = s.id_skill) AS dicari_job,
       (SELECT COUNT(*) FROM mahasiswa_skill ms WHERE ms.id_skill = s.id_skill) AS dimiliki_mahasiswa
FROM skill s
JOIN kategori k ON s.id_kategori = k.id_kategori;

-- 6.5 Status lamaran
CREATE OR REPLACE VIEW v_status_lamaran AS
SELECT status, COUNT(*) AS jumlah FROM lamaran GROUP BY status;

-- 6.6 Aktivitas per tipe client
CREATE OR REPLACE VIEW v_tipe_client AS
SELECT c.tipe_client,
       COUNT(DISTINCT c.id_client) AS jumlah_client,
       COUNT(j.id_job) AS jumlah_job,
       COALESCE(SUM(j.budget), 0) AS total_budget
FROM client c
LEFT JOIN job j ON c.id_client = j.id_client
GROUP BY c.tipe_client;

-- 6.7 Tabel detail proyek (dipakai untuk slicer/filter di Power BI)
CREATE OR REPLACE VIEW v_detail_proyek AS
SELECT p.id_proyek, j.judul, k.nama_kategori,
       uc.nama AS client, c.tipe_client,
       um.nama AS mahasiswa, m.universitas,
       p.harga_deal, p.tgl_mulai, p.tgl_selesai, p.status,
       DATEDIFF(p.tgl_selesai, p.tgl_mulai) AS durasi_hari,
       (SELECT r.rating FROM review r
         WHERE r.id_proyek = p.id_proyek AND r.id_penerima = um.id_user) AS rating_mahasiswa
FROM proyek p
JOIN lamaran l   ON p.id_lamaran = l.id_lamaran
JOIN job j       ON l.id_job = j.id_job
JOIN kategori k  ON j.id_kategori = k.id_kategori
JOIN client c    ON j.id_client = c.id_client
JOIN users uc    ON c.id_client = uc.id_user
JOIN mahasiswa m ON l.id_mahasiswa = m.id_mahasiswa
JOIN users um    ON m.id_mahasiswa = um.id_user;

-- Cek view
SELECT * FROM v_top_freelancer ORDER BY total_pendapatan DESC LIMIT 5;
