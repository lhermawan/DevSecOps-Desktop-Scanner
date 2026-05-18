import 'dart:convert';

import '../models/vulnerability.dart';

class NucleiService {
  List<Vulnerability> parseJsonl(String rawOutput) {
    final items = <Vulnerability>[];
    for (final line in rawOutput.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parsed = jsonDecode(line) as Map<String, dynamic>;
      final info = parsed['info'] as Map<String, dynamic>? ?? {};
      final severity = (info['severity']?.toString() ?? 'medium').toLowerCase();
      items.add(
        Vulnerability(
          scanner: 'Nuclei',
          severity: severity[0].toUpperCase() + severity.substring(1),
          file: parsed['matched-at']?.toString() ?? parsed['host']?.toString() ?? '-',
          line: 0,
          issue: info['name']?.toString() ?? parsed['template-id']?.toString() ?? 'Nuclei finding',
          remediation: 'Patch service/configuration based on template recommendation.',
        ),
      );
    }
    return items;
  }
}
