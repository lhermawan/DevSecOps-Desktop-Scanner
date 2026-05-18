import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../services/git_service.dart';
import '../../services/tool_installer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _installer = ToolInstallerService();
  final _git = GitService();

  Map<String, bool> _toolStatus = {};

  String _installHint =
      'Klik "Check All Tools" untuk cek semua tools scanner.';

  bool _isInstalling = false;
  bool _isChecking = false;
  bool _isInstallingHook = false;

  String _gitStatus = 'Belum ada project git dipilih.';

  // =========================
  // CHECK ALL TOOLS
  // =========================
  Future<void> _checkAllTools() async {
    setState(() {
      _isChecking = true;
      _installHint = 'Sedang mengecek semua tools...';
    });

    try {
      final result = await _installer.checkAllTools();

      setState(() {
        _toolStatus = result;
        _installHint =
        'Pilih tool lalu klik "Install Guide" atau "Install".';
      });
    } catch (e) {
      setState(() {
        _installHint = 'Gagal cek tools: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  // =========================
  // INSTALL TOOL
  // =========================
  Future<void> _installTool(String tool) async {
    setState(() {
      _isInstalling = true;
      _installHint = 'Menjalankan installer untuk $tool...';
    });

    try {
      final result = await _installer.runInstall(tool);

      setState(() {
        _installHint = '[$tool] ${result.message}';
      });

      if (result.success) {
        await _checkAllTools();
      }
    } catch (e) {
      setState(() {
        _installHint = '[$tool] Install gagal: $e';
      });
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  // =========================
  // INSTALL GUIDE
  // =========================
  Future<void> _showInstallHint(String tool) async {
    try {
      final message = await _installer.getInstallCommand(tool);

      setState(() {
        _installHint = '[$tool] $message';
      });
    } catch (e) {
      setState(() {
        _installHint = '[$tool] Gagal mengambil panduan install: $e';
      });
    }
  }

  // =========================
  // INSTALL GIT HOOK
  // =========================
  Future<void> _installGitHook() async {
    try {
      setState(() {
        _isInstallingHook = true;
      });

      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih root project git',
      );

      if (path == null) {
        setState(() {
          _gitStatus = 'Pemilihan folder dibatalkan.';
        });

        return;
      }

      await _git.installPrePushHook(path);

      setState(() {
        _gitStatus =
        '✅ Hook pre-push berhasil dipasang di:\n$path\n\nPush akan diblok jika severity High/Critical > 0.';
      });
    } catch (e) {
      setState(() {
        _gitStatus = '❌ Gagal install git hook:\n$e';
      });
    } finally {
      setState(() {
        _isInstallingHook = false;
      });
    }
  }

  // =========================
  // TOOL STATUS TEXT
  // =========================
  String _getStatusText(bool? status) {
    if (status == null) {
      return 'Belum dicek';
    }

    return status
        ? 'Terpasang ✅'
        : 'Belum ditemukan ❌';
  }

  // =========================
  // TOOL ICON
  // =========================
  IconData _getToolIcon(String tool) {
    switch (tool.toLowerCase()) {
      case 'git':
        return FluentIcons.open_source;

      case 'docker':
        return FluentIcons.developer_tools;

      case 'python':
        return FluentIcons.code;

      case 'trivy':
        return FluentIcons.shield;

      case 'semgrep':
        return FluentIcons.search;

      case 'zap':
        return FluentIcons.warning;

      default:
        return FluentIcons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          // =========================
          // HEADER
          // =========================
          const Text(
            'Scanner Tools Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Cek ketersediaan semua tools scanner dan jalankan installer otomatis.',
          ),

          const SizedBox(height: 20),

          // =========================
          // CHECK BUTTON
          // =========================
          FilledButton(
            onPressed: _isChecking ? null : _checkAllTools,
            child: _isChecking
                ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: ProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Checking...'),
              ],
            )
                : const Text('Check All Tools'),
          ),

          const SizedBox(height: 20),

          // =========================
          // TOOLS LIST
          // =========================
          ...ToolInstallerService.supportedTools.map((tool) {
            final status = _toolStatus[tool];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _getToolIcon(tool),
                      size: 28,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _getStatusText(status),
                          ),
                        ],
                      ),
                    ),

                    Button(
                      onPressed: () => _showInstallHint(tool),
                      child: const Text('Install Guide'),
                    ),

                    const SizedBox(width: 8),

                    FilledButton(
                      onPressed: _isInstalling
                          ? null
                          : () => _installTool(tool),
                      child: const Text('Install'),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // =========================
          // INFO BAR
          // =========================
          InfoBar(
            title: const Text('Install Information'),
            content: Text(_installHint),
            severity: InfoBarSeverity.info,
          ),

          const SizedBox(height: 32),

          // =========================
          // GIT PROTECTION
          // =========================
          const Text(
            'Git Protection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Install pre-push hook untuk memblok push jika masih ada vulnerability High/Critical.',
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _isInstallingHook ? null : _installGitHook,
            child: _isInstallingHook
                ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: ProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Installing Hook...'),
              ],
            )
                : const Text('Install Pre-Push Hook'),
          ),

          const SizedBox(height: 12),

          InfoBar(
            title: const Text('Git Hook Status'),
            content: Text(_gitStatus),
            severity: InfoBarSeverity.success,
          ),
        ],
      ),
    );
  }
}