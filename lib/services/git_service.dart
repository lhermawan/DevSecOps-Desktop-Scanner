import 'dart:convert';
import 'dart:io';

class GitService {
  Future<ProcessResult> status(String projectPath) => Process.run('git', ['-C', projectPath, 'status', '--short']);

  Future<ProcessResult> addAll(String projectPath) => Process.run('git', ['-C', projectPath, 'add', '.']);

  Future<ProcessResult> commit(String projectPath, String message) => Process.run('git', ['-C', projectPath, 'commit', '-m', message]);

  Future<ProcessResult> push(String projectPath) => Process.run('git', ['-C', projectPath, 'push']);

  Future<void> installPrePushHook(String projectPath) async {
    final hook = File('$projectPath/.git/hooks/pre-push');
    await hook.create(recursive: true);
    await hook.writeAsString('''#!/usr/bin/env bash
# SecurePush pre-push hook

if [ -f .securepush_last_scan.json ]; then
  critical=$(python3 - <<'PY'
import json
with open('.securepush_last_scan.json','r',encoding='utf-8') as f:
    data=json.load(f)
print(int(data.get('critical',0)))
PY
)
  high=$(python3 - <<'PY'
import json
with open('.securepush_last_scan.json','r',encoding='utf-8') as f:
    data=json.load(f)
print(int(data.get('high',0)))
PY
)

  if [ "$critical" -gt 0 ] || [ "$high" -gt 0 ]; then
    echo "[SecurePush] Push blocked. Found high/critical vulnerabilities (critical=$critical, high=$high)."
    exit 1
  fi
fi

exit 0
''');
    await Process.run('chmod', ['+x', hook.path]);
  }

  Future<void> writeLastScanSummary(
    String projectPath, {
    required int critical,
    required int high,
    required int medium,
    required int low,
    required int score,
  }) async {
    final file = File('$projectPath/.securepush_last_scan.json');
    final payload = {
      'critical': critical,
      'high': high,
      'medium': medium,
      'low': low,
      'score': score,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(payload));
  }
}
