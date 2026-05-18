import 'dart:convert';
import 'dart:io';


class InstallExecutionResult {
  const InstallExecutionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class ToolInstallerService {
  static const supportedTools = <String>[
    'gitleaks',
    'semgrep',
    'trivy',
    'nuclei',
    'zap-baseline.py',
  ];

  Future<bool> isInstalled(String toolName) async {
    if (await _isOnPath(toolName)) {
      return true;
    }

    // Fallback untuk kasus PATH GUI belum sinkron, tapi binary tetap bisa dieksekusi.
    return _isRunnable(toolName);
  }

  Future<bool> _isOnPath(String toolName) async {
    if (Platform.isWindows) {
      final whereResult = await Process.run('where.exe', [toolName]);
      if (whereResult.exitCode == 0) {
        return true;
      }

      // Fallback PowerShell jika PATH/alias environment berbeda.
      final psResult = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        "Get-Command $toolName -ErrorAction SilentlyContinue | Select-Object -First 1",
      ]);
      return psResult.exitCode == 0 && psResult.stdout.toString().trim().isNotEmpty;
    }

    final result = await Process.run('which', [toolName]);
    return result.exitCode == 0;
  }

  Future<bool> _isRunnable(String toolName) async {
    const versionArgs = <List<String>>[
      ['--version'],
      ['version'],
      ['-version'],
      ['-v'],
      ['v'],
    ];

    for (final args in versionArgs) {
      try {
        final result = await Process.run(toolName, args);
        if (result.exitCode == 0) {
          return true;
        }
      } on ProcessException {
        // Abaikan command yang memang tidak support argumen ini.
      }
    }

    return false;
  }

  Future<Map<String, bool>> checkAllTools() async {
    final result = <String, bool>{};
    for (final tool in supportedTools) {
      result[tool] = await isInstalled(tool);
    }
    return result;
  }


  Future<InstallExecutionResult> runInstall(String toolName) async {
    final normalized = toolName.trim();
    if (await isInstalled(normalized)) {
      return InstallExecutionResult(success: true, message: '$normalized sudah terinstall.');
    }

    final installCommand = await getInstallCommand(normalized);
    if (installCommand == 'Tool tidak dikenali.') {
      return const InstallExecutionResult(success: false, message: 'Tool tidak dikenali.');
    }

    if (Platform.isWindows) {
      return _runWindowsAsAdmin(installCommand);
    }

    return InstallExecutionResult(
      success: false,
      message: 'Auto-install hanya didukung di Windows. Jalankan manual: $installCommand',
    );
  }

  Future<InstallExecutionResult> _runWindowsAsAdmin(String installCommand) async {
    try {
      final encoded = base64Encode(utf8.encode(installCommand));
      final script = """
\$cmd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encoded'))
Start-Process -FilePath powershell -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command',\$cmd)
""";

      final result = await Process.run('powershell', ['-NoProfile', '-Command', script]);

      if (result.exitCode == 0) {
        return const InstallExecutionResult(
          success: true,
          message: 'Installer dijalankan dengan hak administrator. Cek jendela PowerShell yang muncul.',
        );
      }

      return InstallExecutionResult(
        success: false,
        message: 'Gagal menjalankan installer (exit: ${result.exitCode}). ${result.stderr}',
      );
    } on ProcessException catch (e) {
      return InstallExecutionResult(success: false, message: 'Gagal memulai installer: ${e.message}');
    }
  }

  Future<String> getInstallCommand(String toolName) async {
    final normalized = toolName.trim();
    if (await isInstalled(normalized)) {
      return '$normalized sudah terinstall.';
    }

    if (Platform.isWindows) {
      return _windowsInstall(normalized);
    }
    if (Platform.isMacOS) {
      return _macInstall(normalized);
    }
    return _linuxInstall(normalized);
  }

  String _windowsInstall(String tool) {
    switch (tool) {
      case 'gitleaks':
        return 'winget install GitLeaks.Gitleaks';
      case 'semgrep':
        return 'pip install semgrep';
      case 'trivy':
        return 'winget install AquaSecurity.Trivy';
      case 'nuclei':
        return 'go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest';
      case 'zap-baseline.py':
        return 'winget install OWASP.ZAP';
      default:
        return 'Tool tidak dikenali.';
    }
  }

  String _macInstall(String tool) {
    switch (tool) {
      case 'gitleaks':
        return 'brew install gitleaks';
      case 'semgrep':
        return 'brew install semgrep';
      case 'trivy':
        return 'brew install trivy';
      case 'nuclei':
        return 'brew install nuclei';
      case 'zap-baseline.py':
        return 'brew install --cask owasp-zap';
      default:
        return 'Tool tidak dikenali.';
    }
  }

  String _linuxInstall(String tool) {
    switch (tool) {
      case 'gitleaks':
        return 'curl -sSL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh';
      case 'semgrep':
        return 'python3 -m pip install semgrep';
      case 'trivy':
        return 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh';
      case 'nuclei':
        return 'go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest';
      case 'zap-baseline.py':
        return 'sudo snap install zaproxy --classic';
      default:
        return 'Tool tidak dikenali.';
    }
  }
}
