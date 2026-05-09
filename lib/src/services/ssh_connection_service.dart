import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

import '../models.dart';
import 'credential_store.dart';

class SshConnection {
  SshConnection({
    required this.host,
    required this.client,
  });

  final HostProfile host;
  final SSHClient client;

  Future<SSHSession> openShell({
    required int columns,
    required int rows,
  }) {
    return client.shell(
      pty: SSHPtyConfig(width: columns, height: rows),
    );
  }

  Future<SftpClient> openSftp() => client.sftp();

  Future<String> runCommand(String command) async {
    final session = await client.execute(command);
    final stdout = await utf8.decodeStream(session.stdout);
    final stderr = await utf8.decodeStream(session.stderr);
    await session.done;
    if (stderr.trim().isNotEmpty) {
      return '$stdout\n$stderr'.trim();
    }
    return stdout.trim();
  }

  void close() {
    client.close();
  }
}

class SshConnectionService {
  SshConnectionService(this._credentials);

  final CredentialStore _credentials;

  Future<SshConnection> connect(HostProfile host) async {
    final credential = await _credentials.read(host.credentialRef);
    final socket = await SSHSocket.connect(
      host.hostname,
      host.port,
      timeout: const Duration(seconds: 12),
    );
    final identities = <SSHKeyPair>[];
    if (host.authType == AuthType.privateKey) {
      final pem = credential.privateKey;
      if (pem == null || pem.trim().isEmpty) {
        throw StateError('Private key is missing for ${host.name}');
      }
      identities.addAll(SSHKeyPair.fromPem(pem, credential.passphrase));
    }
    final client = SSHClient(
      socket,
      username: host.username,
      identities: identities.isEmpty ? null : identities,
      onPasswordRequest: host.authType == AuthType.password
          ? () => credential.password ?? ''
          : null,
    );
    return SshConnection(host: host, client: client);
  }
}

class TerminalSession {
  TerminalSession({
    required this.id,
    required this.host,
    required this.connection,
  })  : terminal = Terminal(maxLines: 10000),
        controller = TerminalController();

  final String id;
  final HostProfile host;
  final SshConnection connection;
  final Terminal terminal;
  final TerminalController controller;

  SSHSession? _session;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  SessionStatus status = SessionStatus.connecting;
  String? error;

  Future<void> start() async {
    status = SessionStatus.connecting;
    try {
      _session = await connection.openShell(
        columns: terminal.viewWidth == 0 ? 80 : terminal.viewWidth,
        rows: terminal.viewHeight == 0 ? 24 : terminal.viewHeight,
      );
      final session = _session!;
      _stdoutSub = session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(
            terminal.write,
            onError: (Object err) => terminal.write('\r\n$err\r\n'),
          );
      _stderrSub = session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(
            terminal.write,
            onError: (Object err) => terminal.write('\r\n$err\r\n'),
          );
      terminal.onOutput = (data) {
        session.write(Uint8List.fromList(utf8.encode(data)));
      };
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };
      session.done.whenComplete(() {
        status = SessionStatus.disconnected;
        terminal.write('\r\n[TShell] session closed\r\n');
      });
      status = SessionStatus.connected;
    } catch (err) {
      status = SessionStatus.failed;
      error = err.toString();
      terminal.write('[TShell] connect failed: $err\r\n');
      rethrow;
    }
  }

  Future<String?> copySelection() async {
    final selection = controller.selection;
    if (selection == null) {
      return null;
    }
    final text = terminal.buffer.getText(selection);
    controller.clearSelection();
    return text;
  }

  void paste(String text) {
    terminal.paste(text);
  }

  Future<void> close() async {
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _session?.close();
    connection.close();
    status = SessionStatus.disconnected;
  }
}
