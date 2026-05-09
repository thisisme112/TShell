import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../models.dart';
import 'ssh_connection_service.dart';

class MonitorAgentService {
  MonitorAgentService(this.connection);

  final SshConnection connection;
  SSHSession? _session;
  StreamSubscription<String>? _stdout;
  StreamSubscription<String>? _stderr;
  final _controller = StreamController<MetricSnapshot>.broadcast();

  Stream<MetricSnapshot> get snapshots => _controller.stream;
  String status = '未启动';

  Future<void> start() async {
    await stop();
    status = '检测远程系统';
    final probe = await connection.runCommand(
      'uname -s 2>/dev/null || powershell -NoProfile -Command "[System.Environment]::OSVersion.Platform"',
    );
    final isWindows = probe.toLowerCase().contains('win');
    status = '启动监控';
    final command = isWindows ? _windowsScript : _linuxScript;
    _session = await connection.client.execute(command);
    _stdout = _session!.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(_handleLine, onError: _handleError);
    _stderr = _session!.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen((text) {
      if (text.trim().isNotEmpty) {
        status = text.trim();
      }
    });
    status = '运行中';
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    try {
      final json = jsonDecode(line) as Map<String, Object?>;
      if (json['type'] == 'metrics') {
        _controller.add(MetricSnapshot.fromJson(json));
      }
    } catch (err) {
      status = '监控解析失败: $err';
    }
  }

  void _handleError(Object err) {
    status = '监控不可用: $err';
  }

  Future<void> stop() async {
    await _stdout?.cancel();
    await _stderr?.cancel();
    _session?.write(Uint8List.fromList([3]));
    _session?.close();
    _session = null;
    status = '已停止';
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

const _linuxScript = r'''
sh -lc '
prev_total=0; prev_idle=0
while true; do
  cpu_line=$(grep "^cpu " /proc/stat)
  set -- $cpu_line
  user=$2; nice=$3; system=$4; idle=$5; iowait=$6; irq=$7; softirq=$8; steal=$9
  total=$((user+nice+system+idle+iowait+irq+softirq+steal))
  idle_all=$((idle+iowait))
  diff_total=$((total-prev_total))
  diff_idle=$((idle_all-prev_idle))
  if [ "$diff_total" -gt 0 ]; then cpu=$((100*(diff_total-diff_idle)/diff_total)); else cpu=0; fi
  prev_total=$total; prev_idle=$idle_all
  cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 0)
  mem_total=$(awk "/MemTotal/ {print int(\$2/1024)}" /proc/meminfo)
  mem_avail=$(awk "/MemAvailable/ {print int(\$2/1024)}" /proc/meminfo)
  mem_used=$((mem_total-mem_avail))
  disks=$(df -BM -x tmpfs -x devtmpfs 2>/dev/null | awk "NR>1 {gsub(/M/,\"\",\$2); gsub(/M/,\"\",\$3); printf \"%s{\\\"name\\\":\\\"%s\\\",\\\"mount\\\":\\\"%s\\\",\\\"used\\\":%s,\\\"total\\\":%s}\", sep, \$1, \$6, \$3, \$2; sep=\",\"}")
  net=$(awk "NR>2 {gsub(\":\",\"\",\$1); printf \"%s{\\\"name\\\":\\\"%s\\\",\\\"rx\\\":%s,\\\"tx\\\":%s}\", sep, \$1, \$2, \$10; sep=\",\"}" /proc/net/dev)
  gpus=""
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpus=$(nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F, "{gsub(/^ /,\"\",\$2); printf \"%s{\\\"index\\\":%s,\\\"name\\\":\\\"%s\\\",\\\"util\\\":%s,\\\"memUsed\\\":%s,\\\"memTotal\\\":%s}\", sep, \$1, \$2, \$3, \$4, \$5; sep=\",\"}")
  fi
  ts=$(date +%s)
  printf "{\"type\":\"metrics\",\"ts\":%s,\"cpu\":{\"total\":%s,\"cores\":%s},\"memory\":{\"used\":%s,\"total\":%s},\"disks\":[%s],\"net\":[%s],\"gpus\":[%s]}\n" "$ts" "$cpu" "$cores" "$mem_used" "$mem_total" "$disks" "$net" "$gpus"
  sleep 2
done'
''';

const _windowsScript = r'''
powershell -NoProfile -ExecutionPolicy Bypass -Command "while ($true) {
  $cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 1)
  $cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
  $os = Get-CimInstance Win32_OperatingSystem
  $memTotal = [int](($os.TotalVisibleMemorySize) / 1024)
  $memUsed = [int](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024)
  $disks = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { @{ name=$_.DeviceID; mount=$_.DeviceID; used=[int](($_.Size-$_.FreeSpace)/1MB); total=[int]($_.Size/1MB) } })
  $net = @(Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.Name -notmatch 'Loopback' } | ForEach-Object { @{ name=$_.Name; rx=[int64]$_.BytesReceivedPersec; tx=[int64]$_.BytesSentPersec } })
  $gpus = @()
  $smi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
  if ($smi) {
    $rows = & $smi.Source --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>$null
    foreach ($row in $rows) {
      $p = $row -split ','
      if ($p.Count -ge 5) { $gpus += @{ index=[int]$p[0].Trim(); name=$p[1].Trim(); util=[double]$p[2].Trim(); memUsed=[int]$p[3].Trim(); memTotal=[int]$p[4].Trim() } }
    }
  }
  @{ type='metrics'; ts=[int][double]::Parse((Get-Date -UFormat %s)); cpu=@{total=$cpu; cores=$cores}; memory=@{used=$memUsed; total=$memTotal}; disks=$disks; net=$net; gpus=$gpus } | ConvertTo-Json -Compress -Depth 5
  Start-Sleep -Seconds 2
}"
''';
