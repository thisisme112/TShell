import 'dart:convert';

enum AuthType { password, privateKey }

enum SessionStatus { connecting, connected, disconnected, failed }

class HostProfile {
  const HostProfile({
    required this.id,
    required this.name,
    required this.hostname,
    required this.port,
    required this.username,
    required this.tags,
    required this.note,
    required this.osHint,
    required this.authType,
    required this.credentialRef,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String hostname;
  final int port;
  final String username;
  final List<String> tags;
  final String note;
  final String osHint;
  final AuthType authType;
  final String credentialRef;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostProfile copyWith({
    String? id,
    String? name,
    String? hostname,
    int? port,
    String? username,
    List<String>? tags,
    String? note,
    String? osHint,
    AuthType? authType,
    String? credentialRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HostProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      osHint: osHint ?? this.osHint,
      authType: authType ?? this.authType,
      credentialRef: credentialRef ?? this.credentialRef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'port': port,
      'username': username,
      'tags': jsonEncode(tags),
      'note': note,
      'os_hint': osHint,
      'auth_type': authType.name,
      'credential_ref': credentialRef,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toExport() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'port': port,
      'username': username,
      'tags': tags,
      'note': note,
      'osHint': osHint,
      'authType': authType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HostProfile.fromDb(Map<String, Object?> map) {
    return HostProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      hostname: map['hostname'] as String,
      port: map['port'] as int,
      username: map['username'] as String,
      tags: List<String>.from(jsonDecode(map['tags'] as String) as List),
      note: map['note'] as String? ?? '',
      osHint: map['os_hint'] as String? ?? 'auto',
      authType: AuthType.values.byName(map['auth_type'] as String),
      credentialRef: map['credential_ref'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class HostCredential {
  const HostCredential({
    this.password,
    this.privateKey,
    this.passphrase,
  });

  final String? password;
  final String? privateKey;
  final String? passphrase;
}

class RemoteFileEntry {
  const RemoteFileEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    required this.permissions,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedAt;
  final String permissions;
}

class MetricSnapshot {
  const MetricSnapshot({
    required this.timestamp,
    required this.cpu,
    required this.memory,
    required this.disks,
    required this.network,
    required this.gpus,
    required this.raw,
  });

  final DateTime timestamp;
  final CpuMetric cpu;
  final MemoryMetric memory;
  final List<DiskMetric> disks;
  final List<NetworkMetric> network;
  final List<GpuMetric> gpus;
  final Map<String, Object?> raw;

  factory MetricSnapshot.fromJson(Map<String, Object?> json) {
    final ts = json['ts'];
    final cpu = Map<String, Object?>.from(json['cpu'] as Map? ?? {});
    final memory = Map<String, Object?>.from(json['memory'] as Map? ?? {});
    final disks = (json['disks'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => DiskMetric.fromJson(Map<String, Object?>.from(item)))
        .toList();
    final network = (json['net'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => NetworkMetric.fromJson(Map<String, Object?>.from(item)))
        .toList();
    final gpus = (json['gpus'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => GpuMetric.fromJson(Map<String, Object?>.from(item)))
        .toList();
    return MetricSnapshot(
      timestamp: ts is num
          ? DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000)
          : DateTime.now(),
      cpu: CpuMetric(
        total: (cpu['total'] as num?)?.toDouble() ?? 0,
        cores: (cpu['cores'] as num?)?.toInt() ?? 0,
      ),
      memory: MemoryMetric(
        used: (memory['used'] as num?)?.toInt() ?? 0,
        total: (memory['total'] as num?)?.toInt() ?? 0,
      ),
      disks: disks,
      network: network,
      gpus: gpus,
      raw: json,
    );
  }
}

class CpuMetric {
  const CpuMetric({required this.total, required this.cores});
  final double total;
  final int cores;
}

class MemoryMetric {
  const MemoryMetric({required this.used, required this.total});
  final int used;
  final int total;
}

class DiskMetric {
  const DiskMetric({
    required this.name,
    required this.mount,
    required this.used,
    required this.total,
  });

  final String name;
  final String mount;
  final int used;
  final int total;

  factory DiskMetric.fromJson(Map<String, Object?> json) {
    return DiskMetric(
      name: json['name'] as String? ?? '',
      mount: json['mount'] as String? ?? '',
      used: (json['used'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class NetworkMetric {
  const NetworkMetric({
    required this.name,
    required this.rx,
    required this.tx,
  });

  final String name;
  final int rx;
  final int tx;

  factory NetworkMetric.fromJson(Map<String, Object?> json) {
    return NetworkMetric(
      name: json['name'] as String? ?? '',
      rx: (json['rx'] as num?)?.toInt() ?? 0,
      tx: (json['tx'] as num?)?.toInt() ?? 0,
    );
  }
}

class GpuMetric {
  const GpuMetric({
    required this.index,
    required this.name,
    required this.util,
    required this.memUsed,
    required this.memTotal,
  });

  final int index;
  final String name;
  final double util;
  final int memUsed;
  final int memTotal;

  factory GpuMetric.fromJson(Map<String, Object?> json) {
    return GpuMetric(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'GPU',
      util: (json['util'] as num?)?.toDouble() ?? 0,
      memUsed: (json['memUsed'] as num?)?.toInt() ?? 0,
      memTotal: (json['memTotal'] as num?)?.toInt() ?? 0,
    );
  }
}
