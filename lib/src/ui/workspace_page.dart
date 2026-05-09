import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'file_panel.dart';
import 'host_panel.dart';
import 'resource_panel.dart';
import 'terminal_panel.dart';
import 'tshell_app.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  bool _mobileMetricsOpen = false;
  bool _hostsCollapsed = false;
  bool _resourcesCollapsed = false;
  bool _filesCollapsed = false;
  double _hostWidth = 310;
  double _resourceWidth = 320;
  double _fileHeight = 250;
  int _mobileTab = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: _GlassBackdrop(
        child: SafeArea(
          child: wide ? _wideLayout() : _mobileLayout(),
        ),
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.small(
              onPressed: () => setState(() {
                _mobileMetricsOpen = !_mobileMetricsOpen;
              }),
              tooltip: '资源',
              child: const Icon(Icons.monitor_heart_outlined),
            ),
    );
  }

  Widget _wideLayout() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: _hostsCollapsed ? 54 : _hostWidth,
            child: _hostsCollapsed
                ? _CollapsedRail(
                    tooltip: '展开主机',
                    icon: Icons.dns,
                    onPressed: () => setState(() => _hostsCollapsed = false),
                  )
                : _PanelShell(
                    edge: _PanelEdge.left,
                    onCollapse: () => setState(() => _hostsCollapsed = true),
                    child: HostPanel(controller: widget.controller),
                  ),
          ),
          _DesignedDivider(
            onDrag: _hostsCollapsed
                ? null
                : (delta) => setState(() {
                      _hostWidth = (_hostWidth + delta).clamp(240, 520);
                    }),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: TerminalPanel(controller: widget.controller)),
                _HorizontalGrip(
                  collapsed: _filesCollapsed,
                  onPressed: () => setState(() {
                    _filesCollapsed = !_filesCollapsed;
                  }),
                  onDrag: _filesCollapsed
                      ? null
                      : (delta) => setState(() {
                            _fileHeight = (_fileHeight - delta).clamp(160, 460);
                          }),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: _filesCollapsed ? 0 : _fileHeight,
                  child: ClipRect(
                    child: GlassPanel(
                      borderRadius: BorderRadius.circular(8),
                      tint: const Color(0xf217181a),
                      child: FilePanel(controller: widget.controller),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _DesignedDivider(
            onDrag: _resourcesCollapsed
                ? null
                : (delta) => setState(() {
                      _resourceWidth = (_resourceWidth - delta).clamp(260, 520);
                    }),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: _resourcesCollapsed ? 54 : _resourceWidth,
            child: _resourcesCollapsed
                ? _CollapsedRail(
                    tooltip: '展开资源',
                    icon: Icons.monitor_heart,
                    onPressed: () =>
                        setState(() => _resourcesCollapsed = false),
                  )
                : _PanelShell(
                    edge: _PanelEdge.right,
                    onCollapse: () =>
                        setState(() => _resourcesCollapsed = true),
                    child:
                        ResourcePanel(session: widget.controller.activeSession),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() {
    final pages = [
      HostPanel(controller: widget.controller),
      TerminalPanel(controller: widget.controller),
      FilePanel(controller: widget.controller),
    ];
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: pages[_mobileTab]),
            NavigationBar(
              selectedIndex: _mobileTab,
              onDestinationSelected: (value) => setState(() {
                _mobileTab = value;
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dns),
                  label: '主机',
                ),
                NavigationDestination(
                  icon: Icon(Icons.terminal),
                  label: '终端',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder),
                  label: '文件',
                ),
              ],
            ),
          ],
        ),
        if (_mobileMetricsOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _mobileMetricsOpen = false),
              child: ColoredBox(
                color: Colors.black.withOpacity(0.68),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: AppPalette.paper,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.62,
                      child: ResourcePanel(
                        session: widget.controller.activeSession,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _PanelEdge { left, right }

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.edge,
    required this.onCollapse,
    required this.child,
  });

  final _PanelEdge edge;
  final VoidCallback onCollapse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GlassPanel(
            borderRadius: BorderRadius.circular(8),
            tint: const Color(0xf217181a),
            child: child,
          ),
        ),
        Positioned(
          top: 8,
          right: edge == _PanelEdge.left ? 6 : null,
          left: edge == _PanelEdge.right ? 6 : null,
          child: IconButton.filledTonal(
            tooltip: edge == _PanelEdge.left ? '收起主机' : '收起资源',
            style: IconButton.styleFrom(
              minimumSize: const Size.square(32),
              fixedSize: const Size.square(32),
              padding: EdgeInsets.zero,
              backgroundColor: AppPalette.magenta,
              foregroundColor: AppPalette.paperLight,
            ),
            onPressed: onCollapse,
            icon: Icon(
              edge == _PanelEdge.left
                  ? Icons.keyboard_double_arrow_left
                  : Icons.keyboard_double_arrow_right,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(8),
      tint: const Color(0xf217181a),
      child: Center(
        child: IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({required this.child});

  final Widget child;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MagazineBackdropPainter(_controller.value),
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff0c0c0e),
              Color(0xff17181a),
              Color(0xff101113),
              Color(0xff202124),
            ],
            stops: [0, 0.38, 0.72, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.paperLight.withOpacity(0.025),
                      Colors.transparent,
                      AppPalette.magenta.withOpacity(0.045),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _MagazineBackdropPainter extends CustomPainter {
  _MagazineBackdropPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final t = progress * math.pi * 2;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 420; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.018 + random.nextDouble() * 0.035;
      dotPaint.color = AppPalette.paperLight.withOpacity(opacity);
      canvas.drawCircle(
          Offset(x, y), 0.35 + random.nextDouble() * 0.7, dotPaint);
    }

    final fiberPaint = Paint()
      ..color = AppPalette.cream.withOpacity(0.045)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 34; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = 34 + random.nextDouble() * 94;
      final drift = math.sin(t + i) * 2.5;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + length, y + drift + random.nextDouble() * 10 - 5),
        fiberPaint,
      );
    }

    final creasePaint = Paint()
      ..color = AppPalette.paperLight.withOpacity(0.025)
      ..strokeWidth = 1;
    for (var y = 48.0; y < size.height; y += 128) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + math.sin(y) * 5), creasePaint);
    }

    final rulePaint = Paint()
      ..color = AppPalette.line.withOpacity(0.34)
      ..strokeWidth = 1;
    final column = size.width / 12;
    for (var i = 1; i < 12; i++) {
      if (i % 3 == 0) {
        canvas.drawLine(
            Offset(column * i, 0), Offset(column * i, size.height), rulePaint);
      }
    }

    final marginPaint = Paint()
      ..color = AppPalette.magenta.withOpacity(0.24)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.045, size.height * 0.08),
      Offset(size.width * 0.045, size.height * 0.92),
      marginPaint,
    );

    final ghostTitle = TextPainter(
      text: TextSpan(
        text: 'TSHELL',
        style: TextStyle(
          color: AppPalette.paperLight.withOpacity(0.035),
          fontFamily: 'Noto Serif SC',
          fontSize: math.min(160, size.width * 0.16),
          fontWeight: FontWeight.w800,
          height: 0.9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ghostTitle.paint(
      canvas,
      Offset(size.width * 0.08, size.height - ghostTitle.height - 22),
    );

    final issueText = TextPainter(
      text: TextSpan(
        text: 'REMOTE\\nTERMINAL\\nJOURNAL',
        style: TextStyle(
          color: AppPalette.acid.withOpacity(0.10),
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    issueText.paint(canvas, Offset(size.width - issueText.width - 30, 28));

    final scanPaint = Paint()
      ..color = AppPalette.acid.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final brushY = size.height * 0.18 + progress * size.height * 0.78;
    final brush = Path()
      ..moveTo(size.width * 0.08, brushY)
      ..cubicTo(
        size.width * 0.28,
        brushY - 18,
        size.width * 0.54,
        brushY + 12,
        size.width * 0.92,
        brushY - 22,
      );
    canvas.drawPath(brush, scanPaint);

    for (var i = 0; i < 12; i++) {
      dotPaint.color =
          (i.isEven ? AppPalette.magenta : AppPalette.cyan).withOpacity(0.055);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        1.2 + random.nextDouble() * 2.4,
        dotPaint,
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppPalette.ink.withOpacity(0.68),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.42),
          radius: math.max(size.width, size.height) * 0.72,
        ),
      );
    canvas.drawRect(Offset.zero & size, vignette);

    final deckPaint = Paint()
      ..color = AppPalette.magenta.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final deckRect = Rect.fromLTWH(
      size.width - 142 + math.sin(t) * 3,
      size.height - 112,
      82,
      52,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deckRect, const Radius.circular(8)),
      deckPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MagazineBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DesignedDivider extends StatelessWidget {
  const _DesignedDivider({this.onDrag});

  final ValueChanged<double>? onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onDrag == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate:
            onDrag == null ? null : (details) => onDrag!(details.delta.dx),
        child: Container(
          width: 10,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.paperDark,
                AppPalette.graphite,
                AppPalette.paperDark,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 3,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppPalette.paperLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalGrip extends StatelessWidget {
  const _HorizontalGrip({
    required this.collapsed,
    required this.onPressed,
    required this.onDrag,
  });

  final bool collapsed;
  final VoidCallback onPressed;
  final ValueChanged<double>? onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          collapsed ? SystemMouseCursors.click : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        onVerticalDragUpdate:
            onDrag == null ? null : (details) => onDrag!(details.delta.dy),
        child: Container(
          height: 14,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppPalette.paperDark,
                AppPalette.graphite,
                AppPalette.paperDark,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 3,
              decoration: BoxDecoration(
                color: collapsed ? AppPalette.magenta : AppPalette.paperLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
