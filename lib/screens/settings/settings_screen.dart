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
  String _installHint = 'Klik check untuk cek semua tools scanner.';
  bool _isInstalling = false;
  String _gitStatus = 'Belum ada project git dipilih.';

  Future<void> _checkAllTools() async {
    final result = await _installer.checkAllTools();
    setState(() {
      _toolStatus = result;
      _installHint = 'Pilih tool lalu klik tombol panduan install.';
    });
  }

  Future<void> _installTool(String tool) async {
    setState(() {
      _isInstalling = true;
      _installHint = 'Menjalankan installer untuk $tool...';
    });

    final result = await _installer.runInstall(tool);

    setState(() {
      _isInstalling = false;
      _installHint = '[$tool] ${result.message}';
    });

    if (result.success) {
      await _checkAllTools();
    }
  }

  Future<void> _showInstallHint(String tool) async {
    final message = await _installer.getInstallCommand(tool);
    setState(() => _installHint = '[$tool] $message');
  }

  Future<void> _installGitHook() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pilih root project git');
    if (path == null) return;
    await _git.installPrePushHook(path);
    setState(() {
      _gitStatus = 'Hook pre-push terpasang di: $path (block jika severity high/critical > 0).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Scanner Tools Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Cek ketersediaan semua tools scanner dan lihat command install resmi per OS.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _checkAllTools, child: const Text('Check All Tools')),
          const SizedBox(height: 12),
          ...ToolInstallerService.supportedTools.map((tool) {
            final status = _toolStatus[tool];
            final statusText = status == null ? 'Belum dicek' : (status ? 'Terpasang ✅' : 'Belum ❌');
            return Card(
              child: ListTile(
                title: Text(tool),
                subtitle: Text(statusText),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Button(onPressed: () => _showInstallHint(tool), child: const Text('Install Guide')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isInstalling ? null : () => _installTool(tool),
                      child: const Text('Install'),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          InfoBar(
            title: const Text('Install Hint'),
            content: Text(_installHint),
            severity: InfoBarSeverity.info,
          ),
          const SizedBox(height: 24),
          const Text('Git Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Install hook pre-push untuk block push kalau masih ada severity High/Critical.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _installGitHook, child: const Text('Install Pre-Push Hook')),
          const SizedBox(height: 8),
          Text(_gitStatus),
        ],
      ),
    );
  }
}
