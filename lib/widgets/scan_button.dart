import 'package:fluent_ui/fluent_ui.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({super.key, required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const Row(mainAxisSize: MainAxisSize.min, children: [ProgressRing(strokeWidth: 2), SizedBox(width: 8), Text('Scanning...')])
          : const Text('Scan Project'),
    );
  }
}
