import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../models/scan_result.dart';
import '../../services/git_service.dart';
import '../../services/report_repository.dart';
import '../../services/scanner_service.dart';
import '../../widgets/scan_button.dart';
import '../../widgets/score_card.dart';
import '../../widgets/vulnerability_table.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _scanner = ScannerService();
  final _git = GitService();
  bool _loading = false;
  String? _projectPath;
  ScanResult? _result;
  String _status = 'Siap scan.';
  List<String> _missingTools = [];

  Future<void> _scanCode() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pilih folder project source code');
    if (path == null) return;
    setState(() {
      _loading = true;
      _projectPath = path;
      _status = 'Checking tools...';
      _missingTools = [];
      _result = null;
    });
    final missing = await _scanner.getMissingCodeTools();
    if (missing.isNotEmpty) {
      setState(() {
        _missingTools = missing;
        _loading = false;
        _status = 'Scan dibatalkan: ada tools belum terinstall.';
      });
      return;
    }
    setState(() => _status = 'Menjalankan Gitleaks, Semgrep, Trivy...');
    final result = await _scanner.runAll(path);
    await ReportRepository.instance.saveScanResult(result);
    final sev = result.severityCount;
    await _git.writeLastScanSummary(
      path,
      critical: sev['critical'] ?? 0,
      high: sev['high'] ?? 0,
      medium: sev['medium'] ?? 0,
      low: sev['low'] ?? 0,
      score: result.securityScore,
    );
    setState(() {
      _result = result;
      _loading = false;
      _status = result.vulnerabilities.isEmpty ? 'Scan selesai. Tidak ada temuan.' : 'Scan selesai. Ditemukan ${result.vulnerabilities.length} temuan.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          if (_missingTools.isNotEmpty)
            InfoBar(
              title: const Text('Tools belum lengkap'),
              content: Text('Silakan install dulu: ${_missingTools.join(', ')}. Buka halaman Settings untuk panduan install.'),
              severity: InfoBarSeverity.warning,
            ),
          const Text('Scan page hanya untuk Code Scan. Web Scan (Nuclei + ZAP) dilakukan dari halaman Report > Detail / Git.'),
          const SizedBox(height: 12),
          Text(_projectPath == null ? 'Belum ada folder project dipilih.' : 'Project: $_projectPath'),
          const SizedBox(height: 4),
          Text(_status),
          const SizedBox(height: 12),
          ScanButton(onPressed: _scanCode, isLoading: _loading),
          const SizedBox(height: 20),
          if (_result != null) ...[
            ScoreCard(score: _result!.securityScore),
            const SizedBox(height: 16),
            VulnerabilityTable(items: _result!.vulnerabilities),
          ]
        ],
      ),
    );
  }
}
