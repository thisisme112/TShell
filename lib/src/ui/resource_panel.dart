import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'tshell_app.dart';

class ResourcePanel extends StatefulWidget {
  const ResourcePanel({super.key, required this.session});

  final SessionTab? session;

  @override
  State<ResourcePanel> createState() => _ResourcePanelState();
}

class _ResourcePanelState extends State<ResourcePanel> {
  bool _cpuOpen = true;
  bool _memoryOpen = true;
  bool _diskOpen = false;
  bool _networkOpen = true;
  bool _gpuOpen = true;

  @override
  Widget build(BuildContext context) {
    final tab = widget.session;
    final metrics = tab?.latestMetrics;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ArtIconBadge(
                icon: Icons.monitor_heart_outlined,
                size: 30,
                color: AppPalette.acid,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MagazineKicker('SYSTEM DOSSIER'),
                    Text(
                      '资源查看器',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        color: AppPalette.paperLight,
                        fontFamily: 'Noto Serif SC',
                      ),
                    ),
                  ],
                ),
              ),
              if (tab != null)
                Tooltip(
                  message: tab.monitor.status,
                  child: const Icon(Icons.info_outline, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (tab == null)
            const Expanded(
              child: Center(
                child: GlassPanel(
                  padding: EdgeInsets.all(18),
                  child: Text('连接主机后显示资源占用。'),
                ),
              ),
            )
          else if (metrics == null)
            Expanded(child: Center(child: Text(tab.monitor.status)))
          else
            Expanded(
              child: ListView(
                children: [
                  _MetricSection(
                    title: 'CPU',
                    icon: Icons.memory,
                    open: _cpuOpen,
                    onChanged: (value) => setState(() => _cpuOpen = value),
                    summary: '${metrics.cpu.total.toStringAsFixed(1)}%',
                    children: [
                      _MetricCard(
                        title: '总占用',
                        icon: Icons.speed,
                        value: '${metrics.cpu.total.toStringAsFixed(1)}%',
                        subtitle: '${metrics.cpu.cores} 逻辑核心统一显示',
                        progress: metrics.cpu.total / 100,
                      ),
                    ],
                  ),
                  _MetricSection(
                    title: '内存',
                    icon: Icons.sd_storage,
                    open: _memoryOpen,
                    onChanged: (value) => setState(() => _memoryOpen = value),
                    summary:
                        _percentText(metrics.memory.used, metrics.memory.total),
                    children: [
                      _MetricCard(
                        title: '物理内存',
                        icon: Icons.data_usage,
                        value:
                            '${formatMiB(metrics.memory.used)} / ${formatMiB(metrics.memory.total)}',
                        subtitle: _percentText(
                            metrics.memory.used, metrics.memory.total),
                        progress:
                            _ratio(metrics.memory.used, metrics.memory.total),
                      ),
                    ],
                  ),
                  _MetricSection(
                    title: '硬盘',
                    icon: Icons.dns,
                    open: _diskOpen,
                    onChanged: (value) => setState(() => _diskOpen = value),
                    summary: metrics.disks.isEmpty
                        ? '无数据'
                        : '${metrics.disks.length} 个挂载点',
                    empty: metrics.disks.isEmpty,
                    children: metrics.disks
                        .map(
                          (disk) => _MetricCard(
                            title: disk.mount.isEmpty ? disk.name : disk.mount,
                            icon: Icons.album,
                            value:
                                '${formatMiB(disk.used)} / ${formatMiB(disk.total)}',
                            subtitle: disk.name,
                            progress: _ratio(disk.used, disk.total),
                          ),
                        )
                        .toList(),
                  ),
                  _MetricSection(
                    title: '网络',
                    icon: Icons.network_check,
                    open: _networkOpen,
                    onChanged: (value) => setState(() => _networkOpen = value),
                    summary: metrics.network.isEmpty
                        ? '无数据'
                        : '${metrics.network.length} 个接口',
                    empty: metrics.network.isEmpty,
                    children: metrics.network
                        .take(8)
                        .map(
                          (net) => _NetworkTile(
                            name: net.name,
                            rx: net.rx,
                            tx: net.tx,
                          ),
                        )
                        .toList(),
                  ),
                  _MetricSection(
                    title: 'GPU',
                    icon: Icons.developer_board,
                    open: _gpuOpen,
                    onChanged: (value) => setState(() => _gpuOpen = value),
                    summary: metrics.gpus.isEmpty
                        ? '无数据'
                        : '${metrics.gpus.length} 张卡',
                    empty: metrics.gpus.isEmpty,
                    children: metrics.gpus
                        .map(
                          (gpu) => _MetricCard(
                            title: '#${gpu.index} ${gpu.name}',
                            icon: Icons.view_in_ar,
                            value: '${gpu.util.toStringAsFixed(1)}%',
                            subtitle:
                                '显存 ${formatMiB(gpu.memUsed)} / ${formatMiB(gpu.memTotal)}',
                            progress: gpu.util / 100,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({
    required this.title,
    required this.icon,
    required this.open,
    required this.onChanged,
    required this.summary,
    required this.children,
    this.empty = false,
  });

  final String title;
  final IconData icon;
  final bool open;
  final ValueChanged<bool> onChanged;
  final String summary;
  final bool empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppPalette.magenta.withOpacity(0.20),
          highlightColor: AppPalette.cyan.withOpacity(0.16),
        ),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(8),
          tint: const Color(0xf2202124),
          child: ExpansionTile(
            initiallyExpanded: open,
            onExpansionChanged: onChanged,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            leading:
                ArtIconBadge(icon: icon, size: 26, color: AppPalette.paperDark),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPalette.paperLight,
                fontFamily: 'Noto Serif SC',
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: empty
                        ? Theme.of(context).colorScheme.outline
                        : AppPalette.acid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(open ? Icons.expand_less : Icons.expand_more, size: 20),
              ],
            ),
            children: children.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ]
                : children,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final IconData icon;
  final String value;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.paperDark, AppPalette.paper],
        ),
        border: Border.all(color: AppPalette.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _usageColor(progress).withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArtIconBadge(icon: icon, size: 24, color: _usageColor(progress)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.paperLight,
                    fontFamily: 'Noto Serif SC',
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.acid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _UsageProgress(value: progress),
          const SizedBox(height: 7),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({
    required this.name,
    required this.rx,
    required this.tx,
  });

  final String name;
  final int rx;
  final int tx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.paperDark, AppPalette.paper],
        ),
        border: Border.all(color: AppPalette.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const ArtIconBadge(
            icon: Icons.settings_ethernet,
            size: 24,
            color: AppPalette.graphite,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.paperLight,
                    fontFamily: 'Noto Serif SC',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RX ${formatBytes(rx)}/s   TX ${formatBytes(tx)}/s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageProgress extends StatelessWidget {
  const _UsageProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppPalette.paperDark.withOpacity(0.46),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clamped,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff2f6f63),
                    Color(0xff7cb69a),
                    Color(0xffb8956a),
                    Color(0xffe45d42),
                  ],
                  stops: [0, 0.5, 0.78, 1],
                ),
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: _usageColor(clamped).withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _ratio(int used, int total) {
  if (total <= 0) return 0;
  return used / total;
}

Color _usageColor(double value) {
  final v = value.clamp(0.0, 1.0);
  if (v < 0.5) {
    return Color.lerp(
      AppPalette.cyan,
      AppPalette.mint,
      v / 0.5,
    )!;
  }
  if (v < 0.78) {
    return Color.lerp(
      AppPalette.mint,
      AppPalette.acid,
      (v - 0.5) / 0.28,
    )!;
  }
  return Color.lerp(
    AppPalette.acid,
    AppPalette.magenta,
    (v - 0.78) / 0.22,
  )!;
}

String _percentText(int used, int total) {
  if (total <= 0) return '0%';
  return '${(used / total * 100).toStringAsFixed(1)}%';
}
