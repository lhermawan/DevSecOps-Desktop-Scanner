# Petunjuk Teknis Penggunaan dan Instalasi SecFusion

> Dokumen ini menjelaskan langkah instalasi, konfigurasi, penggunaan, serta troubleshooting **SecFusion / SecurePush DevSecOps Desktop Scanner**. Aplikasi ini berjalan sebagai desktop app Flutter dan menjalankan scanner keamanan dari mesin lokal melalui CLI tools.

## 1. Ringkasan Aplikasi

SecFusion adalah aplikasi desktop untuk membantu tim developer dan DevSecOps melakukan pemeriksaan keamanan sebelum kode dipush atau dideploy.

Fitur utama:

- **Code Scan** menggunakan Gitleaks, Semgrep, dan Trivy.
- **Web Scan** menggunakan Nuclei dan OWASP ZAP Baseline.
- **Security score** otomatis berdasarkan temuan vulnerability.
- **Dashboard dan Report** untuk melihat hasil scan yang tersimpan.
- **Git protection** melalui pre-push hook untuk memblok push jika masih ada vulnerability High/Critical.
- **Settings tools** untuk cek status scanner dan menampilkan perintah instalasi sesuai sistem operasi.

## 2. Prasyarat Sistem

### 2.1 Sistem Operasi

Aplikasi dibuat dengan Flutter Desktop dan dapat dijalankan di:

- Windows 10/11
- macOS
- Linux desktop

> Catatan: auto-install dari tombol **Install** saat ini paling optimal untuk Windows. Untuk macOS dan Linux, gunakan perintah manual yang ditampilkan pada tombol **Install Guide**.

### 2.2 Software Dasar

Pastikan software berikut tersedia:

| Komponen | Keterangan |
| --- | --- |
| Flutter SDK | Untuk menjalankan atau membuild aplikasi desktop. |
| Git | Untuk clone repository, status project, hook, commit, dan push. |
| Python/Pip | Dibutuhkan oleh Semgrep dan beberapa mode OWASP ZAP. |
| Go | Direkomendasikan untuk instalasi Nuclei di Linux/manual. |
| Koneksi internet | Dibutuhkan saat install dependency Flutter dan scanner tools. |

### 2.3 Scanner CLI yang Dibutuhkan

| Mode | Tool | Fungsi |
| --- | --- | --- |
| Code Scan | `gitleaks` | Mendeteksi secret, token, password, dan credential yang bocor. |
| Code Scan | `semgrep` | Static analysis untuk mendeteksi pola kode berisiko. |
| Code Scan | `trivy` | Mendeteksi vulnerability dependency, container, IaC, dan filesystem. |
| Web Scan | `nuclei` | Scan web berbasis template vulnerability. |
| Web Scan | `zap-baseline.py` / OWASP ZAP | Baseline scan aplikasi web. |

## 3. Instalasi Aplikasi SecFusion

### 3.1 Clone Repository

```bash
git clone <URL_REPOSITORY_SECFUSION>
cd DevSecOps-Desktop-Scanner
```

Jika repository sudah tersedia di komputer, langsung masuk ke folder project:

```bash
cd DevSecOps-Desktop-Scanner
```

### 3.2 Aktifkan Flutter Desktop

Jalankan salah satu atau beberapa perintah berikut sesuai target OS:

