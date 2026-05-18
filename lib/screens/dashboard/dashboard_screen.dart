import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(title: const Text('SecurePush Dashboard')),
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DevSecOps Desktop Scanner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Scan source code sebelum push/deploy untuk mencegah secret leak dan vulnerability.'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                Button(child: const Text('Mulai Scan'), onPressed: () => context.go('/scan')),
                Button(child: const Text('Lihat Report'), onPressed: () => context.go('/report')),
                Button(child: const Text('Settings'), onPressed: () => context.go('/settings')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
