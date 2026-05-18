import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/scan_result.dart';
import '../models/vulnerability.dart';
import 'gitleaks_service.dart';
import 'nuclei_service.dart';
import 'semgrep_service.dart';
import 'tool_installer_service.dart';
import 'trivy_service.dart';
import 'zap_service.dart';

class ScannerService {
  ScannerService({
    GitleaksService? gitleaks,
    SemgrepService? semgrep,
    TrivyService? trivy,
    NucleiService? nuclei,
    ZapService? zap,
    ToolInstallerService? installer,
  })  : _gitleaks = gitleaks ?? GitleaksService(),
        _semgrep = semgrep ?? SemgrepService(),
        _trivy = trivy ?? TrivyService(),
        _nuclei = nuclei ?? NucleiService(),
        _zap = zap ?? ZapService(),
        _installer = installer ?? ToolInstallerService();

  final GitleaksService _gitleaks;
  final SemgrepService _semgrep;
  final TrivyService _trivy;
  final NucleiService _nuclei;
  final ZapService _zap;
  final ToolInstallerService _installer;

  static const codeTools = ['gitleaks', 'semgrep', 'trivy'];
  static const webTools = ['nuclei', 'zap-baseline.py'];

  Future<ScanResult> runAll(String projectPath) async {
    final startedAt = DateTime.now();
    final vulnerabilities = <Vulnerability>[];
    final errors = <String>[];

    vulnerabilities.addAll(await _runGitleaks(projectPath, errors));
    vulnerabilities.addAll(await _runSemgrep(projectPath, errors));
    vulnerabilities.addAll(await _runTrivy(projectPath, errors));

    return ScanResult(
      projectPath: projectPath,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      vulnerabilities: vulnerabilities,
      errors: errors,
    );
  }

  Future<List<String>> getMissingCodeTools() => getMissingTools(codeTools);

  Future<List<String>> getMissingWebTools() => getMissingTools(webTools);

  Future<List<String>> getMissingTools(List<String> tools) async {
    final missing = <String>[];
    for (final tool in tools) {
      final installed = await _isInstalled(tool);
      if (!installed) {
        missing.add(tool);
      }
    }
    return missing;
  }

  Future<List<Vulnerability>> _runGitleaks(String path, List<String> errors) async {
    final result = await _runProcess('gitleaks', ['detect', '--source', path, '--report-format', 'json', '--report-path', '-']);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _gitleaks.parse(result.stdout.toString()), errors, 'gitleaks');
  }

  Future<List<Vulnerability>> _runSemgrep(String path, List<String> errors) async {
    final result = await _runProcess('semgrep', ['scan', '--config=auto', '--json', path]);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _semgrep.parse(result.stdout.toString()), errors, 'semgrep');
  }

  Future<List<Vulnerability>> _runTrivy(String path, List<String> errors) async {
    final result = await _runProcess('trivy', ['fs', '--format', 'json', path]);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _trivy.parse(result.stdout.toString()), errors, 'trivy');
  }

  Future<List<Vulnerability>> _runNuclei(String targetUrl, List<String> errors) async {
    final result = await _runProcess('nuclei', ['-u', targetUrl, '-jsonl']);
    if (result == null) {
      final diag = await _diagnoseCommand('nuclei');
      errors.add('nuclei error: process gagal dijalankan. $diag');
      return [];
    }
    final stdout = result.stdout.toString();
    final stderr = result.stderr.toString().trim();
    if (result.exitCode != 0 && stderr.isNotEmpty) {
      errors.add('nuclei error: $stderr');
    }
    if (stdout.trim().isEmpty) {
      errors.add('nuclei info: tidak ada output finding (bisa jadi tidak ada temuan).');
      return [];
    }
    return _safeParse(() => _nuclei.parseJsonl(stdout), errors, 'nuclei');
  }

  Future<List<Vulnerability>> runZapBaseline(String targetUrl, List<String> errors) async {
    final tempDir = await Directory.systemTemp.createTemp('securepush-zap-');
    final reportPath = p.join(tempDir.path, 'zap-report.json');
    final result = await _runProcess('zap-baseline.py', ['-t', targetUrl, '-J', reportPath]);
    if (result == null) {
      final diag = await _diagnoseCommand('zap-baseline.py');
      errors.add('zap error: process gagal dijalankan. $diag');
      return [];
    }
    try {
      final reportFile = File(reportPath);
      if (!reportFile.existsSync()) {
        final stderr = result.stderr.toString().trim();
        errors.add(stderr.isNotEmpty ? 'zap error: $stderr' : 'zap error: report JSON tidak terbentuk. Cek apakah zap-baseline.py tersedia di PATH.');
        return [];
      }
      final raw = await reportFile.readAsString();
      if (raw.trim().isEmpty) return [];
      return _safeParse(() => _zap.parse(raw), errors, 'zap');
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<ScanResult> runWebScan(String targetUrl) async {
    final startedAt = DateTime.now();
    final findings = <Vulnerability>[];
    final errors = <String>[];
    findings.addAll(await _runNuclei(targetUrl, errors));
    findings.addAll(await runZapBaseline(targetUrl, errors));
    return ScanResult(
      projectPath: targetUrl,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      vulnerabilities: findings,
      errors: errors,
    );
  }

  Future<bool> _isInstalled(String toolName) => _installer.isInstalled(toolName);

  Future<ProcessResult?> _runProcess(String cmd, List<String> args) async {
    try {
      return await Process.run(cmd, args);
    } on ProcessException {
      return null;
    }
  }



  Future<String> _diagnoseCommand(String cmd) async {
    try {
      if (Platform.isWindows) {
        final whereResult = await Process.run('where.exe', [cmd]);
        if (whereResult.exitCode == 0) {
          final location = whereResult.stdout.toString().trim().split('\n').first;
          return 'Command ditemukan di: $location';
        }
        return 'Command tidak ditemukan di PATH Windows (where.exe).';
      }
      final whichResult = await Process.run('which', [cmd]);
      if (whichResult.exitCode == 0) {
        return 'Command ditemukan di: ${whichResult.stdout.toString().trim()}';
      }
      return 'Command tidak ditemukan di PATH (which).';
    } catch (e) {
      return 'Gagal diagnosis command: $e';
    }
  }
  List<Vulnerability> _safeParse(List<Vulnerability> Function() parser, List<String> errors, String tool) {
    try {
      return parser();
    } catch (e) {
      errors.add('$tool parse error: $e');
      return [];
    }
  }
}
