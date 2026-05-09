import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import 'tshell_app.dart';

class FilePanel extends StatefulWidget {
  const FilePanel({super.key, required this.controller});

  final AppController controller;

  @override
  State<FilePanel> createState() => _FilePanelState();
}

class _FileNode {
  _FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.entry,
    this.depth = 0,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final RemoteFileEntry? entry;
  final int depth;
  bool expanded = false;
  bool loading = false;
  bool loaded = false;
  List<_FileNode> children = [];
}

class _FilePanelState extends State<FilePanel> {
  final _pathController = TextEditingController(text: '.');
  final Map<String, _FileNode> _nodes = {};
  final Set<String> _expanded = {};
  final List<_TransferItem> _transfers = [];

  Offset _transferOffset = const Offset(16, 16);
  String _currentPath = '.';
  String? _loadedSessionId;
  String? _clipboardPath;
  bool _clipboardMove = false;
  bool _bootstrapping = false;
  bool _transfersMinimized = false;

  SessionTab? get _session => widget.controller.activeSession;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      _loadedSessionId = null;
      return const Center(child: Text('未连接会话，文件管理不可用。'));
    }
    _ensureSessionLoaded(session);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              const ArtIconBadge(
                icon: Icons.account_tree,
                size: 30,
                color: AppPalette.acid,
              ),
              const SizedBox(width: 10),
              const MagazineKicker('REMOTE FILES'),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    hintText: '输入路径并回车',
                    isDense: true,
                  ),
                  onSubmitted: _openPathFromInput,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '打开路径',
                onPressed: () => _openPathFromInput(_pathController.text),
                icon: const Icon(Icons.subdirectory_arrow_right),
              ),
              IconButton(
                tooltip: '上级',
                onPressed: _goUp,
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: '刷新当前目录',
                onPressed: _refreshCurrent,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: '上传到当前目录',
                onPressed: () async {
                  await _uploadPicked();
                },
                icon: const Icon(Icons.upload_file),
              ),
              IconButton(
                tooltip: '粘贴到当前目录',
                onPressed: _clipboardPath == null ? null : _paste,
                icon: const Icon(Icons.content_paste),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                _bootstrapping
                    ? const Center(child: CircularProgressIndicator())
                    : _visibleNodes().isEmpty
                        ? const Center(child: Text('没有可显示的路径。'))
                        : ListView.builder(
                            itemCount: _visibleNodes().length,
                            itemBuilder: (context, index) {
                              final node = _visibleNodes()[index];
                              return _FileNodeTile(
                                node: node,
                                selected: node.path == _currentPath,
                                onToggle: node.isDirectory
                                    ? () => _toggleDirectory(node)
                                    : null,
                                onSelect: () => _selectNode(node),
                                onOpen: () => _openNode(node),
                                onAction: (action) => _fileAction(action, node),
                              );
                            },
                          ),
                Positioned(
                  left: _transferOffset.dx,
                  top: _transferOffset.dy,
                  child: _TransferPopup(
                    transfers: _transfers,
                    minimized: _transfersMinimized,
                    onToggleMinimized: () => setState(() {
                      _transfersMinimized = !_transfersMinimized;
                    }),
                    onDrag: (delta) => setState(() {
                      final size = MediaQuery.sizeOf(context);
                      _transferOffset = Offset(
                        (_transferOffset.dx + delta.dx)
                            .clamp(0, size.width - 380),
                        (_transferOffset.dy + delta.dy)
                            .clamp(0, size.height - 180),
                      );
                    }),
                    onDismiss: (item) {
                      setState(() => _transfers.remove(item));
                    },
                    onClear: () {
                      setState(() {
                        _transfers.removeWhere((item) => item.completed);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPicked() async {
    final session = _session;
    if (session == null) return;
    final item = _addTransfer('上传', _currentPath);
    try {
      final remotePath = await session.files.uploadPicked(
        _currentPath,
        onProgress: (done, total) => _updateTransfer(item, done, total),
      );
      if (remotePath == null) {
        _removeTransfer(item);
        return;
      }
      _finishTransfer(item, '上传完成');
      await _refreshCurrent();
    } catch (err) {
      _failTransfer(item, '上传失败: $err');
    }
  }

  void _ensureSessionLoaded(SessionTab session) {
    if (_loadedSessionId == session.id) return;
    _loadedSessionId = session.id;
    _nodes.clear();
    _expanded.clear();
    _clipboardPath = null;
    _currentPath = '.';
    _setInputText('.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session?.id == session.id) {
        _bootstrapTree();
      }
    });
  }

  Future<void> _bootstrapTree() async {
    final session = _session;
    if (session == null) return;
    setState(() => _bootstrapping = true);
    try {
      final home = await session.files.homePath();
      final roots = <_FileNode>[
        _FileNode(path: '/', name: '/', isDirectory: true),
      ];
      if (home != '/' && home.trim().isNotEmpty) {
        roots.add(_FileNode(path: home, name: home, isDirectory: true));
      }
      _nodes
        ..clear()
        ..addEntries(roots.map((node) => MapEntry(node.path, node)));
      _expanded.clear();
      final homeNode = _nodes[home] ?? _nodes['/'];
      if (homeNode != null) {
        _currentPath = homeNode.path;
        _setInputText(homeNode.path);
        await _loadDirectory(homeNode, expand: true);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化文件树失败: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  List<_FileNode> _visibleNodes() {
    final roots = _nodes.values.where((node) => node.depth == 0).toList()
      ..sort((a, b) {
        if (a.path == '/') return -1;
        if (b.path == '/') return 1;
        return a.path.compareTo(b.path);
      });
    final result = <_FileNode>[];
    for (final root in roots) {
      _appendVisible(root, result);
    }
    return result;
  }

  void _appendVisible(_FileNode node, List<_FileNode> result) {
    result.add(node);
    if (!node.expanded) return;
    for (final child in node.children) {
      _appendVisible(child, result);
    }
  }

  Future<void> _toggleDirectory(_FileNode node) async {
    if (!node.isDirectory) return;
    if (node.expanded) {
      setState(() {
        node.expanded = false;
        _expanded.remove(node.path);
      });
      return;
    }
    await _loadDirectory(node, expand: true);
  }

  Future<void> _loadDirectory(_FileNode node, {required bool expand}) async {
    final session = _session;
    if (session == null || !node.isDirectory) return;
    setState(() => node.loading = true);
    try {
      final entries = await session.files.list(node.path);
      final children = entries
          .map(
            (entry) => _FileNode(
              path: entry.path,
              name: entry.name,
              isDirectory: entry.isDirectory,
              entry: entry,
              depth: node.depth + 1,
            ),
          )
          .toList();
      setState(() {
        node.children = children;
        node.loaded = true;
        node.expanded = expand;
        if (expand) _expanded.add(node.path);
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取目录失败: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => node.loading = false);
    }
  }

  Future<void> _openPathFromInput(String value) async {
    final path = value.trim();
    if (path.isEmpty) return;
    _currentPath = path;
    final node = _nodes[path] ??
        _FileNode(path: path, name: path, isDirectory: true, depth: 0);
    _nodes[path] = node;
    await _loadDirectory(node, expand: true);
  }

  void _selectNode(_FileNode node) {
    setState(() {
      _currentPath = node.path;
      _setInputText(node.path);
    });
    if (node.isDirectory && !node.loaded) {
      _loadDirectory(node, expand: true);
    }
  }

  void _openNode(_FileNode node) {
    if (node.isDirectory) {
      _toggleDirectory(node);
      return;
    }
    _fileAction('edit', node);
  }

  Future<void> _refreshCurrent() async {
    final node = _nodes[_currentPath] ??
        _FileNode(path: _currentPath, name: _currentPath, isDirectory: true);
    _nodes[_currentPath] = node;
    await _loadDirectory(node, expand: true);
  }

  void _goUp() {
    final parent = _parentPath(_currentPath);
    if (parent == null) return;
    _currentPath = parent;
    _setInputText(parent);
    _openPathFromInput(parent);
  }

  Future<void> _fileAction(String action, _FileNode node) async {
    final session = _session;
    final entry = node.entry;
    if (session == null) return;
    try {
      switch (action) {
        case 'download':
          if (entry != null) {
            final item = _addTransfer('下载', entry.name);
            try {
              await session.files.download(
                entry.path,
                onProgress: (done, total) => _updateTransfer(item, done, total),
              );
              _finishTransfer(item, '下载完成');
            } catch (err) {
              _failTransfer(item, '下载失败: $err');
            }
          }
          break;
        case 'edit':
          if (entry != null) _editFile(session, entry);
          break;
        case 'copy':
          setState(() {
            _clipboardPath = node.path;
            _clipboardMove = false;
          });
          break;
        case 'move':
          setState(() {
            _clipboardPath = node.path;
            _clipboardMove = true;
          });
          break;
        case 'rename':
          final target = await _askPath('重命名', node.path);
          if (target != null) await session.files.move(node.path, target);
          await _refreshCurrent();
          break;
        case 'delete':
          if (entry != null) await session.files.delete(entry);
          await _refreshCurrent();
          break;
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $err')),
        );
      }
    }
  }

  void _editFile(SessionTab session, RemoteFileEntry entry) {
    final item = _addTransfer('编辑', entry.name);
    item.status = '准备下载';
    unawaitedEdit() async {
      try {
        await session.files.editWithSystemApp(
          entry.path,
          onDownloadProgress: (done, total) =>
              _updateTransfer(item, done, total, phase: '下载'),
          onUploadProgress: (done, total) =>
              _updateTransfer(item, done, total, phase: '上传'),
          onStatus: (status) => _setTransferStatus(item, status),
        );
        _finishTransfer(item, item.status == '监听结束' ? '监听结束' : '编辑同步完成');
        await _refreshCurrent();
      } catch (err) {
        _failTransfer(item, '编辑失败: $err');
      }
    }

    unawaitedEdit();
  }

  Future<void> _paste() async {
    final session = _session;
    final source = _clipboardPath;
    if (session == null || source == null) return;
    final name = source.replaceAll('\\', '/').split('/').last;
    final target = _joinRemote(_currentPath, name);
    if (_clipboardMove) {
      await session.files.move(source, target);
    } else {
      final item = _addTransfer('复制', target);
      try {
        await session.files.copyFile(source, target);
        _finishTransfer(item, '复制完成');
      } catch (err) {
        _failTransfer(item, '复制失败: $err');
      }
    }
    setState(() => _clipboardPath = null);
    await _refreshCurrent();
  }

  Future<String?> _askPath(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '目标路径'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _setInputText(String text) {
    _pathController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _joinRemote(String directory, String name) {
    if (directory.endsWith('/')) return '$directory$name';
    if (directory.contains('\\')) return '$directory\\$name';
    return '$directory/$name';
  }

  String? _parentPath(String path) {
    if (path == '.' || path == '/' || path.length <= 1) return null;
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  _TransferItem _addTransfer(String kind, String label) {
    final item = _TransferItem(kind: kind, label: label);
    setState(() => _transfers.insert(0, item));
    return item;
  }

  void _updateTransfer(
    _TransferItem item,
    int done,
    int total, {
    String? phase,
  }) {
    if (!mounted) return;
    setState(() {
      item.done = done;
      item.total = total;
      if (phase != null) item.kind = phase;
      item.status = total > 0
          ? '${formatBytes(done)} / ${formatBytes(total)}'
          : formatBytes(done);
    });
  }

  void _setTransferStatus(_TransferItem item, String status) {
    if (!mounted) return;
    setState(() => item.status = status);
  }

  void _finishTransfer(_TransferItem item, String status) {
    if (!mounted) return;
    setState(() {
      item.done = item.total;
      item.status = status;
      item.completed = true;
    });
  }

  void _failTransfer(_TransferItem item, String status) {
    if (!mounted) return;
    setState(() {
      item.status = status;
      item.failed = true;
      item.completed = true;
    });
  }

  void _removeTransfer(_TransferItem item) {
    if (!mounted) return;
    setState(() => _transfers.remove(item));
  }
}

class _TransferItem {
  _TransferItem({required this.kind, required this.label});

  String kind;
  final String label;
  String status = '准备中';
  int done = 0;
  int total = 0;
  bool completed = false;
  bool failed = false;

  double? get progress => total <= 0 ? null : (done / total).clamp(0, 1);
}

class _FileNodeTile extends StatelessWidget {
  const _FileNodeTile({
    required this.node,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
    required this.onToggle,
    required this.onAction,
  });

  final _FileNode node;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final VoidCallback? onToggle;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onOpen,
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: selected ? AppPalette.magenta.withOpacity(0.16) : null,
          border: Border(
            left: BorderSide(
              color: selected ? AppPalette.acid : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        padding: EdgeInsets.only(left: 8.0 + node.depth * 18, right: 4),
        height: 38,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: node.isDirectory
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: node.expanded ? '收起' : '展开',
                      onPressed: onToggle,
                      icon: node.loading
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              node.expanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              size: 20,
                            ),
                    )
                  : const SizedBox.shrink(),
            ),
            Icon(
              node.isDirectory ? Icons.folder : Icons.insert_drive_file,
              size: 18,
              color: node.isDirectory
                  ? AppPalette.acid
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppPalette.paperLight : null,
                ),
              ),
            ),
            if (node.entry != null && !node.isDirectory)
              Text(
                formatBytes(node.entry!.size),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            IconButton(
              tooltip: '更多',
              onPressed: () {
                final box = context.findRenderObject() as RenderBox;
                final offset = box.localToGlobal(Offset.zero);
                _showContextMenu(context, offset + Offset(box.size.width, 0));
              },
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (!node.isDirectory)
          const PopupMenuItem(value: 'download', child: Text('下载')),
        if (!node.isDirectory && isDesktopApp)
          const PopupMenuItem(value: 'edit', child: Text('打开编辑')),
        const PopupMenuItem(value: 'copy', child: Text('复制')),
        const PopupMenuItem(value: 'move', child: Text('移动')),
        const PopupMenuItem(value: 'rename', child: Text('重命名')),
        if (node.entry != null)
          const PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
    if (action != null) onAction(action);
  }
}

class _TransferPopup extends StatelessWidget {
  const _TransferPopup({
    required this.transfers,
    required this.minimized,
    required this.onToggleMinimized,
    required this.onDrag,
    required this.onDismiss,
    required this.onClear,
  });

  final List<_TransferItem> transfers;
  final bool minimized;
  final VoidCallback onToggleMinimized;
  final ValueChanged<Offset> onDrag;
  final ValueChanged<_TransferItem> onDismiss;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) return const SizedBox.shrink();
    return Material(
      elevation: 0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(8),
        tint: const Color(0xf217181a),
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: minimized ? 210 : 340,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: minimized ? 46 : 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) => onDrag(details.delta),
                  child: Row(
                    children: [
                      const ArtIconBadge(
                        icon: Icons.sync_alt,
                        size: 24,
                        color: AppPalette.acid,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          minimized ? '传输任务 (${transfers.length})' : '传输任务',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.paperLight,
                            fontFamily: 'Noto Serif SC',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: minimized ? '展开' : '最小化',
                        visualDensity: VisualDensity.compact,
                        onPressed: onToggleMinimized,
                        icon: Icon(
                          minimized ? Icons.open_in_full : Icons.remove,
                          size: 16,
                        ),
                      ),
                      if (!minimized)
                        IconButton(
                          tooltip: '清空已完成任务',
                          visualDensity: VisualDensity.compact,
                          onPressed: onClear,
                          icon: const Icon(Icons.clear_all, size: 16),
                        ),
                    ],
                  ),
                ),
                if (!minimized) ...[
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: transfers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = transfers[index];
                        return _TransferRow(
                          item: item,
                          onDismiss: () => onDismiss(item),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.item,
    required this.onDismiss,
  });

  final _TransferItem item;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.paperDark, AppPalette.paper],
        ),
        border: Border.all(color: AppPalette.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            item.failed
                ? Icons.error
                : item.completed
                    ? Icons.check_circle
                    : Icons.downloading,
            size: 18,
            color: item.failed
                ? AppPalette.magenta
                : item.completed
                    ? AppPalette.mint
                    : AppPalette.cyan,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.kind}  ${item.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: item.progress),
                const SizedBox(height: 4),
                Text(
                  item.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: item.completed ? '关闭任务' : '从列表移除',
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}
