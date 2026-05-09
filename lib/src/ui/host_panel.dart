import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import 'tshell_app.dart';

class HostPanel extends StatelessWidget {
  const HostPanel({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverMasthead(onAdd: () => _showHostDialog(context)),
          const SizedBox(height: 12),
          TextField(
            onChanged: controller.setSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索主机、标签、用户名',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: controller.filteredHosts.isEmpty
                ? const _EmptyHosts()
                : ListView.separated(
                    itemCount: controller.filteredHosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final host = controller.filteredHosts[index];
                      return _HostTile(
                        host: host,
                        onConnect: () => _connect(context, host),
                        onEdit: () => _showHostDialog(context, host: host),
                        onDelete: () => _delete(context, host),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final json = await controller.exportJson();
              if (context.mounted) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('导出配置'),
                    content: SizedBox(
                      width: 560,
                      child: SelectableText(json),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('导出非敏感配置'),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.acid,
              foregroundColor: AppPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context, HostProfile host) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.connect(host);
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('连接失败: $err')));
    }
  }

  Future<void> _delete(BuildContext context, HostProfile host) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 ${host.name}?'),
        content: const Text('主机配置和系统安全存储里的凭据都会删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteHost(host);
    }
  }

  Future<void> _showHostDialog(BuildContext context, {HostProfile? host}) {
    return showDialog<void>(
      context: context,
      builder: (context) => HostEditorDialog(
        controller: controller,
        host: host,
      ),
    );
  }
}

class _CoverMasthead extends StatelessWidget {
  const _CoverMasthead({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(8),
      tint: const Color(0xcc101113),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const MagazineKicker('REMOTE DISPATCH / ISSUE 05'),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.magenta),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SSH',
                    style: TextStyle(
                      color: AppPalette.magenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ArtIconBadge(icon: Icons.hub, color: AppPalette.acid),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'TSHELL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 42,
                      height: 0.9,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.paperLight,
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: '添加主机',
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.acid,
                    foregroundColor: AppPalette.ink,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: Divider(color: AppPalette.line, height: 1),
                ),
                SizedBox(width: 8),
                Text(
                  'TERMINAL JOURNAL',
                  style: TextStyle(
                    color: AppPalette.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HostTile extends StatelessWidget {
  const _HostTile({
    required this.host,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  final HostProfile host;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(8),
      tint: const Color(0xf2202124),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArtIconBadge(
                  icon: host.authType == AuthType.privateKey
                      ? Icons.key
                      : Icons.password,
                  size: 26,
                  color: AppPalette.paperDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    host.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppPalette.paperLight,
                      fontFamily: 'Noto Serif SC',
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '连接',
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.magenta,
                    foregroundColor: AppPalette.paperLight,
                  ),
                  onPressed: onConnect,
                  icon: const Icon(Icons.bolt),
                ),
                PopupMenuButton<String>(
                  tooltip: '更多',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
            Text(
              '${host.username}@${host.hostname}:${host.port}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (host.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(host.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (host.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: host.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          avatar: const Icon(Icons.tag, size: 13),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyHosts extends StatelessWidget {
  const _EmptyHosts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: const GlassPanel(
          padding: EdgeInsets.all(18),
          tint: Color(0xf217181a),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArtIconBadge(icon: Icons.add_link, color: AppPalette.graphite),
              SizedBox(height: 12),
              Text(
                '还没有主机。点击右上角加号添加 SSH/SFTP 服务器。',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HostEditorDialog extends StatefulWidget {
  const HostEditorDialog({
    super.key,
    required this.controller,
    this.host,
  });

  final AppController controller;
  final HostProfile? host;

  @override
  State<HostEditorDialog> createState() => _HostEditorDialogState();
}

class _HostEditorDialogState extends State<HostEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.host?.name ?? '');
  late final _hostname =
      TextEditingController(text: widget.host?.hostname ?? '');
  late final _port =
      TextEditingController(text: (widget.host?.port ?? 22).toString());
  late final _username =
      TextEditingController(text: widget.host?.username ?? '');
  late final _tags =
      TextEditingController(text: widget.host?.tags.join(', ') ?? '');
  late final _note = TextEditingController(text: widget.host?.note ?? '');
  final _secret = TextEditingController();
  final _passphrase = TextEditingController();
  late AuthType _authType = widget.host?.authType ?? AuthType.password;
  late String _osHint = widget.host?.osHint ?? 'auto';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.host == null ? '添加主机' : '编辑主机'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _hostname,
                  decoration: const InputDecoration(labelText: '主机地址'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '必填' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(labelText: '用户名'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? '必填' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _port,
                        decoration: const InputDecoration(labelText: '端口'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<AuthType>(
                  segments: const [
                    ButtonSegment(
                      value: AuthType.password,
                      icon: Icon(Icons.password),
                      label: Text('密码'),
                    ),
                    ButtonSegment(
                      value: AuthType.privateKey,
                      icon: Icon(Icons.key),
                      label: Text('密钥'),
                    ),
                  ],
                  selected: {_authType},
                  onSelectionChanged: (value) =>
                      setState(() => _authType = value.single),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _secret,
                  minLines: _authType == AuthType.privateKey ? 4 : 1,
                  maxLines: _authType == AuthType.privateKey ? 8 : 1,
                  obscureText: _authType == AuthType.password,
                  decoration: InputDecoration(
                    labelText: _authType == AuthType.password ? '密码' : '私钥 PEM',
                    helperText: widget.host == null ? null : '留空表示沿用已保存凭据',
                  ),
                  validator: (value) {
                    if (widget.host == null &&
                        (value == null || value.trim().isEmpty)) {
                      return '新主机需要填写凭据';
                    }
                    return null;
                  },
                ),
                if (_authType == AuthType.privateKey) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passphrase,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '密钥口令'),
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(labelText: '标签，逗号分隔'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _osHint,
                  decoration: const InputDecoration(labelText: '系统'),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('自动')),
                    DropdownMenuItem(value: 'linux', child: Text('Linux')),
                    DropdownMenuItem(value: 'windows', child: Text('Windows')),
                  ],
                  onChanged: (value) =>
                      setState(() => _osHint = value ?? 'auto'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveHost(
        id: widget.host?.id,
        name: _name.text,
        hostname: _hostname.text,
        port: int.tryParse(_port.text) ?? 22,
        username: _username.text,
        tags: _tags.text.split(','),
        note: _note.text,
        osHint: _osHint,
        authType: _authType,
        secret: _secret.text,
        passphrase: _passphrase.text,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
