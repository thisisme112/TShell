import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../app_controller.dart';
import 'tshell_app.dart';

final Map<ShortcutActivator, Intent> _terminalShortcuts = {
  const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
      CopySelectionTextIntent.copy,
  const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
      const PasteTextIntent(SelectionChangedCause.keyboard),
};

const _magazineTerminalTheme = TerminalTheme(
  cursor: AppPalette.acid,
  selection: Color(0x55b8956a),
  foreground: AppPalette.cream,
  background: AppPalette.ink,
  black: AppPalette.ink,
  red: AppPalette.magenta,
  green: AppPalette.mint,
  yellow: AppPalette.amber,
  blue: AppPalette.violet,
  magenta: AppPalette.orange,
  cyan: AppPalette.cyan,
  white: AppPalette.cream,
  brightBlack: AppPalette.muted,
  brightRed: AppPalette.danger,
  brightGreen: AppPalette.cyan,
  brightYellow: AppPalette.acid,
  brightBlue: AppPalette.violet,
  brightMagenta: AppPalette.orange,
  brightCyan: AppPalette.cyan,
  brightWhite: AppPalette.paperLight,
  searchHitBackground: AppPalette.acid,
  searchHitBackgroundCurrent: AppPalette.magenta,
  searchHitForeground: AppPalette.ink,
);

class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.activeSession;
    return Column(
      children: [
        _TabBar(controller: controller),
        Expanded(
          child: session == null
              ? const _NoSession()
              : _TerminalSurface(session: session),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.ink.withOpacity(0.54),
        border: const Border(
          top: BorderSide(color: AppPalette.line),
          bottom: BorderSide(color: AppPalette.line),
          left: BorderSide(color: AppPalette.magenta, width: 2),
        ),
      ),
      child: Row(
        children: [
          const ArtIconBadge(
            icon: Icons.terminal,
            size: 28,
            color: AppPalette.orange,
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MagazineKicker('SESSION INDEX'),
              SizedBox(height: 3),
              Text(
                'LIVE SHELLS',
                style: TextStyle(
                  color: AppPalette.paperLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Noto Serif SC',
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.sessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tab = controller.sessions[index];
                final selected = controller.selectedSession == index;
                return FilterChip(
                  selected: selected,
                  avatar: Icon(
                    iconForStatus(tab.terminal.status),
                    size: 16,
                  ),
                  label: Text(
                    tab.host.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  onSelected: (_) => controller.selectSession(index),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => controller.closeSession(tab),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalSurface extends StatelessWidget {
  const _TerminalSurface({required this.session});

  final SessionTab session;

  Future<void> _copySelection() async {
    final text = await session.terminal.copySelection();
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null) {
      session.terminal.paste(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Column(
        children: [
          Expanded(
            child: GlassPanel(
              borderRadius: BorderRadius.circular(8),
              tint: const Color(0xf217181a),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPalette.paper,
                            AppPalette.graphite,
                            AppPalette.ink,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const ArtIconBadge(
                            icon: Icons.bolt,
                            size: 28,
                            color: AppPalette.magenta,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MagazineKicker(
                                  'TERMINAL / LIVE SHELL',
                                  color: AppPalette.acid,
                                ),
                                Text(
                                  '${session.host.username}@${session.host.hostname}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppPalette.paperLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '复制选区',
                            onPressed: _copySelection,
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            tooltip: '粘贴',
                            onPressed: _pasteClipboard,
                            icon: const Icon(Icons.content_paste),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.cyan.withOpacity(0.12),
                              border: Border.all(color: AppPalette.cyan),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: AppPalette.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: TerminalView(
                      session.terminal.terminal,
                      controller: session.terminal.controller,
                      autofocus: true,
                      backgroundOpacity: 0.96,
                      shortcuts: _terminalShortcuts,
                      theme: _magazineTerminalTheme,
                      textStyle: const TerminalStyle(
                        fontFamily: 'Consolas',
                        fontSize: 14.5,
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      onSecondaryTapDown: (details, offset) async {
                        final text = await session.terminal.copySelection();
                        if (text != null && text.isNotEmpty) {
                          await Clipboard.setData(ClipboardData(text: text));
                        } else {
                          await _pasteClipboard();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSession extends StatelessWidget {
  const _NoSession();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: GlassPanel(
        padding: EdgeInsets.all(22),
        tint: Color(0xf217181a),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArtIconBadge(icon: Icons.terminal, color: AppPalette.graphite),
            SizedBox(height: 12),
            MagazineKicker('NO SESSION'),
            SizedBox(height: 6),
            Text('选择左侧主机并连接后，终端会显示在这里。'),
          ],
        ),
      ),
    );
  }
}
