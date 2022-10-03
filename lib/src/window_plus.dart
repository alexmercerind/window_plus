import 'dart:io';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/window_state.dart';

/// The primary API to draw & handle the custom window frame.
///
/// The application must call [ensureInitialized] before making use of any other APIs.
///
/// e.g.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await WindowPlus.ensureInitialized(
///     application: 'com.alexmercerind.window_plus',
///   );
///   runApp(const MyApp());
/// }
/// ```
///
class WindowPlus extends WindowState {
  /// Globally accessible singleton [instance] of [WindowPlus].
  static WindowPlus get instance {
    if (_instance == null) {
      assert(
        false,
        '[WindowPlus.instance] is not initialized. Call [WindowPlus.ensureInitialized] before accessing the singleton [instance].',
      );
    }
    return _instance!;
  }

  static WindowPlus? _instance;

  WindowPlus._({
    required String application,
  }) : super(application: application);

  /// Initializes the [WindowPlus] instance for use.
  ///
  /// Pass an [application] name to uniquely identify the application.
  /// This is used to save & restore the window state at a well-defined location.
  ///
  static Future<void> ensureInitialized({
    required String application,
  }) async {
    if (Platform.isWindows) {
      _instance = WindowPlus._(application: application);
      // Make the window visible based on saved state.
      final savedWindowState = await _instance?.savedWindowState;
      _instance?.hwnd = await _channel.invokeMethod(
        kEnsureInitializedMethodName,
        savedWindowState?.toJson(),
      );
      debugPrint(_instance?.hwnd.toString());
      debugPrint(_instance?.captionPadding.toString());
      debugPrint(_instance?.captionHeight.toString());
      debugPrint(_instance?.captionButtonSize.toString());
    }
  }

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
