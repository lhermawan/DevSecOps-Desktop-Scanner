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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = [
    'DevOps Security Dashboard',
    'Code & Web Scanning',
    'Security Reports',
    'Protection Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const ScanScreen(),
      const ReportScreen(),
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
          child: Text('Protection Areas', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        items: [
          PaneItem(icon: const Icon(FluentIcons.view_dashboard), title: const Text('Dashboard'), body: pages[0]),
          PaneItem(icon: const Icon(FluentIcons.search), title: const Text('Scan'), body: pages[1]),
          PaneItem(icon: const Icon(FluentIcons.report_document), title: const Text('Report'), body: pages[2]),
          PaneItem(icon: const Icon(FluentIcons.settings), title: const Text('Settings'), body: pages[3]),
        ],
      ),
      content: NavigationBody(index: _index, children: pages.map((page) => _ShellPage(title: _titles[_index], child: page)).toList()),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text(title)),
      content: child,
    );
  }
}
