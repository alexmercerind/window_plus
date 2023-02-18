// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:window_plus/src/utils/windows_info.dart';
import 'package:window_plus/src/platform/gtk_window.dart';
import 'package:window_plus/src/platform/win32_window.dart';
import 'package:window_plus/src/platform/platform_window.dart';

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
class WindowPlus {
  /// [WindowPlus] singleton instance.

  // This is liskov substituted with the platform specific instance e.g.
  // [Win32Window] or [GTKWindow] in [ensureInitialized].
  // It avoids any redundant null check errors at runtime.
  static PlatformWindow instance = PlatformWindow(
    application: 'com.window_plus.uninitialized',
    enableCustomFrame: false,
    enableEventStreams: false,
  );

  /// Initializes the [WindowPlus] instance for use.
  ///
  /// Pass an [application] name to uniquely identify the application.
  /// This is used to save & restore the window state at a well-defined location.
  ///
  /// Calling this method makes the window rendering the Flutter view visible.
  ///
  /// [enableCustomFrame] argument decides whether a custom window frame should be
  /// used or not. By default, [enableCustomFrame] will be `true` for Windows 10
  /// RS1 (Anniversary Update) or higher (i.e. Windows 10 & 11). Enabling this on
  /// older Windows versions may result in undefined behaviors & thus not recommended.
  ///
  /// [enableEventStreams] argument decides whether [Stream]s should be enabled
  /// for listening to window state changes e.g. minimize, maximize, restore,
  /// position, size, etc. It is `true` by default. Disabling this should be
  /// considered if this ability is not needed. This may yield performance improvements.
  ///
  static Future<void> ensureInitialized({
    required String application,
    bool? enableCustomFrame,
    bool? enableEventStreams,
  }) async {
    // Default values.
    enableCustomFrame ??= WindowsInfo.instance.isWindows10RS1OrGreater;
    enableEventStreams ??= true;
    // Platform specific polymorphic initialization.
    if (Platform.isWindows) {
      instance = Win32Window(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.initialize();
    }
    if (Platform.isLinux) {
      instance = GTKWindow(
        application: application,
        enableCustomFrame: enableCustomFrame,
        enableEventStreams: enableEventStreams,
      );
      await instance.initialize();
    }
  }
}
