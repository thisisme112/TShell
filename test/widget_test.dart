import 'package:flutter_test/flutter_test.dart';

import 'package:tshell/src/models.dart';

void main() {
  test('MetricSnapshot.fromJson maps fields with defaults', () {
    final snapshot = MetricSnapshot.fromJson({
      'ts': 1700000000,
      'cpu': {'total': 33.5, 'cores': 8},
      'memory': {'used': 1024, 'total': 2048},
      'disks': [
        {'name': 'root', 'mount': '/', 'used': 12, 'total': 20},
      ],
      'net': [
        {'name': 'eth0', 'rx': 100, 'tx': 200},
      ],
      'gpus': [
        {'index': 0, 'name': 'A', 'util': 50, 'memUsed': 1, 'memTotal': 2},
      ],
    });

    expect(snapshot.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    expect(snapshot.cpu.total, 33.5);
    expect(snapshot.cpu.cores, 8);
    expect(snapshot.memory.used, 1024);
    expect(snapshot.memory.total, 2048);
    expect(snapshot.disks.single.mount, '/');
    expect(snapshot.network.single.tx, 200);
    expect(snapshot.gpus.single.name, 'A');
  });

  test('MetricSnapshot.fromJson falls back when fields are missing', () {
    final snapshot = MetricSnapshot.fromJson({});

    expect(snapshot.cpu.total, 0);
    expect(snapshot.cpu.cores, 0);
    expect(snapshot.memory.used, 0);
    expect(snapshot.memory.total, 0);
    expect(snapshot.disks, isEmpty);
    expect(snapshot.network, isEmpty);
    expect(snapshot.gpus, isEmpty);
  });
}
