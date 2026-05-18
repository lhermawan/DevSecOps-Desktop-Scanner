import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

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
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
        GoRoute(path: '/report', builder: (context, state) => const ReportScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    );

    return FluentApp.router(
      title: 'SecurePush',
      theme: FluentThemeData(brightness: Brightness.dark, accentColor: Colors.blue),
      routerConfig: router,
    );
  }
}
