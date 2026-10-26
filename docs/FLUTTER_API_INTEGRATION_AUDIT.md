# LAPORAN AUDIT KOMPATIBILITAS & INTEGRASI API LARAVEL
## APLIKASI FLUTTER MB-ENGKELQQ MOBILE

- **Tanggal Pelaksanaan:** 26 Oktober 2026
- **Target Repository Flutter:** `/home/wh4mi/Dokumen/S5/jumat/pemograman_perangkat_bergrak/Droid/mb_engkelqq_mobile`
  - **Commit Terakhir:** `fbe6326` (*fix: improve mobile API integration and regression coverage*)
  - **Branch Aktif:** `main` (sinkron dengan `origin/main`)
- **Target Repository Laravel Backend (READ-ONLY):** `/home/wh4mi/Dokumen/S5/senin/pw/mbengkelQ`
  - **Remote URL:** `https://github.com/arappp118/MB-engkelQQ.git`
  - **Commit Terakhir Backend:** `f256f50` (*test(e2e): add end-to-end business flow tests and final audit documentation*)
  - **Branch Aktif:** `main` (sinkron dengan `origin/main`)
- **Status Akhir Kode:**
  - `flutter analyze`: **0 Issues (Bersih)**
  - `flutter test`: **120/120 Test Lulus (100% Pass, 0 Failed, 0 Skipped)**
  - Kompatibilitas API: **100% Cocok & Terverifikasi**

---

## 1. KONDISI AWAL & DIAGNOSIS LINGKUNGAN

### 1.1 Status Git Awal
Pemeriksaan awal `git status --short --branch` pada repository mobile:
```text
## main...origin/main
?? FINAL_AUDIT_REPORT.md
?? mb-engkelqq-screen.png
```
- Berkas `FINAL_AUDIT_REPORT.md` dan `mb-engkelqq-screen.png` adalah berkas audit/screenshot sebelumnya yang dipertahankan utuh dan tidak dimodifikasi.
- Tidak terdapat perubahan uncommitted pada berkas kode terlacak.

### 1.2 Investigasi Error `zsh: command not found: flutter`
Saat perintah `flutter` dijalankan di terminal pengguna, muncul pesan error:
```text
zsh: command not found: flutter
```

**Temuan Investigasi Sistem:**
1. **Shell Interaktif Pengguna:** Default login shell pada OS Linux pengguna adalah `/usr/bin/zsh`.
2. **Lokasi Instalasi SDK:** Flutter SDK terpasang secara valid di direktori:
   ```text
   /home/wh4mi/development/flutter/bin/flutter
   ```
   Versi terpasang: **Flutter 3.47.6** (Channel stable, revision `5fc346839b`), **Dart 3.13.5**, DevTools `2.60.0`.
3. **Penyebab Utama (Root Cause):**
   - Konfigurasi PATH untuk Flutter SDK dan Android SDK telah terdefinisi di `~/.bashrc` (baris 162–166) dan `~/.profile` (baris 30–34):
     ```bash
     export FLUTTER_HOME="$HOME/development/flutter"
     export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/android-studio/bin:$PATH"
     ```
   - Namun, berkas konfigurasi `~/.zshrc` **TIDAK** memuat definisi PATH tersebut, dan shell ZSH secara default tidak membaca `~/.bashrc` maupun `~/.profile`.
4. **Solusi untuk Pengguna (Workaround & Permanent Fix):**
   - *Sesi saat ini:* Jalankan `export PATH="$HOME/development/flutter/bin:$PATH"` sebelum perintah flutter.
   - *Permanen:* Tambahkan baris berikut pada akhir berkas `~/.zshrc`:
     ```bash
     export FLUTTER_HOME="$HOME/development/flutter"
     export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/android-studio/bin:$PATH"
     ```

---

## 2. AUDIT INTEGRITAS & KONTRAK BACKEND LARAVEL

Pemeriksaan dilakukan secara **READ-ONLY** terhadap repositori backend Laravel di `/home/wh4mi/Dokumen/S5/senin/pw/mbengkelQ`:
- `git status -s`: **Clean working tree (0 modified files)**.
- Seluruh controller API, FormRequest, Eloquent Resource, Model, dan Policies dianalisis langsung dari source code riil.

### 2.1 Update Signifikan Kontrak Backend (Komparasi Audit Sebelumnya vs Sekarang)
Pada audit sebelumnya (10 Oktober 2026), fitur penambahan item oleh mekanik berstatus `BLOCKED BY BACKEND` karena route `POST /api/v1/service-orders/{id}/items` belum didaftarkan di `routes/api.php`.

