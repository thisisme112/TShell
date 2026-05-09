import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'services/app_database.dart';
import 'services/credential_store.dart';
import 'services/monitor_agent_service.dart';
import 'services/remote_file_service.dart';
import 'services/ssh_connection_service.dart';

class SessionTab {
  SessionTab({
    required this.id,
    required this.host,
    required this.terminal,
    required this.files,
    required this.monitor,
  });

  final String id;
  final HostProfile host;
  final TerminalSession terminal;
  final RemoteFileService files;
  final MonitorAgentService monitor;
  MetricSnapshot? latestMetrics;
  StreamSubscription<MetricSnapshot>? metricSub;
}

class AppController extends ChangeNotifier {
  final AppDatabase database = AppDatabase();
  final CredentialStore credentials = CredentialStore();
  late final SshConnectionService ssh = SshConnectionService(credentials);
  final _uuid = const Uuid();

  List<HostProfile> hosts = [];
  final List<SessionTab> sessions = [];
  int selectedSession = -1;
  String search = '';

  Future<void> init() async {
    await database.open();
    hosts = await database.listHosts();
  }

  List<HostProfile> get filteredHosts {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) {
      return hosts;
    }
    return hosts.where((host) {
      return host.name.toLowerCase().contains(q) ||
          host.hostname.toLowerCase().contains(q) ||
          host.username.toLowerCase().contains(q) ||
          host.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  SessionTab? get activeSession {
    if (selectedSession < 0 || selectedSession >= sessions.length) {
      return null;
    }
    return sessions[selectedSession];
  }

  Future<void> saveHost({
    String? id,
    required String name,
    required String hostname,
    required int port,
    required String username,
    required List<String> tags,
    required String note,
    required String osHint,
    required AuthType authType,
    required String secret,
    String passphrase = '',
  }) async {
    final now = DateTime.now();
    final existing = id == null ? null : _findHost(id);
    final credentialRef = existing?.credentialRef ?? _uuid.v4();
    final host = HostProfile(
      id: id ?? _uuid.v4(),
      name: name.trim().isEmpty ? hostname.trim() : name.trim(),
      hostname: hostname.trim(),
      port: port,
      username: username.trim(),
      tags:
          tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
      note: note.trim(),
      osHint: osHint,
      authType: authType,
      credentialRef: credentialRef,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (secret.trim().isNotEmpty) {
      if (authType == AuthType.password) {
        await credentials.savePassword(credentialRef, secret);
      } else {
        await credentials.savePrivateKey(credentialRef, secret, passphrase);
      }
    }
    await database.saveHost(host);
    hosts = await database.listHosts();
    notifyListeners();
  }

  Future<void> deleteHost(HostProfile host) async {
    await database.deleteHost(host.id);
    await credentials.delete(host.credentialRef);
    hosts = await database.listHosts();
    notifyListeners();
  }

  Future<void> connect(HostProfile host) async {
    final id = _uuid.v4();
    final connection = await ssh.connect(host);
    final terminal = TerminalSession(
      id: id,
      host: host,
      connection: connection,
    );
    final tab = SessionTab(
      id: id,
      host: host,
      terminal: terminal,
      files: RemoteFileService(connection),
      monitor: MonitorAgentService(connection),
    );
    sessions.add(tab);
    selectedSession = sessions.length - 1;
    notifyListeners();
    await database.recordSession(host.id);
    try {
      await terminal.start();
      unawaited(tab.monitor.start());
      tab.metricSub = tab.monitor.snapshots.listen((snapshot) {
        tab.latestMetrics = snapshot;
        notifyListeners();
      });
    } finally {
      notifyListeners();
    }
  }

  Future<void> closeSession(SessionTab tab) async {
    final index = sessions.indexOf(tab);
    await tab.metricSub?.cancel();
    await tab.monitor.dispose();
    await tab.files.close();
    await tab.terminal.close();
    sessions.remove(tab);
    if (sessions.isEmpty) {
      selectedSession = -1;
    } else if (selectedSession >= sessions.length) {
      selectedSession = sessions.length - 1;
    } else if (index <= selectedSession) {
      selectedSession = (selectedSession - 1).clamp(0, sessions.length - 1);
    }
    notifyListeners();
  }

  void selectSession(int index) {
    selectedSession = index;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  Future<String> exportJson() async {
    return const JsonEncoder.withIndent('  ')
        .convert(await database.exportPublicData());
  }

  HostProfile? _findHost(String id) {
    for (final host in hosts) {
      if (host.id == id) return host;
    }
    return null;
  }
}
