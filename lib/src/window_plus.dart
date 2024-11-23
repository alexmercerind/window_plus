import 'dart:io';

import 'package:window_plus/src/platform/ns_window.dart';
import 'package:window_plus/src/platform/gtk_window.dart';
import 'package:window_plus/src/platform/win32_window.dart';
import 'package:window_plus/src/platform/platform_window.dart';
import 'package:window_plus/src/utils/windows_info.dart';

/// {@template window_plus}
///
/// WindowPlus
/// ----------
///
/// {@endtemplate}
class WindowPlus {
  /// Singleton instance.
  static late final PlatformWindow instance;

  /// Whether the [instance] is initialized.
  static bool initialized = false;

  /// Initializes the instance.
  ///
  /// The [application] argument should be a unique identifier, which is used to save & restore the window state i.e. position, size etc.
  ///
  /// Calling this method makes the window visible.
  ///
  /// * [enableCustomFrame] decides whether a custom window frame should be used or not. The default values for different platforms are:
  ///   * macOS:     Depends on the configured window style.
  ///   * Windows:   `true` if Windows 10 RTM i.e. version 1507 & build 10240 or greater, `false` otherwise.
  ///   * GNU/Linux: `false` (too much nonsense with all the desktop environments).
  ///
  /// * [enableEventStreams] argument decides whether event streams should be enabled for listening to window state changes e.g. minimize, maximize, restore, position, size, etc.
  ///   Disabling this may yield performance improvements. The default value is `true`.
  ///
  static Future<void> ensureInitialized({
    required String application,
    bool? enableCustomFrame,
    bool? enableEventStreams,
  }) async {
    if (initialized) return;
    initialized = true;
    enableCustomFrame ??= WindowsInfo.instance.isWindows10RS1OrGreater;
    enableEventStreams ??= true;
    if (Platform.isMacOS) {
      instance = NSWindow(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.ensureInitialized();
    } else if (Platform.isWindows) {
      instance = Win32Window(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.ensureInitialized();
    } else if (Platform.isLinux) {
      instance = GTKWindow(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.ensureInitialized();
    }
  }
}
