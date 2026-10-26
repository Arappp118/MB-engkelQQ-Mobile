# LAPORAN HASIL END-TO-END (E2E) BUSINESS FLOW TESTING
## INTEGRASI SISTEM MB-ENGKELQQ MOBILE & BACKEND LARAVEL

- **Metode Pengujian:** Pengujian Alur Terpadu Lintas Role (*Customer, Admin, Mekanik, Kurir*)
- **Lingkungan Eksekusi:** Backend Laravel Feature E2E Testing & Flutter State Simulation
- **Hasil Akhir:** **4/4 ALUR UTAMA LULUS 100% (ALL PASS)**

---

## 1. FLOW A — ALUR BISNIS CUSTOMER (PELANGGAN)

### Skenario & Langkah Eksekusi:
1. **Autentikasi:** Customer login menggunakan `POST /api/v1/auth/login`. Server menerbitkan token Sanctum; token tersimpan di Flutter SecureStorage.
2. **Dashboard & Profil:** Memanggil `GET /api/v1/auth/me` dan `GET /api/v1/dashboard`. Menampilkan ringkasan jumlah kendaraan, booking aktif, dan tagihan pending.
3. **Pendaftaran Kendaraan:** Customer menambahkan unit motor baru (`POST /api/v1/vehicles`) dengan nomor polisi, merk, model, tipe mesin (`4-tak`), dan transmisi (`matic`).
4. **Pembuatan Booking:** Customer membuat booking baru (`POST /api/v1/bookings`) memilih layanan `service_rutin`, keluhan servis berkala, dan memilih layanan pickup unit di wilayah Kota Tanjungpinang.
5. **Monitoring Servis:** Customer memantau transisi pengerjaan dari `pending` $\rightarrow$ `confirmed` $\rightarrow$ `in_progress`.
6. **Pemeriksaan Invoice:** Saat pengerjaan selesai (`completed`), customer membuka detail tagihan invoice (`GET /api/v1/invoices/{order_id}`) dengan rincian snapshot biaya yang terkunci.
7. **Pengajuan Pembayaran:**
   - *Kasus Tunai:* Customer memilih pembayaran tunai tanpa syarat file struk.
   - *Kasus Transfer / QRIS:* Customer mengunggah foto bukti transfer berformat PNG (< 2MB).
8. **Notifikasi:** Customer menerima notifikasi otomatis atas konfirmasi booking dan penyelesaian pengerjaan, lalu menandai notifikasi sebagai dibaca (`POST /api/v1/notifications/{id}/read`).
9. **Logout:** Sesi diakhiri via `POST /api/v1/auth/logout`.

**Hasil Pengujian:** **PASS** (Terverifikasi di `Tests\Feature\EndToEndBusinessFlowTest::test_flow_1_service_biasa_end_to_end` dan `test/role_integration_regression_test.dart`).

---

## 2. FLOW B — ALUR BISNIS ADMIN BENGKEL

### Skenario & Langkah Eksekusi:
1. **Autentikasi & Dashboard:** Admin login dan memantau metrik agregasi operasional bengkel (`total_bookings`, `active_bookings`, `payment_pending`, `delivery_task_total`).
2. **Konfirmasi Booking Pelanggan:** Admin mengonfirmasi booking berstatus `pending` (`POST /api/v1/bookings/{id}/confirm`). Backend secara otomatis:
   - Mengubah status booking menjadi `confirmed`.
   - Meng-generate entri `service_order` baru.
   - Menugaskan mekanik yang tersedia secara otomatis (*auto-assignment*).
3. **Penugasan Kurir Pickup / Delivery:** Admin membuka daftar tugas pengiriman (`GET /api/v1/delivery-tasks`) dan menugaskan kurir via `POST /api/v1/delivery-tasks/{id}/assign`.
4. **Verifikasi Pembayaran Pelanggan:**
   - Admin memeriksa bukti transfer pada daftar pembayaran `waiting_verification`.
   - Jika bukti sah, Admin menyetujui (`POST /api/v1/payments/{id}/verify`). Transaksi berstatus `verified`, order lunas, dan waktu `paid_at` tercatat.
   - Jika bukti tidak sesuai, Admin menolak (`POST /api/v1/payments/{id}/reject`) dengan alasan penolakan, memungkinkan customer mengunggah ulang.
5. **Pencatatan Audit Trail:** Seluruh aksi konfirmasi, penugasan, dan verifikasi admin terekam di tabel `audit_logs` server.

**Hasil Pengujian:** **PASS** (Terverifikasi di `Tests\Feature\Api\PaymentApiTest`, `Tests\Feature\Api\BookingApiTest`, dan `test/admin_payment_test.dart`).