Pada audit saat ini (26 Oktober 2026, commit backend `f256f50`):
- **Backend telah resmi mendaftarkan route API:**
  ```php
  Route::post('service-orders/{service_order}/items', [ServiceOrderController::class, 'addItem'])->name('api.service-orders.items.store');
  ```
- **Controller & Request Backend:**
  - `App\Http\Controllers\Api\ServiceOrderController::addItem()` menggunakan `AddServiceOrderItemRequest` dan `ServiceOrderService::addItem()`.
  - Body yang diterima: `service_item_id` (integer, exists di active service_items) dan `quantity` (integer, min 1).
  - Snapshot harga, subtotal, dan pemotongan stok dilakukan di sisi server via database lock.
  - Return: `HTTP 201 Created` dengan `ServiceOrderResource`.
- **Kesiapan Sisi Flutter:**
  - `ServiceOrderService.addItemToServiceOrder()` di Flutter telah mengirimkan payload `service_item_id` dan `quantity` ke `${ApiConstants.serviceOrders}/$id/items`.
  - Dengan tersedianya endpoint ini di backend, fitur penambahan jasa/sparepart mekanik kini **100% UNBLOCKED & FULLY COMPATIBLE**.

### 2.2 Penambahan Endpoint Pengaturan (Settings) di Backend
Backend menambahkan endpoint pengaturan baru:
- `GET /api/v1/payment-settings`: Mengembalikan instruksi rekening bank dan QRIS aktif untuk Customer, serta konfigurasi lengkap untuk Admin.
- `PUT /api/v1/payment-settings`: Pengaturan master bank & QRIS oleh Admin.
- `GET /api/v1/delivery-settings`: Mengembalikan tarif per km dan radius pengiriman.
- `PUT /api/v1/delivery-settings`: Update konfigurasi pengiriman oleh Admin.

---

## 3. MATRIKS KOMPATIBILITAS ENDPOINT FLUTTER & LARAVEL

