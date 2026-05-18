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
  final _urlController = TextEditingController(text: 'https://example.com');
  bool _loading = false;
  String? _projectPath;
  ScanResult? _result;
  String _mode = 'code';
  String _status = 'Siap scan.';
  List<String> _missingTools = [];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _scanCode() async {
    final path = await FilePicker().getDirectoryPath(dialogTitle: 'Pilih project source code');
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
    setState(() {
      _result = result;
      _loading = false;
      _status = result.vulnerabilities.isEmpty ? 'Scan selesai. Tidak ada temuan.' : 'Scan selesai. Ditemukan ${result.vulnerabilities.length} temuan.';
    });
  }

  Future<void> _scanWeb() async {
    final target = _urlController.text.trim();
    if (target.isEmpty) return;
    setState(() {
      _loading = true;
      _projectPath = target;
      _status = 'Checking tools...';
      _missingTools = [];
      _result = null;
    });
    final missing = await _scanner.getMissingWebTools();
    if (missing.isNotEmpty) {
      setState(() {
        _missingTools = missing;
        _loading = false;
        _status = 'Scan dibatalkan: ada tools web scan belum terinstall.';
      });
      return;
    }
    setState(() => _status = 'Menjalankan Nuclei + OWASP ZAP baseline...');
    final result = await _scanner.runWebScan(target);
    await ReportRepository.instance.saveScanResult(result);
    setState(() {
      _result = result;
      _loading = false;
      _status = result.vulnerabilities.isEmpty ? 'Web scan selesai. Tidak ada temuan.' : 'Web scan selesai. Ditemukan ${result.vulnerabilities.length} temuan.';
    });
  }

  Future<void> _runScan() => _mode == 'code' ? _scanCode() : _scanWeb();

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
          InfoLabel(
            label: 'Mode Scan',
            child: ComboBox<String>(
              value: _mode,
              items: const [
                ComboBoxItem(value: 'code', child: Text('Code Scan (Gitleaks/Semgrep/Trivy)')),
                ComboBoxItem(value: 'web', child: Text('Web Scan (Nuclei/ZAP)')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'code'),
            ),
          ),
          const SizedBox(height: 12),
          if (_mode == 'web') InfoLabel(label: 'Target URL', child: TextBox(controller: _urlController)),
          const SizedBox(height: 12),
          Text(_projectPath == null ? 'Belum ada target dipilih.' : 'Target: $_projectPath'),
          const SizedBox(height: 4),
          Text(_status),
          const SizedBox(height: 12),
          ScanButton(onPressed: _runScan, isLoading: _loading),
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
