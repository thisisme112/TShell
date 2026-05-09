import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';

class AppDatabase {
  Database? _db;

  Future<void> open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'tshell.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE hosts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  hostname TEXT NOT NULL,
  port INTEGER NOT NULL,
  username TEXT NOT NULL,
  tags TEXT NOT NULL,
  note TEXT NOT NULL,
  os_hint TEXT NOT NULL,
  auth_type TEXT NOT NULL,
  credential_ref TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('CREATE TABLE host_tags (name TEXT PRIMARY KEY)');
        await db.execute(
          'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute('''
CREATE TABLE recent_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  host_id TEXT NOT NULL,
  opened_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE file_bookmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  host_id TEXT NOT NULL,
  path TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
      },
    );
  }

  Database get db {
    final current = _db;
    if (current == null) {
      throw StateError('Database has not been opened');
    }
    return current;
  }

  Future<List<HostProfile>> listHosts() async {
    final rows = await db.query('hosts', orderBy: 'updated_at DESC');
    return rows.map(HostProfile.fromDb).toList();
  }

  Future<void> saveHost(HostProfile host) async {
    await db.insert(
      'hosts',
      host.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final batch = db.batch();
    for (final tag in host.tags.where((tag) => tag.trim().isNotEmpty)) {
      batch.insert(
        'host_tags',
        {'name': tag.trim()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteHost(String id) async {
    await db.delete('hosts', where: 'id = ?', whereArgs: [id]);
    await db.delete('recent_sessions', where: 'host_id = ?', whereArgs: [id]);
    await db.delete('file_bookmarks', where: 'host_id = ?', whereArgs: [id]);
  }

  Future<void> recordSession(String hostId) async {
    await db.insert('recent_sessions', {
      'host_id': hostId,
      'opened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveSetting(String key, Object value) async {
    await db.insert(
      'settings',
      {'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>> exportPublicData() async {
    final hosts = await listHosts();
    final settings = await db.query('settings');
    return {
      'version': 1,
      'hosts': hosts.map((host) => host.toExport()).toList(),
      'settings': {
        for (final row in settings) row['key'] as String: row['value'],
      },
    };
  }
}
