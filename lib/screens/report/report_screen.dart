import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/scan_result.dart';
import '../../services/git_service.dart';
import '../../services/report_repository.dart';
import '../../services/scanner_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repo = ReportRepository.instance;
  final _scanner = ScannerService();
  final _git = GitService();
  late Future<List<ScanResult>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _repo.getReports();
  }

  Future<void> _refreshReports() async {
    setState(() => _reportsFuture = _repo.getReports());
  }

  Future<void> _exportPdfReport(ScanResult item) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan report PDF',
      fileName: 'scan-report-${item.id ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    if (savePath == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('SecurePush Scan Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Target: ${item.projectPath}'),
          pw.Text('Started: ${item.startedAt}'),
          pw.Text('Finished: ${item.finishedAt}'),
          pw.Text('Findings: ${item.vulnerabilities.length} | Score: ${item.securityScore}'),
          pw.SizedBox(height: 12),
          pw.Text('Errors', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (item.errors.isEmpty) pw.Text('-') else ...item.errors.map((e) => pw.Bullet(text: e)),
          pw.SizedBox(height: 12),
          pw.Text('Findings Detail', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...item.vulnerabilities.map(
            (v) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('[${v.severity}] ${v.issue}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${v.file}:${v.line} (${v.scanner})'),
                  pw.Text('Remediation: ${v.remediation}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await File(savePath).writeAsBytes(await pdf.save());
  }

  Future<void> _openDetail(ScanResult item) async {
    final targetController = TextEditingController(text: 'https://example.com');
    final commitController = TextEditingController();
    String status = 'Siap.';
    bool busy = false;
    final logs = <String>[];

    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Project Detail & Git Control'),
          content: StatefulBuilder(
            builder: (context, setInnerState) => SizedBox(
              width: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Project: ${item.projectPath}'),
                  const SizedBox(height: 8),
                  Text('Score terakhir: ${item.securityScore} | Temuan: ${item.vulnerabilities.length}'),
                  const SizedBox(height: 12),
                  InfoLabel(label: 'Target URL (untuk Nuclei + ZAP)', child: TextBox(controller: targetController)),
                  const SizedBox(height: 10),
                  Text(status),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: logs.isEmpty
                          ? const Text('Belum ada log scan.')
                          : ListView(children: logs.map((l) => Text(l)).toList()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        child: const Text('Scan Web di Detail'),
                        onPressed: busy
                            ? null
                            : () async {
                                setInnerState(() {
                                  busy = true;
                                  status = 'Checking tools web...';
                                  logs.clear();
                                  logs.add('[1/3] Validasi tools web...');
                                });
                                final missing = await _scanner.getMissingWebTools();
                                if (missing.isNotEmpty) {
                                  setInnerState(() {
                                    busy = false;
                                    status = 'Gagal: tools belum lengkap (${missing.join(', ')})';
                                  });
                                  return;
                                }
                                setInnerState(() => logs.add('[2/3] Menjalankan Nuclei + ZAP baseline...'));
                                final result = await _scanner.runWebScan(targetController.text.trim());
                                await _repo.saveScanResult(result);
                                setInnerState(() {
                                  busy = false;
                                  status = 'Web scan selesai. Temuan: ${result.vulnerabilities.length}';
                                  logs.add('[3/3] Selesai. Findings: ${result.vulnerabilities.length}. Errors: ${result.errors.length}.');
                                  if (result.errors.isNotEmpty) {
                                    logs.addAll(result.errors.map((e) => '• $e'));
                                  }
                                });
                                await _refreshReports();
                              },
                      ),
                      const SizedBox(width: 8),
                      Button(
                        child: const Text('Git Status'),
                        onPressed: busy
                            ? null
                            : () async {
                                final projectDir = Directory(item.projectPath);
                                if (!projectDir.existsSync()) {
                                  setInnerState(() => status = 'Path project tidak ditemukan di mesin ini.');
                                  return;
                                }
                                final res = await _git.status(item.projectPath);
                                setInnerState(() => status = (res.stdout.toString().trim().isEmpty) ? 'Working tree clean.' : res.stdout.toString());
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InfoLabel(label: 'Commit message', child: TextBox(controller: commitController, placeholder: 'chore(security): fix after scan')),                  
                ],
              ),
            ),
          ),
          actions: [
            Button(
              child: const Text('Commit + Push (Lolos Scan)'),
              onPressed: () async {
                final projectDir = Directory(item.projectPath);
                if (!projectDir.existsSync()) {
                  setState(() {});
                  return;
                }
                final latest = await _repo.getReports();
                final latestForProject = latest.where((e) => e.projectPath == item.projectPath).toList();
                if (latestForProject.isEmpty) return;
                final sev = latestForProject.first.severityCount;
                final high = sev['high'] ?? 0;
                final critical = sev['critical'] ?? 0;
                if (high > 0 || critical > 0) {
                  return;
                }
                final msg = commitController.text.trim().isEmpty ? 'chore(security): safe commit after clean scan' : commitController.text.trim();
                await _git.addAll(item.projectPath);
                await _git.commit(item.projectPath, msg);
                await _git.push(item.projectPath);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            FilledButton(
              child: const Text('Tutup'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<ScanResult>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const ProgressRing();
          final reports = snapshot.data!;
          if (reports.isEmpty) return const Text('Belum ada report tersimpan. Jalankan scan dulu.');
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final item = reports[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.projectPath, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Temuan: ${item.vulnerabilities.length} | Score: ${item.securityScore} | ${item.finishedAt}'),
                      if (item.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Errors:', style: TextStyle(fontWeight: FontWeight.w700)),
                        ...item.errors.map((e) => Text('• $e')),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Button(
                            child: const Text('Copy Errors'),
                            onPressed: item.errors.isEmpty ? null : () => Clipboard.setData(ClipboardData(text: item.errors.join('\n'))),
                          ),
                          const SizedBox(width: 8),
                          Button(
                            child: const Text('Export PDF'),
                            onPressed: () => _exportPdfReport(item),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            child: const Text('Detail / Git'),
                            onPressed: () => _openDetail(item),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
