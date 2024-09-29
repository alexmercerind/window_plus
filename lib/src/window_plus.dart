// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';

import 'package:window_plus/src/utils/windows_info.dart';
import 'package:window_plus/src/platform/gtk_window.dart';
import 'package:window_plus/src/platform/win32_window.dart';
import 'package:window_plus/src/platform/platform_window.dart';

/// {@template window_plus}
///
/// WindowPlus
/// ----------
/// The application must call [ensureInitialized] before making use of API from the package.
///
/// e.g.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await WindowPlus.ensureInitialized(
///     application: 'com.example.counter_app',
///   );
///   runApp(const MyApp());
/// }
/// ```
///
/// {@endtemplate}
class WindowPlus {
  /// Singleton instance.
  static PlatformWindow instance = PlatformWindow(
    application: 'com.window_plus.uninitialized',
    enableCustomFrame: false,
    enableEventStreams: false,
  );

  /// Whether the [instance] is initialized.
  static bool initialized = false;

  /// Initializes the instance.
  ///
  /// The [application] argument should be a unique identifier, which is used to save & restore the window state i.e. position, size etc.
  ///
  /// Calling this method makes the window visible.
  ///
  /// * [enableCustomFrame] decides whether a custom window frame should be used or not. The default values for different platforms are:
  ///   * macOS: `true` if macOS 10.15 or greater, `false` otherwise.
  ///   * Windows: `true` if Windows 10 RTM i.e. version 1507 & build 10240 or greater, `false` otherwise.
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
    enableCustomFrame ??= WindowsInfo.instance.isWindows10OrGreater;
    enableEventStreams ??= true;
    if (Platform.isMacOS) {
      // TODO: If someone sees this & wants to help, please do.
    }
    if (Platform.isWindows) {
      instance = Win32Window(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.ensureInitialized();
    }
    if (Platform.isLinux) {
      instance = GTKWindow(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.ensureInitialized();
    }
  }
}