---

## 3. FLOW C — ALUR OPERASIONAL MEKANIK

### Skenario & Langkah Eksekusi:
1. **Autentikasi & Daftar Pekerjaan:** Mekanik login dan membuka daftar `ServiceOrder` miliknya (`GET /api/v1/service-orders`). Sistem memfilter order secara ketat sesuai `mechanic_id`.
2. **Mulai Servis:** Mekanik menekan tombol **Mulai Servis** (`POST /api/v1/service-orders/{id}/start`). Status order berubah menjadi `in_progress`.
3. **Input Diagnosis:** Mekanik mendiagnosis kendaraan dan menginput catatan teknis (`POST /api/v1/service-orders/{id}/diagnosis`).
4. **Penambahan Jasa & Sparepart:**
   - Mekanik memilih sparepart oli mesin matic dan kampas rem dari katalog aktif (`GET /api/v1/service-items`).
   - Mekanik mengirimkan request tambah item (`POST /api/v1/service-orders/{id}/items`) dengan kuantitas valid.
   - Server mengunci baris database, memvalidasi stok, mengurangi stok sparepart master secara riil, mencatat snapshot harga resmi, dan menghitung subtotal/grand total baru.
5. **Penyelesaian Servis:**
   - Jika mekanik mencoba menyelesaikan servis tanpa diagnosis/item, server menolak (Aturan Bisnis BR-012).
   - Setelah item dan diagnosis lengkap, mekanik menekan **Selesaikan Servis** (`POST /api/v1/service-orders/{id}/complete`). Status berubah menjadi `completed` dan siap untuk proses pembayaran.

**Hasil Pengujian:** **PASS** (Terverifikasi di `Tests\Feature\Api\ServiceOrderApiTest`, `Tests\Feature\PriceSnapshotTest`, dan `test/qa_regression_test.dart`).

---

## 4. FLOW D — ALUR TUGAS KURIR (PICKUP & DELIVERY)

### Skenario & Langkah Eksekusi:
1. **Autentikasi & Daftar Tugas:** Kurir login dan membaca daftar tugas penjemputan/pengantaran unit kendaraan (`GET /api/v1/delivery-tasks`).
2. **Detail Tugas & Rute Alamat:** Kurir membuka detail tugas, melihat nomor telepon customer, dan meninjau alamat penjemputan/pengantaran (dengan deduplikasi segmen alamat rapi tanpa redundancy teks).
3. **Mulai Tugas Pengiriman:** Kurir menekan tombol **Mulai Pengiriman** (`POST /api/v1/delivery-tasks/{id}/start`). Status task bertransisi menjadi `in_transit`.
4. **Navigasi Peta:** Aplikasi memanggil Google Maps intent atau membuka peta interaktif viewer dengan titik koordinat customer dan bengkel resmi Tanjungpinang.
5. **Selesaikan Tugas:** Setelah motor tiba di bengkel (pickup) atau diserahkan ke pelanggan (delivery), kurir menyelesaikan tugas via `POST /api/v1/delivery-tasks/{id}/complete` dengan catatan serah terima.

**Hasil Pengujian:** **PASS** (Terverifikasi di `Tests\Feature\EndToEndBusinessFlowTest::test_flow_2_pickup_and_delivery_end_to_end` dan `test/role_integration_regression_test.dart`).

---

## 5. HASIL VERIFIKASI LANGSUNG PADA ANDROID EMULATOR (RUNTIME LIVE E2E)

- **Perangkat Emulator (AVD):** `flutter_pixel_api_36`
- **Arsitektur & Versi OS:** Android 16 (API Level 36), `x86_64` (`sdk_gphone64_x86_64`)
- **Status Boot Android:** `sys.boot_completed = 1` (Device Online)
- **Aplikasi (Target):** `com.example.mb_engkelqq_mobile/.MainActivity`
- **Status Instalasi APK:** `adb install -r build/app/outputs/flutter-apk/app-debug.apk` $\rightarrow$ **Success**
  - SHA-256 APK: `fc90d87429097dc1840366cc6921f60b1751649d8beb9b5230642fcb145731d4` (199,617,610 bytes)
- **Jembatan Jaringan Backend:** Host `10.0.2.2:8000` & `127.0.0.1:8000` (`adb reverse tcp:8000 tcp:8000`)
- **API Health Check dari Emulator:** `HTTP 200 OK` (`{"success":true,"message":"MotoCare API berjalan","data":{"version":"v1"}}`)
- **In-App Tes Koneksi Server:** Latensi `1164 ms` (*"Koneksi Berhasil! MotoCare API berjalan (v1)"*)

