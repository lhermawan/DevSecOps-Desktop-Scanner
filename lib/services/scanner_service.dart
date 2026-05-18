import 'dart:io';

import '../models/scan_result.dart';
import '../models/vulnerability.dart';
import 'gitleaks_service.dart';
import 'semgrep_service.dart';
import 'trivy_service.dart';

class ScannerService {
  ScannerService({
    GitleaksService? gitleaks,
    SemgrepService? semgrep,
    TrivyService? trivy,
  })  : _gitleaks = gitleaks ?? GitleaksService(),
        _semgrep = semgrep ?? SemgrepService(),
        _trivy = trivy ?? TrivyService();

  final GitleaksService _gitleaks;
  final SemgrepService _semgrep;
  final TrivyService _trivy;

  Future<ScanResult> runAll(String projectPath) async {
    final startedAt = DateTime.now();
    final vulnerabilities = <Vulnerability>[];

    vulnerabilities.addAll(await _runGitleaks(projectPath));
    vulnerabilities.addAll(await _runSemgrep(projectPath));
    vulnerabilities.addAll(await _runTrivy(projectPath));

    return ScanResult(
      projectPath: projectPath,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      vulnerabilities: vulnerabilities,
    );
  }

  Future<List<Vulnerability>> _runGitleaks(String path) async {
    final result = await Process.run('gitleaks', ['detect', '--source', path, '--report-format', 'json', '--report-path', '-']);
    return result.exitCode == 0 || result.stdout.toString().isNotEmpty
        ? _safeParse(() => _gitleaks.parse(result.stdout.toString()))
        : [];
  }

  Future<List<Vulnerability>> _runSemgrep(String path) async {
    final result = await Process.run('semgrep', ['scan', '--config=auto', '--json', path]);
    return result.exitCode == 0 || result.stdout.toString().isNotEmpty
        ? _safeParse(() => _semgrep.parse(result.stdout.toString()))
        : [];
  }

  Future<List<Vulnerability>> _runTrivy(String path) async {
    final result = await Process.run('trivy', ['fs', '--format', 'json', path]);
    return result.exitCode == 0 || result.stdout.toString().isNotEmpty
        ? _safeParse(() => _trivy.parse(result.stdout.toString()))
        : [];
  }

  List<Vulnerability> _safeParse(List<Vulnerability> Function() parser) {
    try {
      return parser();
    } catch (_) {
      return [];
    }
  }
}
