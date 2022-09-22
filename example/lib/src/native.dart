import 'package:flutter/services.dart';
import 'package:window_plus_example/src/common.dart';

class WindowPlus {
  static const WindowPlus instance = WindowPlus._();

  const WindowPlus._();

  Future<void> ensureInitialized() {
    return _channel.invokeMethod<void>(kEnsureInitializedMethodName);
  }

  static const MethodChannel _channel = MethodChannel(kMethodChannelName);
}
