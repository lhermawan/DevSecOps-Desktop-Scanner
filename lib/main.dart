import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const SecurePushApp());
}

class SecurePushApp extends StatelessWidget {
  const SecurePushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'SecurePush - DevOps Dashboard',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
      ),
      home: const ProjectBootstrapScreen(),
    );
  }
}

class ProjectBootstrapScreen extends StatefulWidget {
  const ProjectBootstrapScreen({super.key});

  @override
  State<ProjectBootstrapScreen> createState() => _ProjectBootstrapScreenState();
}

class _ProjectBootstrapScreenState extends State<ProjectBootstrapScreen> {
  String? _selectedPath;

  Future<void> _pickProject() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih folder project utama',
    );

    if (path == null) return;

    setState(() => _selectedPath = path);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Pilih Project Dulu')),
        content: Center(
          child: SizedBox(
            width: 640,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konsep workspace seperti VS Code: 1 aplikasi fokus 1 project aktif.',
                    ),
                    const SizedBox(height: 12),
                    Text(_selectedPath == null ? 'Belum ada folder dipilih.' : 'Project aktif: $_selectedPath'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _pickProject,
                          child: const Text('Pilih Folder Project'),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: _selectedPath == null
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    FluentPageRoute(
                                      builder: (_) => AppShell(initialProjectPath: _selectedPath!),
                                    ),
                                  );
                                },
                          child: const Text('Buka Workspace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.initialProjectPath});

  final String initialProjectPath;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late String _projectPath;

  static const _titles = [
    'DevOps Security Dashboard',
    'Code & Web Scanning',
    'Security Reports',
    'Protection Settings',
  ];

  @override
  void initState() {
    super.initState();
    _projectPath = widget.initialProjectPath;
  }

  Future<void> _switchProject() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Ganti folder project aktif',
    );
    if (path == null) return;
    setState(() => _projectPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _projectPath.split(RegExp(r'[\\/]')).where((e) => e.isNotEmpty).isNotEmpty
        ? _projectPath.split(RegExp(r'[\\/]')).where((e) => e.isNotEmpty).last
        : _projectPath;

    final pages = [
      DashboardScreen(projectPath: _projectPath),
      ScanScreen(projectPath: _projectPath),
      ReportScreen(projectPath: _projectPath),
      const SettingsScreen(),
    ];

    return NavigationView(
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        displayMode: PaneDisplayMode.auto,
        size: const NavigationPaneSize(openWidth: 280),
        header: const Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Text(
            'Protection Areas',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Tooltip(
                message: _projectPath,
                child: Text(
                  projectName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Button(onPressed: _switchProject, child: const Text('Ganti Project')),
            ],
          ),
        ),
        items: [
          PaneItem(icon: const Icon(FluentIcons.view_dashboard), title: const Text('Dashboard'), body: _ShellPage(title: _titles[0], child: pages[0])),
          PaneItem(icon: const Icon(FluentIcons.search), title: const Text('Scan'), body: _ShellPage(title: _titles[1], child: pages[1])),
          PaneItem(icon: const Icon(FluentIcons.report_document), title: const Text('Report'), body: _ShellPage(title: _titles[2], child: pages[2])),
          PaneItem(icon: const Icon(FluentIcons.settings), title: const Text('Settings'), body: _ShellPage(title: _titles[3], child: pages[3])),
        ],
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(header: PageHeader(title: Text(title)), content: child);
  }
}
