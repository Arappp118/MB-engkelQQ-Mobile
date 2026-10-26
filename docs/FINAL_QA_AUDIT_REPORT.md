# FINAL QA/QC CLOSURE & AUDIT REPORT — MB-ENGKELQQ (MOBILE & BACKEND)

- **Tanggal Pelaksanaan:** 26 Oktober 2026
- **Status Akhir Akseptasi:** **CONDITIONAL PASS — READY WITH LIMITATIONS**
- **Lead QA, Security, & Systems Reviewer:** Senior QA & Application Security Reviewer

---

## 1. PENUTUPAN TEMUAN KHUSUS (SPECIAL FINDINGS CLOSURE)

### 1.1 Penanganan Script `test/integration_test_sim.dart` & Pengujian Pembayaran Live
- **Karakteristik Script:** Berkas `test/integration_test_sim.dart` adalah skrip otomasi pengujian integrasi live HTTP client terhadap backend Laravel.
- **Investigasi Akar Masalah Enum Mismatch:**
  - Skrip versi lama mencoba memfilter raw JSON: `o['status'] == 'waiting_payment'`.
  - Di backend Laravel, enum resmi kolom `service_orders.status` adalah `['pending', 'in_progress', 'completed']`. Status yang menandakan servis selesai dan siap diterbitkan invoice/dibayar adalah `completed` (terdapat 10 entri `completed` di database).
  - Status `waiting_payment` / `service_completed` adalah status pada model `Booking` dan filter label di UI Flutter (`AdminPaymentsPage`), bukan kolom `service_orders.status`.
  - Model `Payment` menggunakan kolom status `waiting_verification`, `verified`, dan `rejected`.
- **Hasil Eksekusi Nyata:**
  Skrip diperbarui untuk menguji kontrak yang valid sesuai arsitektur backend, mencakup:
  1. Login Admin dan fetch 13 service orders & 15 bookings.
  2. Verifikasi Payment #10 (`waiting_verification` $\rightarrow$ `verified`, cash Rp 165.000) via `POST /api/v1/payments/10/verify` $\rightarrow$ **HTTP 200 OK** (`paid_at` tercatat).
  3. Uji proteksi double verification $\rightarrow$ **HTTP 422 Unprocessable Entity**.
  4. Uji proteksi IDOR hak akses customer $\rightarrow$ **HTTP 403 Forbidden**.
  - **Status:** **PASS 100% (Exit Code 0)** via `dart run test/integration_test_sim.dart`.

### 1.2 Inspeksi Database Laravel yang Benar
- **Diagnosis Kegagalan Sebelumnya:** Perintah `php -r "require 'bootstrap/app.php'; config(...)"` gagal karena pada Laravel 11 `bootstrap/app.php` mengembalikan `ApplicationBuilder`. Helper `config()` membutuhkan kernel aplikasi yang sudah ter-boot penuh.
- **Solusi Bersih Tanpa Mutasi Data:**
  - Menggunakan `php artisan tinker --execute="..."` yang me-load kernel dan service container penuh.
  - Memeriksa status migrasi via `php artisan migrate:status` (15/15 migrations ran).
  - Verifikasi pengguna test (`admin@motocare.test`, `mekanik@motocare.test`, `kurir@motocare.test`, `customer@motocare.test`) tanpa mencetak hash password atau data sensitif.

### 1.3 Penyebab dan Solusi `zsh: command not found: flutter`
- **Penyebab:** Konfigurasi `PATH` Flutter SDK (`/home/wh4mi/development/flutter/bin`) hanya tercatat di `~/.bashrc` dan `~/.profile`. Pengguna menggunakan shell `/usr/bin/zsh` yang membaca `~/.zshrc`.
- **Solusi Permanen untuk Pengguna:**
  Tambahkan ke `~/.zshrc`:
  ```bash
  export FLUTTER_HOME="$HOME/development/flutter"
  export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/android-studio/bin:$PATH"
  ```

---

## 2. KATEGORISASI & PEMISAHAN TIPE PENGUJIAN

Untuk memastikan transparansi dan akurasi klaim, seluruh pengujian diklasifikasikan secara ketat:

### A. Automated Unit & Widget Tests (Flutter) — **PASS**
- **Metode:** `flutter test` (120 test cases).
- **Cakupan:** Model parsing, state management provider, URL normalizer, widget lifecycle, geofence Tanjungpinang, responsive text scaling 1.4x.
- **Hasil:** **120 LULUS (100% Pass, 0 Gagal)**.

### B. Automated Feature & Security Tests (Laravel) — **PASS**
- **Metode:** `php artisan test` dengan database SQLite isolated in-memory (`:memory:`).
- **Cakupan:** 340 test cases (801 assertions), mencakup 160 API tests, IDOR protection, mass assignment, race conditions, atomic payment locks.
- **Hasil:** **340 LULUS (100% Pass, 0 Gagal)**.

