import 'dart:io';

class GitService {
  Future<ProcessResult> status(String projectPath) =>
      Process.run('git', ['-C', projectPath, 'status', '--short']);

  Future<ProcessResult> addAll(String projectPath) =>
      Process.run('git', ['-C', projectPath, 'add', '.']);

  Future<ProcessResult> commit(String projectPath, String message) =>
      Process.run('git', ['-C', projectPath, 'commit', '-m', message]);

  Future<ProcessResult> push(String projectPath) =>
      Process.run('git', ['-C', projectPath, 'push']);

  Future<void> installPrePushHook(
      String projectPath, {
        required int threshold,
      }) async {
    final hook = File('$projectPath/.git/hooks/pre-push');

    await hook.create(recursive: true);

    await hook.writeAsString('''#!/usr/bin/env bash
# SecurePush pre-push hook

if [ -f .securepush_last_scan ]; then
  score=\$(cat .securepush_last_scan)

  if [ "\$score" -lt "$threshold" ]; then
    echo "[SecurePush] Push blocked. Security score below threshold: $threshold"
    exit 1
  fi
fi

exit 0
''');

    await Process.run('chmod', ['+x', hook.path]);
  }
}