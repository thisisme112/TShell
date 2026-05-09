import 'dart:io';

import 'package:flutter/services.dart';

class BackgroundKeepAlive {
  static const _channel = MethodChannel('tshell/background');

  static Future<void> setActive(bool active, int sessions) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(
        active ? 'start' : 'stop',
        {'sessions': sessions},
      );
    } catch (_) {
      // Desktop and debug shells can run without the Android service.
    }
  }
}
