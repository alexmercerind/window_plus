import 'dart:io';
import 'package:win32/win32.dart';
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
  static Future<void> ensureInitialized() async {
    if (Platform.isWindows) {
      instance.hwnd = await _channel.invokeMethod(kEnsureInitializedMethodName);
      debugPrint(instance.hwnd.toString());
      debugPrint(instance.captionPadding.toString());
      debugPrint(instance.captionHeight.toString());
      debugPrint(instance.captionButtonSize.toString());
    }
  }

  /// `HWND` of the window. Only for Windows.
  int hwnd = 0;

  double get captionPadding {
    if (Platform.isWindows) {
      return GetSystemMetrics(SM_CXBORDER) * 1.0;
    }
    return 0.0;
  }

  double get captionHeight {
    if (Platform.isWindows) {
      final pixels = GetSystemMetrics(SM_CYCAPTION) +
          GetSystemMetrics(SM_CYSIZEFRAME) +
          GetSystemMetrics(SM_CXPADDEDBORDER);
      return pixels * 1.0;
    }
    return 0.0;
  }

  Size get captionButtonSize {
    if (Platform.isWindows) {
      final dx = GetSystemMetrics(SM_CYCAPTION) * 2.0;
      final dy = (captionHeight - GetSystemMetrics(SM_CXBORDER));
      return Size(dx, dy);
    }
    return Size.zero;
  }

  /// [MethodChannel] for communicating with the native side.
  static const MethodChannel _channel = MethodChannel(kMethodChannelName);
}
