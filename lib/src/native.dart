import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:window_plus/src/common.dart';

/// The primary API to draw & handle the custom window frame.
///
/// The application must call [ensureInitialized] before making use of any other APIs.
///
/// e.g.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await WindowPlus.instance.ensureInitialized();
///   runApp(const MyApp());
/// }
/// ```
///
class WindowPlus {
  /// Globally accessible singleton [instance] of [WindowPlus].
  static final WindowPlus instance = WindowPlus._();

  WindowPlus._();

  /// Initializes the [WindowPlus] instance for use.
  Future<void> ensureInitialized() async {
    if (Platform.isWindows) {
      final result = await _channel.invokeMethod(kEnsureInitializedMethodName);
      debugPrint(result.toString());
      captionHeight = result[kCaptionHeightKey];
      hwnd = result[kHwndKey];
    }
  }

  /// Height of the title bar.
  /// If it is `0`, then it indicates that a custom title bar is not being used.
  int captionHeight = 0;

  /// `HWND` of the window. Only for Windows.
  int hwnd = 0;

  /// [MethodChannel] for communicating with the native side.
  static const MethodChannel _channel = MethodChannel(kMethodChannelName);
}
