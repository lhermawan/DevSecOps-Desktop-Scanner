import 'dart:convert';

import '../models/vulnerability.dart';

class ZapService {
  List<Vulnerability> parse(String rawOutput) {
    final parsed = jsonDecode(rawOutput) as Map<String, dynamic>;
    final sites = parsed['site'];
    if (sites is! List) return [];

    final findings = <Vulnerability>[];
    for (final site in sites) {
      final alerts = site['alerts'];
      if (alerts is! List) continue;
      for (final alert in alerts) {
        final risk = int.tryParse(alert['riskcode']?.toString() ?? '2') ?? 2;
        final severity = switch (risk) {4 => 'Critical', 3 => 'High', 2 => 'Medium', 1 => 'Low', _ => 'Low'};
        findings.add(
          Vulnerability(
            scanner: 'OWASP ZAP',
            severity: severity,
            file: site['@name']?.toString() ?? '-',
            line: 0,
            issue: alert['name']?.toString() ?? 'DAST finding',
            remediation: alert['solution']?.toString() ?? 'Review OWASP ZAP recommendation.',
          ),
        );
      }
    }

    return findings;
  }
}
