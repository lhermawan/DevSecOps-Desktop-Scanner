import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

import '../../models/scan_result.dart';
import '../../services/git_service.dart';
import '../../services/report_repository.dart';
import '../../services/scanner_service.dart';
import '../../widgets/score_card.dart';
import '../../widgets/vulnerability_table.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.item});

  final ScanResult item;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _scanner = ScannerService();
  final _git = GitService();
  final _repo = ReportRepository.instance;
  final _targetController = TextEditingController(text: 'https://example.com');
  final _commitController = TextEditingController();

  bool _busy = false;
  String _status = 'Siap.';
  List<String> _logs = [];
  ScanResult? _latest;

  @override
  void initState() {
    super.initState();
    _latest = widget.item;
  }

  Future<void> _scanWeb() async {
    setState(() {
      _busy = true;
      _status = 'Checking tools web...';
      _logs = ['[1/3] Validasi tools web...'];
    });
    final missing = await _scanner.getMissingWebTools();
    if (missing.isNotEmpty) {
      setState(() {
        _busy = false;
        _status = 'Gagal: tools belum lengkap (${missing.join(', ')})';
      });
      return;
    }
    setState(() => _logs = [..._logs, '[2/3] Menjalankan Nuclei + ZAP baseline...']);
    final result = await _scanner.runWebScan(_targetController.text.trim());
    await _repo.saveScanResult(result);
    setState(() {
      _latest = result;
      _busy = false;
      _status = 'Web scan selesai. Temuan: ${result.vulnerabilities.length}';
      _logs = [
        ..._logs,
        '[3/3] Selesai. Findings: ${result.vulnerabilities.length}. Errors: ${result.errors.length}.',
        ...result.errors.map((e) => '• $e'),
      ];
    });
  }

  Future<void> _gitStatus() async {
    final projectDir = Directory(widget.item.projectPath);
    if (!projectDir.existsSync()) {
      setState(() => _status = 'Path project tidak ditemukan di mesin ini.');
      return;
    }
    final res = await _git.status(widget.item.projectPath);
    setState(() => _status = res.stdout.toString().trim().isEmpty ? 'Working tree clean.' : res.stdout.toString());
  }

  Future<void> _commitPush() async {
    final projectDir = Directory(widget.item.projectPath);
    if (!projectDir.existsSync()) {
      setState(() => _status = 'Path project tidak ditemukan di mesin ini.');
      return;
    }
    final latest = await _repo.getReports();
    final latestForProject = latest.where((e) => e.projectPath == widget.item.projectPath).toList();
    if (latestForProject.isEmpty) return;
    final sev = latestForProject.first.severityCount;
    if ((sev['high'] ?? 0) > 0 || (sev['critical'] ?? 0) > 0) {
      setState(() => _status = 'Commit ditolak: masih ada high/critical vulnerability.');
      return;
    }
    final msg = _commitController.text.trim().isEmpty ? 'chore(security): safe commit after clean scan' : _commitController.text.trim();
    await _git.addAll(widget.item.projectPath);
    await _git.commit(widget.item.projectPath, msg);
    await _git.push(widget.item.projectPath);
    setState(() => _status = 'Commit + push berhasil.');
  }

  @override
  Widget build(BuildContext context) {
    final item = _latest ?? widget.item;
    return ScaffoldPage.scrollable(
      header: PageHeader(
        leading: Button(
          child: const Text('← Kembali'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Project Security Detail'),
      ),
      children: [
        Text(item.projectPath, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 220, child: ScoreCard(score: item.securityScore)),
          InfoLabel(label: 'Target URL (Nuclei + ZAP)', child: SizedBox(width: 420, child: TextBox(controller: _targetController))),
        ]),
        const SizedBox(height: 12),
        Text(_status),
        const SizedBox(height: 8),
        Container(
          height: 130,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: _logs.isEmpty ? const Text('Belum ada log scan.') : ListView(children: _logs.map((l) => Text(l)).toList()),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: _busy ? null : _scanWeb, child: const Text('Scan Nuclei + ZAP')),
          Button(onPressed: _busy ? null : _gitStatus, child: const Text('Git Status')),
          SizedBox(width: 360, child: TextBox(controller: _commitController, placeholder: 'Commit message')),
          FilledButton(onPressed: _busy ? null : _commitPush, child: const Text('Commit + Push (Lolos Scan)')),
        ]),
        const SizedBox(height: 16),
        VulnerabilityTable(items: item.vulnerabilities),
      ],
    );
  }
}
