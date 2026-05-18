# 🛡️ SecurePush — DevSecOps Desktop Scanner

SecurePush adalah aplikasi desktop berbasis Flutter untuk melakukan scanning source code sebelum push ke GitHub atau deployment ke server.

## Fitur MVP yang sudah disiapkan

- Flutter Desktop UI (Dashboard, Scan, Report, Settings)
- Integrasi scanner engine via `Process.run()`:
  - Gitleaks (secret leak)
  - Semgrep (SAST)
  - Trivy (dependency/filesystem vulnerability)
  - Nuclei (web vuln template scan untuk target URL)
  - OWASP ZAP baseline (DAST untuk target URL)
- Perhitungan security score berbasis severity
- Tampilan tabel vulnerability
- Service git dasar + installer `pre-push` hook
- Struktur project mengikuti kebutuhan SOC/CSIRT internal

## Struktur

```text
lib/
├── main.dart
├── screens/
│   ├── dashboard/
│   ├── scan/
│   ├── report/
│   └── settings/
├── services/
│   ├── scanner_service.dart
│   ├── git_service.dart
│   ├── semgrep_service.dart
│   ├── trivy_service.dart
│   └── gitleaks_service.dart
├── models/
│   ├── vulnerability.dart
│   ├── scan_result.dart
│   └── project.dart
└── widgets/
    ├── score_card.dart
    ├── vulnerability_table.dart
    └── scan_button.dart
```

## Menjalankan

```bash
flutter pub get
flutter run -d windows
# atau linux / macos
```

## Catatan

- Scanner CLI (`gitleaks`, `semgrep`, `trivy`) harus terinstall di host.
- Fitur database SQLite, integrasi WhatsApp API, dan integrasi SOC API disiapkan sebagai fase lanjutan.


## Tambahan: Nuclei + ZAP

Bisa. Implementasi saat ini menambahkan `NucleiService` dan `ZapService`, serta `ScannerService.runWebScan(targetUrl)` untuk scanning aplikasi web (bukan source folder).

Contoh use case:
- `runAll(projectPath)` untuk source/dependency scanning lokal.
- `runWebScan('https://staging.example.internal')` untuk DAST/Pentest ringan sebelum release.
