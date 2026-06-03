import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../services/background_keep_alive.dart';
import 'workspace_page.dart';

class AppPalette {
  static const ink = Color(0xff101113);
  static const paper = Color(0xff17181a);
  static const graphite = Color(0xff202124);
  static const violet = Color(0xff7e9bc7);
  static const magenta = Color(0xffe45d42);
  static const cyan = Color(0xff62b7a8);
  static const acid = Color(0xffb8956a);
  static const orange = Color(0xffc47a5a);
  static const mint = Color(0xff7cb69a);
  static const line = Color(0xff3a3a3d);
  static const paperLight = Color(0xfff2eee6);
  static const paperDark = Color(0xff202124);
  static const cream = Color(0xffd8d1c6);
  static const muted = Color(0xff8f8a80);
  static const danger = Color(0xffd95b5b);
  static const amber = Color(0xffd8a64e);
}

class TShellApp extends StatefulWidget {
  const TShellApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<TShellApp> createState() => _TShellAppState();
}

class _TShellAppState extends State<TShellApp> {
  int _lastSessionCount = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncKeepAlive);
    _syncKeepAlive();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncKeepAlive);
    super.dispose();
  }

  void _syncKeepAlive() {
    final count = widget.controller.sessions.length;
    if (count == _lastSessionCount) {
      return;
    }
    _lastSessionCount = count;
    BackgroundKeepAlive.setActive(count > 0, count);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.acid,
      brightness: Brightness.dark,
      primary: AppPalette.acid,
      secondary: AppPalette.cyan,
      tertiary: AppPalette.magenta,
      surface: AppPalette.graphite,
    );
    return MaterialApp(
      title: 'TShell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppPalette.ink,
        fontFamily: 'DM Sans',
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            height: 1,
            color: AppPalette.paperLight,
            fontFamily: 'Noto Serif SC',
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppPalette.paperLight,
            fontFamily: 'Noto Serif SC',
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppPalette.paperLight,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.32,
            color: AppPalette.cream,
          ),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: AppPalette.paper,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppPalette.line),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppPalette.line,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppPalette.paperDark,
          selectedColor: AppPalette.acid.withOpacity(0.22),
          side: const BorderSide(color: AppPalette.line),
          labelStyle: const TextStyle(
            color: AppPalette.cream,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppPalette.cream,
            hoverColor: AppPalette.acid.withOpacity(0.12),
            focusColor: AppPalette.cyan.withOpacity(0.16),
            highlightColor: AppPalette.magenta.withOpacity(0.12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.ink.withOpacity(0.72),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppPalette.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppPalette.acid, width: 1.4),
          ),
          prefixIconColor: AppPalette.acid,
          hintStyle: const TextStyle(color: AppPalette.muted),
          labelStyle: const TextStyle(color: AppPalette.muted),
          isDense: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppPalette.acid,
          foregroundColor: AppPalette.ink,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppPalette.paper,
          indicatorColor: AppPalette.acid.withOpacity(0.24),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => WorkspacePage(controller: widget.controller),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.tint = const Color(0xf217181a),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint,
                Color.alphaBlend(
                  AppPalette.paperDark.withOpacity(0.42),
                  tint,
                ),
                Color.alphaBlend(
                  AppPalette.ink.withOpacity(0.28),
                  tint,
                ),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: AppPalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _EditorialPanelPainter()),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialPanelPainter extends CustomPainter {
  const _EditorialPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topRule = Paint()
      ..color = AppPalette.acid.withOpacity(0.24)
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), topRule);

    final accent = Paint()
      ..color = AppPalette.magenta.withOpacity(0.34)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), accent);

    final crop = Paint()
      ..color = AppPalette.paperLight.withOpacity(0.18)
      ..strokeWidth = 1;
    const length = 12.0;
    canvas.drawLine(const Offset(10, 10), const Offset(10 + length, 10), crop);
    canvas.drawLine(const Offset(10, 10), const Offset(10, 10 + length), crop);
    canvas.drawLine(
      Offset(size.width - 10, size.height - 10),
      Offset(size.width - 10 - length, size.height - 10),
      crop,
    );
    canvas.drawLine(
      Offset(size.width - 10, size.height - 10),
      Offset(size.width - 10, size.height - 10 - length),
      crop,
    );
  }

  @override
  bool shouldRepaint(covariant _EditorialPanelPainter oldDelegate) => false;
}

class ArtIconBadge extends StatelessWidget {
  const ArtIconBadge({
    super.key,
    required this.icon,
    this.size = 34,
    this.color = AppPalette.magenta,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? AppPalette.paperLight
            : AppPalette.ink;
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppPalette.line, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.56, color: foreground),
      ),
    );
  }
}

class MagazineKicker extends StatelessWidget {
  const MagazineKicker(this.text, {super.key, this.color = AppPalette.acid});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }
}

String formatBytes(num value) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = value.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String formatMiB(int value) => formatBytes(value * 1024 * 1024);

IconData iconForStatus(SessionStatus status) {
  switch (status) {
    case SessionStatus.connecting:
      return Icons.sync;
    case SessionStatus.connected:
      return Icons.check_circle;
    case SessionStatus.disconnected:
      return Icons.link_off;
    case SessionStatus.failed:
      return Icons.error;
  }
}

bool get isDesktopApp =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