### C. Live Backend API Testing — **PASS**
- **Metode:** Permintaan HTTP riil via curl ke `http://127.0.0.1:8000` dengan proses server aktif.
- **Hasil:** `GET /api/v1/health` merespons `HTTP 200 OK` (`{"success":true,"message":"MotoCare API berjalan","data":{"version":"v1"}}`).

### D. Live Integration Simulation (`test/integration_test_sim.dart`) — **PASS (100%)**
- **Metode:** `dart run test/integration_test_sim.dart` terhubung ke server lokal port 8000.
- **Hasil:** **PASS (Exit code 0)**. Autentikasi admin sukses, verifikasi payment live sukses, proteksi double verification sukses (HTTP 422), proteksi IDOR customer sukses (HTTP 403).

### E. Kompilasi Android Debug APK — **PASS**
- **Metode:** `flutter build apk --debug`.
- **Hasil:** Berhasil mengompilasi `app-debug.apk` (191 MB, SHA-256: `fc90d87429097dc1840366cc6921f60b1751649d8beb9b5230642fcb145731d4`).

### F. Pengujian Runtime pada Android Emulator — **EMULATOR PASS**
- **Metode:** Menjalankan AVD `flutter_pixel_api_36` (Android 16 API 36, x86_64), instalasi APK via `adb install -r`, eksekusi aplikasi `com.example.mb_engkelqq_mobile/.MainActivity`, pengujian interaksi UI, koneksi API `10.0.2.2:8000` (latensi 1164 ms), GPS location runtime permissions, rendering peta OpenStreetMap Tanjungpinang, dan alur autentikasi/fitur untuk 4 role (*Customer, Admin, Mekanik, Kurir*).
- **Hasil:** **EMULATOR PASS (100%)**.

### G. Pengujian Fisik pada Smartphone Nyata via ADB — **PHYSICAL DEVICE BLOCKED**
- **Alasan:** Pada lingkungan sesi CLI saat ini, tidak ada smartphone Android fisik yang dicolokkan via kabel USB debugging ke workstation (`adb devices` hanya mendeteksi emulator).
- **Status:** **PHYSICAL DEVICE BLOCKED (No External USB Hardware)**.

---

## 3. HASIL PENGUJIAN ALUR BISNIS 4 ROLE

| Role Pengguna | Skenario Alur yang Diuji | Status Unit/API Test | Status Android Emulator E2E | Bukti Pengujian Nyata |
|:---|:---|:---:|:---:|:---|
| **Customer** | Login, Dashboard, Tambah Motor, Buat Booking, Pantau Servis, Buka Invoice, Ajukan Pembayaran, API Settings Test, Logout | **PASS** | **EMULATOR PASS** | `Tests\Feature\EndToEndBusinessFlowTest::test_flow_1_service_biasa_end_to_end`, `emulator_customer_kendaraan.png`, `emulator_booking_create_form.png`, `emulator_tes_koneksi_success.png` |
| **Admin** | Dashboard Metrik (21 Bookings), Konfirmasi Booking, Penugasan Kurir, Tab Kelola Pembayaran (Tagihan Rp 55.000), Delivery Tasks, Notifikasi Verifikasi, Logout | **PASS** | **EMULATOR PASS** | `Tests\Feature\Api\PaymentApiTest`, `emulator_admin_logged_in.png`, `emulator_admin_payments.png`, `emulator_admin_delivery.png`, `emulator_admin_notifications.png` |
| **Mechanic** | Ambil Order Miliknya, Mulai Servis (`in_progress`), Simpan Diagnosis, Tambah Sparepart via API, Selesaikan Servis, Task List View, Logout | **PASS** | **EMULATOR PASS** | `Tests\Feature\Api\ServiceOrderApiTest`, `PriceSnapshotTest`, `emulator_mechanic_logged_in.png` |
| **Courier** | Ambil Tugas Pengiriman, Deduplikasi Alamat, Mulai Pengiriman, Izin Lokasi GPS Runtime, Peta & Navigasi Tanjungpinang (OSM Tiles), Selesaikan Tugas, Logout | **PASS** | **EMULATOR PASS** | `Tests\Feature\EndToEndBusinessFlowTest::test_flow_2_pickup_and_delivery_end_to_end`, `emulator_courier_loaded.png`, `emulator_courier_map_final.png` |


---

## 4. KEPUTUSAN RELEASE ACCEPTANCE GATE

### Status: **CONDITIONAL PASS — READY WITH LIMITATIONS**

**Kondisi dan Batasan Rilis:**
1. **Kualitas Kode & Backend:** Siap rilis (Zero Critical/High bugs, 340 test Laravel lulus, 120 test Flutter lulus, APK terkompilasi).
2. **Keterbatasan Operasional:**
   - Pengujian layar sentuh dan sensor GPS riil pada perangkat fisik Android belum dieksekusi via ADB karena ketiadaan device fisik tertancap pada terminal.
   - APK debug telah tersedia di `build/app/outputs/flutter-apk/app-debug.apk` dan siap dipasang ke HP pengguna.
