# 🛡️ SecurePush — DevSecOps Desktop Scanner

SecurePush adalah aplikasi desktop Flutter untuk scanning security sebelum push/deploy.

## Yang sudah siap dipakai

- Code scan: **Gitleaks + Semgrep + Trivy**
- Web scan: **Nuclei + OWASP ZAP Baseline**
- Security score otomatis
- Tampilan hasil vulnerability
- Helper untuk cek status Trivy di Settings

## Prasyarat

- Flutter SDK (desktop enabled)
- Git
- Scanner CLI tersedia di PATH:
  - `gitleaks`
  - `semgrep`
  - `trivy`
  - `nuclei`
  - `zap-baseline.py` (opsional jika pakai web scan ZAP)

## Quick Start (langsung coba scan)

1. Install dependency Flutter:

```bash
flutter pub get
```

2. Jalankan aplikasi desktop (Windows contoh):

```bash
flutter run -d windows
```

3. Buka menu **Scan** lalu pilih mode:
   - **Code Scan** → pilih folder project
   - **Web Scan** → isi URL target (mis. `https://staging-app.internal`)

4. Klik **Scan Project** dan tunggu hasil tampil.

## Cara penggunaan

### 1) Code Scan

- Pilih mode `Code Scan (Gitleaks/Semgrep/Trivy)`
- Klik tombol scan
- Pilih folder source code
- Aplikasi menjalankan:
  - gitleaks detect
  - semgrep scan --config=auto
  - trivy fs

### 2) Web Scan

- Pilih mode `Web Scan (Nuclei/ZAP)`
- Isi URL target web
- Klik scan
- Aplikasi menjalankan:
  - nuclei -u <target>
  - zap-baseline.py -t <target>

## Auto setup semua tools scanner (internet allowed)

Di halaman **Settings**, klik:

- `Check All Tools` untuk cek semua tools scanner di PATH
- Klik `Install Guide` pada tiap tool untuk menampilkan command install sesuai OS

Tools yang dicheck:
- gitleaks
- semgrep
- trivy
- nuclei
- zap-baseline.py (OWASP ZAP)

> Catatan: demi keamanan dan kompatibilitas, aplikasi saat ini menampilkan perintah install resmi (bukan auto-exec silent installer).


## Update UX terbaru

- Setiap halaman (`Scan`, `Report`, `Settings`) sekarang punya tombol **← Kembali** ke Dashboard.
- Saat klik scan, aplikasi akan **cek ketersediaan tools dulu**.
- Jika tools belum terinstall, scan dibatalkan dan muncul notifikasi tool mana yang kurang.
- Jadi tidak lagi terlihat seperti "scan selesai terlalu cepat tanpa alasan".

## Struktur ringkas

```text
lib/
├── screens/
├── services/
├── models/
└── widgets/
```

## Roadmap berikutnya

- Simpan hasil scan ke SQLite
- Integrasi SOC API + WhatsApp notif
- Pre-push block berdasarkan severity threshold
- Packaging installer (.exe/.dmg/.AppImage)
