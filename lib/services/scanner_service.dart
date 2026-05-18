import 'dart:io';

import '../models/scan_result.dart';
import '../models/vulnerability.dart';
import 'gitleaks_service.dart';
import 'nuclei_service.dart';
import 'semgrep_service.dart';
import 'trivy_service.dart';
import 'zap_service.dart';

class ScannerService {
  ScannerService({
    GitleaksService? gitleaks,
    SemgrepService? semgrep,
    TrivyService? trivy,
    NucleiService? nuclei,
    ZapService? zap,
  })  : _gitleaks = gitleaks ?? GitleaksService(),
        _semgrep = semgrep ?? SemgrepService(),
        _trivy = trivy ?? TrivyService(),
        _nuclei = nuclei ?? NucleiService(),
        _zap = zap ?? ZapService();

  final GitleaksService _gitleaks;
  final SemgrepService _semgrep;
  final TrivyService _trivy;
  final NucleiService _nuclei;
  final ZapService _zap;

  static const codeTools = ['gitleaks', 'semgrep', 'trivy'];
  static const webTools = ['nuclei', 'zap-baseline.py'];

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

  Future<List<Vulnerability>> _runGitleaks(String path) async {
    final result = await _runProcess('gitleaks', ['detect', '--source', path, '--report-format', 'json', '--report-path', '-']);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _gitleaks.parse(result.stdout.toString()));
  }

  Future<List<Vulnerability>> _runSemgrep(String path) async {
    final result = await _runProcess('semgrep', ['scan', '--config=auto', '--json', path]);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _semgrep.parse(result.stdout.toString()));
  }

  Future<List<Vulnerability>> _runTrivy(String path) async {
    final result = await _runProcess('trivy', ['fs', '--format', 'json', path]);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _trivy.parse(result.stdout.toString()));
  }

  Future<List<Vulnerability>> _runNuclei(String targetUrl) async {
    final result = await _runProcess('nuclei', ['-u', targetUrl, '-jsonl', '-silent']);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _nuclei.parseJsonl(result.stdout.toString()));
  }

  Future<List<Vulnerability>> runZapBaseline(String targetUrl) async {
    final result = await _runProcess('zap-baseline.py', ['-t', targetUrl, '-J', '-']);
    return result == null || result.stdout.toString().trim().isEmpty
        ? []
        : _safeParse(() => _zap.parse(result.stdout.toString()));
  }

  Future<List<Vulnerability>> runWebScan(String targetUrl) async {
    final findings = <Vulnerability>[];
    findings.addAll(await _runNuclei(targetUrl));
    findings.addAll(await runZapBaseline(targetUrl));
    return findings;
  }

  Future<bool> _isInstalled(String toolName) async {
    final cmd = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(cmd, [toolName]);
    return result.exitCode == 0;
  }

  Future<ProcessResult?> _runProcess(String cmd, List<String> args) async {
    try {
      return await Process.run(cmd, args);
    } on ProcessException {
      return null;
    }
  }

  List<Vulnerability> _safeParse(List<Vulnerability> Function() parser) {
    try {
      return parser();
    } catch (_) {
      return [];
    }
  }
}