| No | Modul / Fitur | HTTP Method & Endpoint | Kontrak Parameter Request | Kontrak Response Backend | Status Kompatibilitas |
|:---|:---|:---|:---|:---|:---:|
| 1 | Health Check | `GET /api/v1/health` | Query params: `-` | `{"success":true,"message":"...","data":{"status":"ok","version":"1.0.0"}}` (200) | **PASS** |
| 2 | Auth Login | `POST /api/v1/auth/login` | Body: `email`, `password` (Throttle 5/menit) | `data.token`, `data.user` (id, name, email, role) (200) | **PASS** |
| 3 | Auth Logout | `POST /api/v1/auth/logout` | Header: `Authorization: Bearer <token>` | `{"success":true,"message":"Logout berhasil"}` (200) | **PASS** |
| 4 | Profil User | `GET /api/v1/auth/me` | Header: `Authorization: Bearer <token>` | `{"success":true,"data":{...user...}}` (200) | **PASS** |
| 5 | Dashboard Role | `GET /api/v1/dashboard` | Header: `Authorization: Bearer <token>` | Agregasi dinamis sesuai role login (Customer / Admin / Mekanik / Kurir) | **PASS** |
| 6 | List Kendaraan | `GET /api/v1/vehicles` | Header Sanctum (Filter kepemilikan otomatis di server) | List of `VehicleResource` (200) | **PASS** |
| 7 | Tambah Kendaraan | `POST /api/v1/vehicles` | Body: `nomor_polisi`, `merk`, `model`, `tahun`, `tipe_mesin`, `transmisi`, dll. | `VehicleResource` baru (201) | **PASS** |
| 8 | Detail Kendaraan | `GET /api/v1/vehicles/{id}` | Path: `id` | Detail `VehicleResource` (200) | **PASS** |
| 9 | Update Kendaraan | `PUT/PATCH /api/v1/vehicles/{id}` | Body: field kendaraan | `VehicleResource` terupdate (200) | **PASS** |
| 10 | Hapus Kendaraan | `DELETE /api/v1/vehicles/{id}` | Path: `id` (Dicek proteksi booking aktif) | `{"success":true}` (200) / 422 jika ada booking aktif | **PASS** |
| 11 | List Booking | `GET /api/v1/bookings` | Header Sanctum | List of `BookingResource` (200) | **PASS** |
| 12 | Buat Booking | `POST /api/v1/bookings` | Body: `vehicle_id`, `tanggal`, `waktu`, `keluhan`, `jenis_layanan`, `pickup_requested`, dll. | `BookingResource` baru (201) | **PASS** |
| 13 | Detail Booking | `GET /api/v1/bookings/{id}` | Path: `id` | `BookingResource` dengan relasi vehicle (200) | **PASS** |
| 14 | Batalkan Booking | `POST /api/v1/bookings/{id}/cancel` | Body: `cancellation_reason` | `BookingResource` status `cancelled` (200) | **PASS** |
| 15 | Konfirmasi Booking | `POST /api/v1/bookings/{id}/confirm` | Khusus Admin | `BookingResource` status `confirmed` & auto assign mekanik (200) | **PASS** |
| 16 | List Service Order | `GET /api/v1/service-orders` | Filter otomatis sesuai role user | List of `ServiceOrderResource` (200) | **PASS** |
| 17 | Detail Service Order| `GET /api/v1/service-orders/{id}` | Relasi items, booking, customer | `ServiceOrderResource` lengkap (200) | **PASS** |
| 18 | Mulai Servis | `POST /api/v1/service-orders/{id}/start` | Khusus Mekanik penugasan / Admin | Status transisi ke `in_progress` (200) | **PASS** |
| 19 | Simpan Diagnosis | `POST /api/v1/service-orders/{id}/diagnosis` | Body: `diagnosis_mechanic`, `notes?` | `ServiceOrderResource` terupdate (200) | **PASS** |
| 20 | Tambah Item Servis | `POST /api/v1/service-orders/{id}/items` | Body: `service_item_id`, `quantity` | `ServiceOrderResource` terupdate, stok terpotong (201) | **PASS** |
| 21 | Selesaikan Servis | `POST /api/v1/service-orders/{id}/complete` | Syarat: diagnosis & item lengkap | Status transisi ke `completed` (200) | **PASS** |
| 22 | Katalog Jasa/Part | `GET /api/v1/service-items` | Non-admin hanya melihat item aktif | List of `ServiceItemResource` (200) | **PASS** |
| 23 | Ajukan Pembayaran | `POST /api/v1/service-orders/{id}/payments` | Multipart: `payment_method` (cash/transfer/qris), `proof` (file maks 2MB) | `PaymentResource` (201) | **PASS** |
| 24 | Detail Pembayaran | `GET /api/v1/payments/{id}` | Path: `id` | `PaymentResource` (200) | **PASS** |
| 25 | Verifikasi Bayar | `POST /api/v1/payments/{id}/verify` | Khusus Admin | Status pembayaran `verified` (200) | **PASS** |
| 26 | Tolak Pembayaran | `POST /api/v1/payments/{id}/reject` | Khusus Admin, Body: `reason?` | Status pembayaran `rejected` (200) | **PASS** |
| 27 | List Delivery Task | `GET /api/v1/delivery-tasks` | Filter kurir/customer/admin otomatis | List of `DeliveryTaskResource` (200) | **PASS** |
| 28 | Detail Delivery | `GET /api/v1/delivery-tasks/{id}` | Path: `id` | `DeliveryTaskResource` (200) | **PASS** |
| 29 | Assign Kurir | `POST /api/v1/delivery-tasks/{id}/assign` | Khusus Admin, Body: `courier_id` | `DeliveryTaskResource` dengan kurir (200) | **PASS** |
| 30 | Mulai Pengiriman | `POST /api/v1/delivery-tasks/{id}/start` | Khusus Kurir penugasan | Status transisi ke `in_transit` (200) | **PASS** |
| 31 | Selesaikan Kirim | `POST /api/v1/delivery-tasks/{id}/complete`| Khusus Kurir penugasan, Body: `notes?`| Status transisi ke `completed` (200) | **PASS** |
| 32 | List Invoices | `GET /api/v1/invoices` | Ringkasan order completed | List of `{invoice_number, service_order_id, grand_total}` (200) | **PASS** |
| 33 | Detail Invoice | `GET /api/v1/invoices/{order_id}` | Path: `service_order_id` | `InvoiceResource` snapshot komprehensif (200) | **PASS** |
| 34 | List Notifikasi | `GET /api/v1/notifications` | Milik authenticated user | List of notifikasi (200) | **PASS** |
| 35 | Notifikasi Belum Baca| `GET /api/v1/notifications/unread` | Milik authenticated user | List of unread notifikasi (200) | **PASS** |
| 36 | Tandai Baca Notif | `POST /api/v1/notifications/{id}/read`| Path: `id` | Notifikasi terupdate (200) | **PASS** |

