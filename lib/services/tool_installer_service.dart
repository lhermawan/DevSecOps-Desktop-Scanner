import 'dart:io';

class ToolInstallerService {
  static const supportedTools = <String>[
    'gitleaks',
    'semgrep',
    'trivy',
    'nuclei',
    'zap-baseline.py',
  ];

  Future<bool> isInstalled(String toolName) async {
    final cmd = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(cmd, [toolName]);
    return result.exitCode == 0;
  }

  Future<Map<String, bool>> checkAllTools() async {
    final result = <String, bool>{};
    for (final tool in supportedTools) {
      result[tool] = await isInstalled(tool);
    }
    return result;
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
