import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models.dart';
import 'ssh_connection_service.dart';

typedef TransferProgress = void Function(int transferred, int total);
typedef TransferStatus = void Function(String status);

class RemoteFileService {
  RemoteFileService(this.connection);

  final SshConnection connection;
  SftpClient? _sftp;

  Future<SftpClient> get _client async => _sftp ??= await connection.openSftp();

  Future<List<RemoteFileEntry>> list(String remotePath) async {
    final sftp = await _client;
    final items = await sftp.listdir(remotePath);
    final result = <RemoteFileEntry>[];
    for (final item in items) {
      if (item.filename == '.' || item.filename == '..') {
        continue;
      }
      final mode = item.attr.mode;
      final path = _joinRemote(remotePath, item.filename);
      result.add(RemoteFileEntry(
        path: path,
        name: item.filename,
        isDirectory: mode?.type == SftpFileType.directory,
        size: item.attr.size ?? 0,
        modifiedAt: item.attr.modifyTime == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000),
        permissions:
            mode == null ? '' : mode.value.toRadixString(8).padLeft(6, '0'),
      ));
    }
    result.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<String> homePath() async {
    final output = await connection.runCommand(
      r'printf "$HOME" 2>/dev/null || powershell -NoProfile -Command "$HOME"',
    );
    final home = output.split('\n').first.trim();
    return home.isEmpty ? '.' : home;
  }

  Future<String?> uploadPicked(
    String remoteDirectory, {
    TransferProgress? onProgress,
  }) async {
    final picked = await FilePicker.platform.pickFiles();
    if (picked == null || picked.files.single.path == null) {
      return null;
    }
    final localPath = picked.files.single.path!;
    final remotePath = _joinRemote(remoteDirectory, p.basename(localPath));
    await upload(localPath, remotePath, onProgress: onProgress);
    return remotePath;
  }

  Future<void> upload(
    String localPath,
    String remotePath, {
    TransferProgress? onProgress,
  }) async {
    final sftp = await _client;
    final total = await File(localPath).length();
    final file = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );
    try {
      await file
          .write(
            File(localPath).openRead().cast<Uint8List>(),
            onProgress: (sent) => onProgress?.call(sent, total),
          )
          .done;
    } finally {
      await file.close();
    }
  }

  Future<File> download(
    String remotePath, {
    TransferProgress? onProgress,
  }) async {
    final sftp = await _client;
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final localFile = File(p.join(dir.path, p.basename(remotePath)));
    final remote = await sftp.open(remotePath);
    try {
      final attrs = await remote.stat();
      final total = attrs.size ?? 0;
      final sink = localFile.openWrite();
      try {
        await sink.addStream(
          remote.read(onProgress: (read) => onProgress?.call(read, total)),
        );
      } finally {
        await sink.close();
      }
      return localFile;
    } finally {
      await remote.close();
    }
  }

  Future<void> editWithSystemApp(
    String remotePath, {
    TransferProgress? onDownloadProgress,
    TransferProgress? onUploadProgress,
    TransferStatus? onStatus,
  }) async {
    if (!Platform.isWindows) {
      return;
    }
    onStatus?.call('下载到临时文件');
    final local = await download(remotePath, onProgress: onDownloadProgress);
    var lastUploaded = await local.lastModified();
    onStatus?.call('正在打开本地编辑器');
    final waitFuture = _openEditorAndMaybeWait(local.path);
    var editorClosed = false;
    var canDetectClose = true;
    waitFuture.whenComplete(() {
      editorClosed = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (editorClosed) {
      canDetectClose = false;
      editorClosed = false;
      onStatus?.call('已打开编辑器，继续监听保存');
    } else {
      onStatus?.call('已打开编辑器，等待保存');
    }
    var ticks = 0;
    while (!editorClosed && ticks < 900) {
      ticks++;
      await Future<void>.delayed(const Duration(seconds: 2));
      final exists = await local.exists();
      if (!exists) {
        onStatus?.call('本地临时文件已删除');
        return;
      }
      final after = await local.lastModified();
      if (after.isAfter(lastUploaded)) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        onStatus?.call('检测到保存，上传覆盖');
        await upload(
          local.path,
          remotePath,
          onProgress: onUploadProgress,
        );
        lastUploaded = await local.lastModified();
        onStatus?.call('已同步，继续监听保存');
      }
    }
    if (canDetectClose) {
      await waitFuture;
      onStatus?.call('编辑器已关闭，监听结束');
    } else {
      onStatus?.call('监听超时结束');
    }
  }

  Future<void> _openEditorAndMaybeWait(String localPath) async {
    if (!Platform.isWindows) {
      final result = await OpenFile.open(localPath);
      if (result.type != ResultType.done) {
        throw StateError(result.message);
      }
      return;
    }
    try {
      await Process.start('explorer.exe', [localPath]);
      return;
    } catch (_) {
      final result = await OpenFile.open(localPath);
      if (result.type != ResultType.done) {
        throw StateError(result.message);
      }
    }
  }

  Future<void> delete(RemoteFileEntry entry) async {
    final sftp = await _client;
    if (entry.isDirectory) {
      await sftp.rmdir(entry.path);
    } else {
      await sftp.remove(entry.path);
    }
  }

  Future<void> move(String from, String to) async {
    final sftp = await _client;
    await sftp.rename(from, to);
  }

  Future<void> copyFile(String from, String to) async {
    final temp = await download(from);
    await upload(temp.path, to);
  }

  Future<void> close() async {
    _sftp?.close();
    _sftp = null;
  }

  String _joinRemote(String directory, String name) {
    if (directory.endsWith('/')) {
      return '$directory$name';
    }
    if (directory.contains('\\')) {
      return '$directory\\$name';
    }
    return '$directory/$name';
  }
}
