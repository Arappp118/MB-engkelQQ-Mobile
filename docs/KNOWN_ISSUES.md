# REGISTER ISU DIKETAHUI & KETERBATASAN OPERASIONAL (KNOWN ISSUES)
## MB-ENGKELQQ MOBILE & BACKEND

Dokumen ini memuat isu non-kritis dan keterbatasan lingkungan pengujian yang diketahui, beserta mitigasi dan solusi teknisnya.

---

### ISSUE 1: `zsh: command not found: flutter` PADA TERMINAL INTERAKTIF PENGGUNA
- **Tingkat Keparahan:** Low (Developer Environment Configuration)
- **Gejala:** Saat pengguna mengetik `flutter` di terminal ZSH, terminal menampilkan:
  ```text
  zsh: command not found: flutter
  ```
- **Akar Masalah:**
  - Shell default pengguna adalah `/usr/bin/zsh`.
  - Flutter SDK dan Android toolchain telah terpasang di:
    ```text
    /home/wh4mi/development/flutter/bin/flutter
    ```
  - Konfigurasi `PATH` telah ada di `~/.bashrc` dan `~/.profile`, tetapi **tidak ada di `~/.zshrc`**.
  - ZSH tidak otomatis membaca konfigurasi `~/.bashrc` atau `~/.profile`.
- **Solusi Permanen untuk Pengguna:**
  Tambahkan baris berikut ke file `~/.zshrc`:
  ```bash
  export FLUTTER_HOME="$HOME/development/flutter"
  export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/android-studio/bin:$PATH"
  ```
  Kemudian jalankan:
  ```bash
  source ~/.zshrc
  ```
- **Status:** **TERIDENTIFIKASI & SOLUSI TERDOKUMENTASI**.

---

### ISSUE 2: KETIADAAN PERANGKAT FISIK PADA KONEKSI ADB CLI
- **Tingkat Keparahan:** Low (Keterbatasan Fasilitas Perangkat Keras Eksternal)
- **Gejala:** Perintah `adb devices` sebelum emulator dijalankan menampilkan daftar kosong (*List of devices attached* kosong).
- **Akar Masalah:** Tidak ada kabel data USB atau koneksi ADB over Wi-Fi aktif yang menghubungkan ponsel fisik Android ke workstation saat sesi ini dijalankan.
- **Hasil Verifikasi Runtime:**
  - **Android Emulator (`flutter_pixel_api_36`, Android 16 API 36):** **EMULATOR PASS (100%)**. Seluruh alur 4 role (Customer, Admin, Mekanik, Kurir) berhasil diuji pada layar emulator aktif.
  - **Pengujian Smartphone Fisik:** **PHYSICAL DEVICE BLOCKED** (karena tidak ada unit HP fisik yang dicolokkan ke port USB komputer kerja).
- **Langkah Pengguna untuk Pengujian Mandiri pada HP Fisik:**
  1. Hubungkan HP fisik ke komputer via kabel USB dengan opsi *USB Debugging* aktif.
  2. Pasang APK ke ponsel:
     ```bash
     adb install -r build/app/outputs/flutter-apk/app-debug.apk
     ```
  3. Buka aplikasi dan arahkan IP ke laptop via menu Pengaturan API.
- **Status:** **EMULATOR VERIFIED (PASS) | PHYSICAL DEVICE BLOCKED (HARDWARE ABSENT)**.

---

### ISSUE 3: SCRIPT SIMULASI LIVE `test/integration_test_sim.dart`
- **Tingkat Keparahan:** Low (Resolved Integration Contract Verification)
- **Gejala Sebelumnya:**
  - Menjalankan skrip mencetak `FAIL: No payments to test (due to missing data or backend enum mismatch)`.
- **Akar Masalah & Resolusi:**
  - Skrip versi lama mengasumsikan `service_orders.status` bernilai `waiting_payment`.
  - Kontrak aktual backend Laravel:
    - `service_orders.status` adalah `['pending', 'in_progress', 'completed']` (terdapat 10 order berstatus `completed`).
    - `waiting_payment` adalah status pada model `Booking` dan filter label di UI `AdminPaymentsPage`.
    - `payments.status` menggunakan `waiting_verification`.
  - Skrip telah diperbarui untuk merefleksikan model kontrak yang sesungguhnya dan mengeksekusi pengujian live:
    - Verifikasi Admin pada Payment #10 (metode cash, Rp 165.000) $\rightarrow$ **HTTP 200 OK** (`paid_at` tercatat).
    - Double verification guard $\rightarrow$ **HTTP 422 Unprocessable Entity**.
    - Customer IDOR guard $\rightarrow$ **HTTP 403 Forbidden**.
- **Hasil Eksekusi:** **100% PASS (Exit Code 0)** via `dart run test/integration_test_sim.dart`.
- **Status:** **RESOLVED & VERIFIED PASS**.


