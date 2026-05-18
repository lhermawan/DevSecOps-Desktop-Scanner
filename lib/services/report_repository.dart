import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/scan_result.dart';
import '../models/vulnerability.dart';

class ReportRepository {
  static final ReportRepository instance = ReportRepository._();
  ReportRepository._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'securepush_reports.db');
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE scan_reports(id INTEGER PRIMARY KEY AUTOINCREMENT, project_path TEXT NOT NULL, started_at TEXT NOT NULL, finished_at TEXT NOT NULL, vulnerabilities_json TEXT NOT NULL, errors_json TEXT NOT NULL)',
    );
  }

  Future<int> saveScanResult(ScanResult result) async {
    final db = await database;
    return db.insert('scan_reports', {
      'project_path': result.projectPath,
      'started_at': result.startedAt.toIso8601String(),
      'finished_at': result.finishedAt.toIso8601String(),
      'vulnerabilities_json': jsonEncode(result.vulnerabilities.map((e) => e.toMap()).toList()),
      'errors_json': jsonEncode(result.errors),
    });
  }

  Future<List<ScanResult>> getReports() async {
    final db = await database;
    final rows = await db.query('scan_reports', orderBy: 'finished_at DESC');
    return rows.map((row) {
      final vulnList = (jsonDecode((row['vulnerabilities_json'] ?? '[]').toString()) as List<dynamic>)
          .map((e) => Vulnerability.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      final errors = (jsonDecode((row['errors_json'] ?? '[]').toString()) as List<dynamic>).map((e) => e.toString()).toList();
      return ScanResult(
        id: (row['id'] as num?)?.toInt(),
        projectPath: row['project_path'].toString(),
        startedAt: DateTime.parse(row['started_at'].toString()),
        finishedAt: DateTime.parse(row['finished_at'].toString()),
        vulnerabilities: vulnList,
        errors: errors,
      );
    }).toList();
  }
}