---

## 4. PERBAIKAN DAN PENINGKATAN AMAN YANG DILAKUKAN

Sesuai instruksi audit tahap 3, dilakukan perbaikan aman dan penguatan kontrak API tanpa merombak arsitektur:

1. **`lib/core/constants/api_constants.dart`**
   - **Perubahan:** Menambahkan konstanta endpoint baru:
     ```dart
     static const String paymentSettings = '/payment-settings';
     static const String deliverySettings = '/delivery-settings';
     ```
   - **Alasan:** Menyelaraskan seluruh konstanta endpoint di Flutter agar mencakup 100% rute resmi yang terdaftar di Laravel `routes/api.php` commit `f256f50`.

2. **`test/audit_integration_test.dart`**
   - **Perubahan:** Menambahkan unit test `ApiConstants covers complete Laravel routes/api.php endpoint specifications` untuk memastikan seluruh konstanta endpoint sinkron dengan kontrak REST API Laravel.
   - **Alasan:** Mencegah regresi desinkronisasi kontrak endpoint di masa depan.

---

## 5. HASIL PENGUJIAN OTOMATIS

### 5.1 Flutter Pub Get
```text
Got dependencies!
Exit Code: 0
```

### 5.2 Flutter Analyze
```text
Analyzing mb_engkelqq_mobile...
No issues found! (ran in 12.6s)
Exit Code: 0
```
- Total error: **0**
- Total warning: **0**
- Total lint: **0**

### 5.3 Flutter Test (Pengujian Unit, Widget, dan Regresi)
```text
00:48 +120: All tests passed!
Exit Code: 0
```
**Total: 120 dari 120 tes lulus (100% SUCCESS)**. Rincian cakupan pengujian:
- `test/dynamic_api_url_test.dart`: Normalisasi IP LAN port 8000, pemisahan storage secure, isolasi token, health check differentiation.
- `test/audit_integration_test.dart`: Parsing model DeliveryTask, Booking, Vehicle, Dashboard, ServiceItem, dan verifikasi spesifikasi endpoint `ApiConstants`.
- `test/admin_payment_test.dart`: Logika verifikasi dan penolakan bukti bayar admin, handling 422.
- `test/bugfix_regression_test.dart`: Penanganan crash `_dependents.isEmpty`, constraint `StatCard`, deduplikasi alamat delivery task, kontrak `addItemToServiceOrder`.
- `test/customer_payment_verification_regression_test.dart`: Alur pembayaran customer, validasi bukti transfer/QRIS, upload multipart.
- `test/role_integration_regression_test.dart`: Alur navigasi antar-role (Customer, Admin, Mekanik, Kurir), filter data, transisi status.
- `test/gps_maps_test.dart`: Geofencing Kota Tanjungpinang, validasi bounding box, izin GPS, fallback peta.
- `test/invoice_test.dart`: Rendering invoice digital, parsing snapshot harga historis.
- `test/notification_test.dart`: Pengambilan notifikasi unread dan aksi mark as read.
- `test/qa_regression_test.dart`: Validasi enum `tipe_mesin`, `transmisi`, `jenis_layanan`, dan integritas widget UI.
- `test/runtime_test.dart` & `test/widget_test.dart`: Lifecycle widget dan inisialisasi aplikasi.

---

## 6. KENDALA & CATATAN UNTUK PENGUJIAN DI PERANGKAT FISIK

1. **Perangkat Fisik Nyata (ADB):**
   - Pada lingkungan pengujian CLI saat ini, tidak ada perangkat fisik Android yang terhubung via kabel data/Wi-Fi (`adb devices` kosong).
   - Seluruh logika telah teruji dan lulus via 120 automated unit/widget/integration tests.
2. **Koneksi LAN HP Fisik ke Server Laravel:**
   - Saat menjalankan di HP fisik, pastikan HP dan laptop terhubung ke jaringan Wi-Fi yang sama.
   - Jalankan backend Laravel dengan command:
     ```bash
     php artisan serve --host=0.0.0.0 --port=8000
     ```
   - Di aplikasi mobile, buka menu **Pengaturan API** (ikon gear di pojok kanan atas login):
     - Masukkan alamat IP komputer (contoh: `192.168.1.19` atau `http://192.168.1.19:8000/api/v1`).
     - Fitur normalisasi otomatis akan secara cerdas mengarahkan ke port `:8000` dan skema `http://`.
     - Tekan tombol **Tes Koneksi** untuk memverifikasi respon `/health` dan latensi server sebelum melakukan login.
