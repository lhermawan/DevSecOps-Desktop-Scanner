import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../models/scan_result.dart';
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
  bool _loading = false;
  String? _projectPath;
  ScanResult? _result;

  Future<void> _pickAndScan() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pilih project source code');
    if (path == null) return;

    setState(() {
      _loading = true;
      _projectPath = path;
    });

    final result = await _scanner.runAll(path);
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Scan Project')),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_projectPath == null ? 'Belum ada project dipilih.' : 'Project: $_projectPath'),
              const SizedBox(height: 12),
              ScanButton(onPressed: _pickAndScan, isLoading: _loading),
              const SizedBox(height: 20),
              if (_result != null) ...[
                ScoreCard(score: _result!.securityScore),
                const SizedBox(height: 16),
                VulnerabilityTable(items: _result!.vulnerabilities),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