```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

Verifikasi environment Flutter:

```bash
flutter doctor
```

Pastikan tidak ada error kritis untuk target desktop yang akan digunakan.

### 3.3 Install Dependency Flutter

```bash
flutter pub get
```

### 3.4 Jalankan Aplikasi

Pilih command sesuai OS:

#### Windows

```bash
flutter run -d windows
```

#### macOS

```bash
flutter run -d macos
```

#### Linux

```bash
flutter run -d linux
```

## 4. Instalasi Scanner Tools

Scanner tools harus tersedia di `PATH` agar dapat dijalankan oleh aplikasi.

### 4.1 Instalasi via Halaman Settings

1. Buka aplikasi SecFusion.
2. Masuk ke menu **Settings**.
3. Klik **Check All Tools** untuk mengecek status semua tool.
4. Jika ada tool yang belum ditemukan:
   - Klik **Install Guide** untuk melihat command instalasi.
   - Klik **Install** untuk menjalankan installer otomatis jika didukung oleh sistem operasi.
5. Tutup dan buka kembali terminal/aplikasi jika PATH belum terbaca setelah instalasi.
6. Klik ulang **Check All Tools** sampai status tool berubah menjadi **Terpasang ✅**.

### 4.2 Command Instalasi Manual Windows

Jalankan PowerShell sebagai Administrator jika diperlukan.

```powershell
winget install GitLeaks.Gitleaks
pip install semgrep
winget install AquaSecurity.Trivy
winget install --id ProjectDiscovery.Nuclei -e --accept-package-agreements --accept-source-agreements
winget install --id OWASP.ZAP -e --accept-package-agreements --accept-source-agreements
```

Jika `winget` tidak tersedia, gunakan Chocolatey jika sudah terpasang:

```powershell
choco install nuclei -y
choco install zap -y
```

### 4.3 Command Instalasi Manual macOS

```bash
brew install gitleaks
brew install semgrep
brew install trivy
brew install nuclei
brew install --cask owasp-zap
```

### 4.4 Command Instalasi Manual Linux

```bash
curl -sSL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh
python3 -m pip install semgrep
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
sudo snap install zaproxy --classic
```

Pastikan binary hasil instalasi masuk ke `PATH`, misalnya `$HOME/go/bin` untuk Nuclei yang diinstall dengan Go.

### 4.5 Verifikasi Tool dari Terminal

```bash
gitleaks version
semgrep --version
trivy --version
nuclei -version
zap-baseline.py -h
```

Jika command tidak dikenali, periksa kembali instalasi dan konfigurasi `PATH`.

## 5. Alur Penggunaan Aplikasi

### 5.1 Membuka Workspace Project

1. Jalankan aplikasi SecFusion.
2. Pilih satu folder project yang akan dianalisis.
3. Setelah project aktif, menu **Dashboard**, **Scan**, dan **Report** akan mengarah ke project tersebut.
4. Gunakan tombol **Ganti Project** di sidebar jika ingin berpindah workspace.

### 5.2 Menjalankan Code Scan

1. Buka menu **Scan**.
2. Pastikan project aktif sudah benar.
3. Klik **Scan Project**.
4. Aplikasi akan mengecek tool yang dibutuhkan untuk code scan:
   - `gitleaks`
   - `semgrep`
   - `trivy`
5. Jika tool lengkap, aplikasi menjalankan:

```bash
gitleaks detect --source <PROJECT_PATH> --report-format json --report-path -
semgrep scan --config=auto --json <PROJECT_PATH>
trivy fs --format json <PROJECT_PATH>
```

6. Tunggu proses selesai.
7. Hasil vulnerability dan security score akan ditampilkan di layar.
8. Hasil scan disimpan ke database lokal report.
9. Ringkasan scan terakhir ditulis ke file `.securepush_last_scan.json` pada root project aktif.

### 5.3 Menjalankan Web Scan

Web scan tersedia dari halaman detail report.

1. Jalankan minimal satu code scan agar report project tersedia.
2. Buka menu **Report**.
3. Pilih salah satu report project.
4. Pada halaman **Project Security Detail**, isi **Target URL**.
5. Klik **Scan Nuclei + ZAP**.
6. Aplikasi akan mengecek tool web scan:
   - `nuclei`
   - `zap-baseline.py` / OWASP ZAP
7. Jika tool lengkap, aplikasi menjalankan:

```bash
nuclei -u <TARGET_URL> -jsonl
zap-baseline.py -t <TARGET_URL> -J <REPORT_JSON>
```

8. Hasil web scan disimpan sebagai report baru.

> Gunakan web scan hanya pada target yang Anda miliki atau yang secara eksplisit diizinkan untuk dites.

### 5.4 Melihat Report

1. Buka menu **Report**.
2. Pilih hasil scan berdasarkan project dan waktu scan.
3. Buka detail untuk melihat:
   - Target/project path
   - Security score
   - Daftar vulnerability
   - Log/error hasil scan
   - Aksi Git terkait project

### 5.5 Git Status, Commit, dan Push

Di halaman detail report:

1. Klik **Git Status** untuk melihat perubahan pada project.
2. Isi commit message jika ingin menggunakan pesan custom.
3. Klik **Commit + Push (Lolos Scan)**.
4. Aplikasi akan menolak commit/push jika report terakhir untuk project masih memiliki severity `high` atau `critical`.
5. Jika tidak ada severity High/Critical, aplikasi menjalankan:

```bash
git -C <PROJECT_PATH> add .
git -C <PROJECT_PATH> commit -m "<COMMIT_MESSAGE>"
git -C <PROJECT_PATH> push
```

## 6. Mengaktifkan Git Pre-Push Protection

Pre-push hook digunakan untuk memblok `git push` jika file `.securepush_last_scan.json` menunjukkan temuan High/Critical.

Langkah instalasi:

1. Buka menu **Settings**.
2. Pada bagian **Git Protection**, klik **Install Pre-Push Hook**.
3. Pilih root folder project Git.
4. Jika berhasil, hook dipasang di:

```text
<PROJECT_PATH>/.git/hooks/pre-push
```

5. Setelah code scan selesai, SecFusion memperbarui file:

```text
<PROJECT_PATH>/.securepush_last_scan.json
```

6. Ketika user menjalankan `git push`, hook akan membaca file tersebut dan memblok push jika `critical > 0` atau `high > 0`.

## 7. Lokasi Data dan Output

| Data | Lokasi/Keterangan |
| --- | --- |
| Hasil report | Database lokal aplikasi di application support directory. |
| Ringkasan scan terakhir | `<PROJECT_PATH>/.securepush_last_scan.json`. |
| Git hook | `<PROJECT_PATH>/.git/hooks/pre-push`. |
| ZAP temporary report | Folder temporary sistem, dibuat saat scan lalu dihapus setelah proses selesai. |

## 8. Troubleshooting

### 8.1 Tool Terdeteksi Belum Terinstall

Solusi:

1. Jalankan command verifikasi tool dari terminal.
2. Pastikan lokasi binary masuk ke `PATH`.
3. Restart terminal dan aplikasi.
4. Di Windows, cek lokasi umum berikut:
   - `%LOCALAPPDATA%\Microsoft\WinGet\Links`
   - `%USERPROFILE%\go\bin`
   - `%USERPROFILE%\scoop\shims`
5. Klik ulang **Check All Tools**.

### 8.2 Scan Selesai Terlalu Cepat atau Tidak Ada Output

Kemungkinan penyebab:

- Tool scanner belum tersedia di `PATH`.
- Project path tidak valid.
- Scanner tidak menemukan vulnerability.
- Scanner gagal parse output.

Solusi:

1. Buka **Settings** lalu klik **Check All Tools**.
2. Jalankan tool secara manual dari terminal.
3. Periksa log/error di halaman report detail.

### 8.3 Semgrep Gagal Berjalan

Solusi:

```bash
python3 -m pip install --upgrade semgrep
semgrep --version
```

Jika menggunakan Windows, pastikan folder `Scripts` milik Python masuk ke `PATH`.

### 8.4 Nuclei Tidak Ditemukan Setelah Install dengan Go

Tambahkan `$HOME/go/bin` ke `PATH`.

Linux/macOS contoh:

```bash
export PATH="$PATH:$HOME/go/bin"
```

Windows PowerShell contoh:

```powershell
setx PATH "$env:PATH;$env:USERPROFILE\go\bin"
```

### 8.5 OWASP ZAP Baseline Tidak Ditemukan

Solusi:

- Pastikan OWASP ZAP sudah terinstall.
- Cari file `zap-baseline.py`, `zap.bat`, atau executable ZAP.
- Tambahkan folder instalasi ZAP ke `PATH` jika diperlukan.
- Di Windows, lokasi umum ZAP adalah:

```text
C:\Program Files\ZAP\Zed Attack Proxy
```

### 8.6 Pre-Push Hook Tidak Memblok Push

Periksa hal berikut:

1. File hook ada di `.git/hooks/pre-push`.
2. Pada Linux/macOS, file hook executable:

```bash
chmod +x .git/hooks/pre-push
```

3. File `.securepush_last_scan.json` ada di root project.
4. Isi file memiliki nilai `critical` atau `high` lebih dari 0 untuk kondisi blokir.

## 9. Rekomendasi Operasional

- Jalankan **Code Scan** sebelum commit atau push.
- Jalankan **Web Scan** terhadap staging/internal URL yang mendapat izin pengujian.
- Aktifkan **Pre-Push Hook** pada repository yang ingin diproteksi.
- Jadikan temuan High/Critical sebagai blocker sebelum deploy.
- Simpan hasil report sebagai evidence audit internal.
- Update scanner tools secara berkala agar rule dan database vulnerability tetap relevan.

## 10. Quick Checklist

Sebelum menggunakan SecFusion:

- [ ] Flutter desktop sudah aktif.
- [ ] `flutter pub get` berhasil.
- [ ] Aplikasi dapat dijalankan dengan `flutter run -d <target>`.
- [ ] `gitleaks`, `semgrep`, dan `trivy` terdeteksi untuk code scan.
- [ ] `nuclei` dan OWASP ZAP terdeteksi untuk web scan.
- [ ] Project workspace sudah dipilih.
- [ ] Pre-push hook sudah dipasang jika ingin proteksi Git otomatis.
