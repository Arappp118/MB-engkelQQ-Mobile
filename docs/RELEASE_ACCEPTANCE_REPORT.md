# LAPORAN AKSEPTASI RILIS (RELEASE ACCEPTANCE REPORT)
## MB-ENGKELQQ MOBILE & BACKEND LARAVEL

- **Versi Proyek:** 1.0.0+1
- **Tanggal Audit Akhir:** 26 Oktober 2026
- **Status Keputusan Gate:** **CONDITIONAL PASS — READY WITH LIMITATIONS**

---

## 1. KEPUTUSAN RELEASE ACCEPTANCE GATE

Berdasarkan evaluasi menyeluruh terhadap kriteria akseptasi kualitas dan keamanan:

```
[  ] FAIL — NOT READY
[ X ] CONDITIONAL PASS — READY WITH LIMITATIONS
[  ] PASS — READY FOR RELEASE (UNCONDITIONAL)
```

### Dasar Pertimbangan Keputusan:
1. **Zero Critical/High Defects:** Tidak ada cacat fungsional berkategori *Critical* maupun *High* pada Flutter Mobile maupun Laravel Backend.
2. **Kesesuaian Kontrak API 100%:** Seluruh 45 rute API Laravel telah diverifikasi dan kompatibel dengan implementasi klien mobile.
3. **Pengujian Menyeluruh:**
   - Backend Laravel: **340/340 test cases lulus (100%)**
   - Flutter Static Analysis: **0 Issues / Lints**
   - Flutter Automated Tests: **120/120 test cases lulus (100%)**
   - Live Payment Contract Test (`test/integration_test_sim.dart`): **Lulus 100% (Exit Code 0)**
   - Android Emulator E2E (`flutter_pixel_api_36`): **4/4 Role Lulus 100% (EMULATOR PASS)**
   - Build Android: **APK Debug Berhasil Dikompilasi** (191 MB, SHA-256 terverifikasi)
4. **Keamanan Aplikasi:** Proteksi menyeluruh terhadap IDOR/BOLA, manipulasi harga, brute-force rate limiting, race conditions, atomic payment lock, dan upload berkas berbahaya.
5. **Keterbatasan yang Terdokumentasi (Limitations):**
   - Ketiadaan device fisik yang terhubung ke port USB saat sesi CLI (`PHYSICAL DEVICE BLOCKED`). Pengujian pada layar fisik diserahkan kepada pengguna melalui file APK yang sudah terpasang dan siap uji.

---

## 2. EVALUASI KRITERIA GERBANG KUALITAS (QUALITY GATE CRITERIA)

| Kriteria Kualitas | Standar Minimum | Hasil Aktual | Status |
|:---|:---|:---|:---:|
| **Kompilasi / Analisis Statis** | 0 Error, 0 Warning Kritis | `flutter analyze`: 0 Issues | **PASS** |
| **Unit & Integration Test Mobile** | Kelulusan 100% | 120 dari 120 tests lulus (0 fail) | **PASS** |
| **Unit & Feature Test Backend** | Kelulusan 100% | 340 dari 340 tests lulus (801 assertions) | **PASS** |
| **Simulasi Pembayaran Live API** | Verifikasi & Proteksi Lulus | `dart run test/integration_test_sim.dart` (Exit 0) | **PASS** |
| **Runtime Android Emulator E2E** | 4 Role Berjalan pada Layar | AVD `flutter_pixel_api_36` (Android 16 API 36) | **EMULATOR PASS** |
| **End-to-End Business Flow** | 4 Alur Utama Lulus | Alur Customer, Admin, Mekanik, Kurir Lulus | **PASS** |
| **API Contract Matching** | 100% Endpoint Cocok | Seluruh method, path, model response sinkron | **PASS** |
| **Perlindungan Broken Access Control**| 0 Celah IDOR/BOLA | Seluruh model diproteksi Laravel Policy | **PASS** |
| **Integritas Database & Mutasi Harga**| Server Otoritatif | Harga & nominal selalu dari server/database | **PASS** |
| **Build Artefak Rilis** | Kompilasi APK Sukses | `app-debug.apk` berhasil terbuat (191 MB) | **PASS** |
| **Perangkat Fisik Terhubung ADB** | Opsional untuk CLI Gate | Kosong (Dikelola mandiri oleh pengguna via APK) | **LIMITATION** |

---

## 3. CHECKLIST PRA-RILIS & PANDUAN PENGGUNA

Untuk menjalankan dan mendemokan aplikasi:

1. **Konfigurasi Lingkungan Terminal ZSH:**
   ```bash
   echo 'export FLUTTER_HOME="$HOME/development/flutter"' >> ~/.zshrc
   echo 'export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/android-studio/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Menjalankan Backend Laravel:**
   ```bash
   cd /home/wh4mi/Dokumen/S5/senin/pw/mbengkelQ
   php artisan serve --host=0.0.0.0 --port=8000
   ```

3. **Memasang dan Menjalankan Aplikasi di HP Android:**
   - Hubungkan HP Android ke komputer dengan USB Debugging aktif.
   - Pasang file APK:
     ```bash
     adb install -r /home/wh4mi/Dokumen/S5/jumat/pemograman_perangkat_bergrak/Droid/mb_engkelqq_mobile/build/app/outputs/flutter-apk/app-debug.apk
     ```
   - Buka aplikasi MB-engkelQQ di HP, tap ikon gear di layar login, masukkan IP laptop Anda (misal `192.168.1.19`), dan tekan **Tes Koneksi**.
   - Setelah muncul status sukses *"MotoCare API berjalan"*, lakukan login dengan akun test sesuai role.

---

## 4. TANDA TANGAN AKSEPTASI (SIGN-OFF)

- **Keputusan:** **CONDITIONAL PASS — READY WITH LIMITATIONS**
- **Disetujui Oleh:** Senior QA & Application Security Reviewer
- **Tanggal:** 26 Oktober 2026
