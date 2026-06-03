# TShell

TShell 是一款基于 Flutter 的跨平台 SSH 终端与远程运维工具。它把 SSH 终端、主机管理、SFTP 文件操作和资源监控放在同一个界面里，适合日常连接服务器、查看状态、编辑远程文件和处理简单运维任务。

界面采用暗色编辑风杂志设计：黑色纸张纹理、米白标题、金铜/红/青点缀，以及更明显的栏目线和卡片层次。它不是传统“表格工具”外观，而是更偏精致、沉浸式的远程工作台。

## 功能

- SSH 终端连接，支持多会话标签
- 主机配置管理，支持密码和私钥认证
- 终端复制/粘贴快捷键，保留 `Ctrl+A` 等组合键给 screen/tmux 使用
- 远程资源监控，包括 CPU、内存、磁盘、网络和 GPU 信息
- SFTP 文件浏览、上传、下载、复制、移动、重命名和删除
- 可调用系统编辑器编辑远程文件，并在保存后同步上传
- 本地安全存储凭据
- Windows 桌面版和 Android APK 构建

## 快捷键

- `Ctrl+Shift+C`：复制终端选区
- `Ctrl+Shift+V`：粘贴到终端
- `Ctrl+A` 等组合键会直接传给远程终端，方便在 `screen`、`tmux`、shell 中使用

## 构建

请先安装 Flutter、Android SDK 和 Windows 构建工具。

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release
flutter build apk --release
```

Windows 产物：

```text
build/windows/x64/runner/Release/tshell.exe
```

Android 产物：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 技术栈

- Flutter / Dart
- xterm
- dartssh2
- sqflite
- flutter_secure_storage
- file_picker
- open_file

## 平台状态

- Windows：已支持
- Android：已支持
- Linux/macOS：代码结构预留，尚未作为正式发布目标验证

## 说明

当前 release 使用 debug signing 配置生成 Android APK，适合本地安装和测试。如果要发布到应用商店，请替换为正式签名配置。

English documentation: [README_EN.md](README_EN.md)
