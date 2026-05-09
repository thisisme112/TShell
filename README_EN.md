# TShell

TShell is a Flutter-based cross-platform SSH terminal and remote operations tool. It combines SSH sessions, host management, SFTP file operations, and system metrics into one focused workspace for daily server access and lightweight maintenance tasks.

The interface uses a dark editorial magazine style: black paper texture, warm ivory typography, gold/copper/red/teal accents, column rules, and layered panels. It is designed to feel more like a polished remote workstation than a plain table-heavy utility.

## Features

- SSH terminal connections with multiple session tabs
- Host profile management with password and private key authentication
- Terminal copy/paste shortcuts while preserving combinations such as `Ctrl+A` for screen/tmux
- Remote metrics for CPU, memory, disks, network, and GPU data
- SFTP file browsing, upload, download, copy, move, rename, and delete
- Edit remote files with the system editor and sync changes back after saving
- Secure local credential storage
- Windows desktop and Android APK builds

## Shortcuts

- `Ctrl+Shift+C`: copy terminal selection
- `Ctrl+Shift+V`: paste into terminal
- `Ctrl+A` and similar combinations are passed through to the remote terminal for tools such as `screen`, `tmux`, and shells

## Build

Install Flutter, the Android SDK, and Windows build tools first.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release
flutter build apk --release
```

Windows artifact:

```text
build/windows/x64/runner/Release/tshell.exe
```

Android artifact:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Tech Stack

- Flutter / Dart
- xterm
- dartssh2
- sqflite
- flutter_secure_storage
- file_picker
- open_file

## Platform Status

- Windows: supported
- Android: supported
- Linux/macOS: project structure is available, but they are not verified release targets yet

## Note

The current Android release APK is generated with debug signing for local installation and testing. Use a production signing configuration before publishing to an app store.

Chinese documentation: [README.md](README.md)
