import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/scan_result.dart';
import '../../services/report_repository.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repo = ReportRepository.instance;
  late Future<List<ScanResult>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _repo.getReports();
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