### Ringkasan Eksekusi Runtime Lintas Role pada Emulator:

| Role | Skenario Runtime yang Dieksekusi pada Layar Emulator | Status | Bukti Tangkapan Layar |
|:---|:---|:---:|:---|
| **Customer** | Pemulihan sesi SecureStorage, daftar kendaraan (Kawasaki Ninja & Honda Vario), formulir booking baru, bottom sheet profil akun, dialog konfigurasi API server live test (1164 ms), dan dialog konfirmasi logout. | **EMULATOR PASS** | `emulator_customer_kendaraan.png`, `emulator_booking_create_form.png`, `emulator_profile_sheet.png`, `emulator_tes_koneksi_success.png` |
| **Admin** | Autentikasi `admin@motocare.test`, Dashboard KPI (Total Booking: 21, Aktif: 12, Bayar Pending: 3), filter status booking (Semua 15, Pending 2, Aktif 12, Selesai 5), detail Booking #21, navigasi tab **Kelola Pembayaran** (menampilkan Booking #MC202610060001, Order #8, Tagihan Rp 55.000, tombol Input Verifikasi Manual), navigasi tab **Delivery Tasks** (Pickup Task #11, Assign Courier action), layar **Notifikasi** (peringatan pembayaran verifikasi order #14, #13, #12), dan konfirmasi logout. | **EMULATOR PASS** | `emulator_admin_logged_in.png`, `emulator_admin_payments.png`, `emulator_admin_delivery.png`, `emulator_admin_notifications.png` |
| **Mechanic** | Autentikasi `mekanik@motocare.test`, Dashboard KPI (Antrean: 0, Dikerjakan: 2, Selesai: 9), Daftar Pekerjaan teknisi (Service Order #14 diagnosis "oli 3 bulan", Service Order #12), tombol aksi "Lihat Detail", navigasi tab bar, dan konfirmasi logout. | **EMULATOR PASS** | `emulator_mechanic_logged_in.png` |
| **Courier** | Autentikasi `kurir@motocare.test`, Dashboard KPI (Menunggu: 0, Aktif: 0, Selesai: 7), Daftar Tugas Pengantaran (Pickup Task #10 Alamat Jl. Merdeka 2.5 km, Pickup Task #8), navigasi tab **Peta & Navigasi**, dialog izin lokasi runtime Android (Precise/While using app), rendering tile OpenStreetMap riil wilayah Tanjungpinang (Jalan WR Supratman, Melayu Kota Piring, Air Raja), dan kartu detail koordinat navigasi. | **EMULATOR PASS** | `emulator_courier_loaded.png`, `emulator_courier_map_final.png` |

---

## 6. HASIL PENYELESAIAN AUDIT PEMBAYARAN LIVE (`test/integration_test_sim.dart`)

- **Perintah Eksekusi:** `dart run test/integration_test_sim.dart`
- **Hasil Eksekusi:** **100% PASS (Exit Code 0)**
- **Verifikasi Kontrak Database & API:**
  1. **Enum Contract Truth:**
     - `service_orders.status` di backend Laravel secara resmi hanya memiliki nilai: `['pending', 'in_progress', 'completed']`.
     - Terdapat 10 service order berstatus `completed` yang merupakan order tuntas dan menjadi dasar terbitnya tagihan invoice.
     - `waiting_payment` adalah status pada model `Booking` dan filter label pada UI Flutter `AdminPaymentsPage`, bukan kolom `service_orders.status`.
     - `payments.status` menggunakan enum `['waiting_verification', 'verified', 'rejected']`.
  2. **Pengujian Alur Pembayaran Nyata:**
     - Login Admin dan fetch 13 service orders serta 15 bookings.
     - Inspeksi entri Payment #10 (metode Cash, nominal Rp 165.000, status awal `waiting_verification`).
     - Eksekusi verifikasi admin: `POST /api/v1/payments/10/verify` $\rightarrow$ merespons `HTTP 200 OK` (*"Pembayaran berhasil diverifikasi"*), status berubah menjadi `verified`, waktu `paid_at` tercatat di database.
     - Proteksi verifikasi ganda: Request ulang verifikasi pada Payment #10 $\rightarrow$ backend menolak dengan `HTTP 422 Unprocessable Entity` (*"Tidak dapat verifikasi payment dari status 'verified'"*).
     - Proteksi IDOR / Hak Akses: Login customer (`customer@motocare.test`) dan mencoba memverifikasi pembayaran $\rightarrow$ backend menolak dengan `HTTP 403 Forbidden`.

