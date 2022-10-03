import 'dart:io';
import 'dart:ui';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/window_state.dart';
import 'package:window_plus/src/utils/windows_info.dart';

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
      return getSystemMetrics(SM_CXBORDER);
    }
    return 0.0;
  }

  double get captionHeight {
    if (Platform.isWindows) {
      return getSystemMetrics(SM_CYCAPTION) +
          getSystemMetrics(SM_CYSIZEFRAME) +
          getSystemMetrics(SM_CXPADDEDBORDER);
    }
    return 0.0;
  }

  Size get captionButtonSize {
    if (Platform.isWindows) {
      final dx = getSystemMetrics(SM_CYCAPTION) * 2;
      final dy = captionHeight - captionPadding;
      return Size(dx, dy);
    }
    return Size.zero;
  }

  double getSystemMetrics(int index) {
    if (Platform.isWindows) {
      try {
        // Use DPI aware API [GetSystemMetricsForDpi] on Windows 10 1607+.
        if (WindowsInfo.instance.isWindows10RS1OrGreater) {
          return GetSystemMetricsForDpi(
                index,
                GetDpiForWindow(hwnd),
              ) /
              window.devicePixelRatio;
        }
        // Non DPI aware API [GetSystemMetrics] on older Windows versions.
        else {
          return GetSystemMetrics(index) / window.devicePixelRatio;
        }
      } catch (exception, stacktrace) {
        // Fallback.
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        return GetSystemMetrics(index) / window.devicePixelRatio;
      }
    }
    // Non Windows platforms.
    return 0.0;
  }

  /// [MethodChannel] for communicating with the native side.
  static const MethodChannel _channel = MethodChannel(kMethodChannelName);
}
