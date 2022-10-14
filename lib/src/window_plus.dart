// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/saved_window_state.dart';
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
  /// Calling this method makes the window rendering the Flutter view visible.
  ///
  /// [enableCustomFrame] argument decides whether a custom window frame should be
  /// used or not. By default, [enableCustomFrame] will be `true` for Windows 10
  /// RS1 (Anniversary Update) or higher (i.e. Windows 10 & 11). Enabling this on
  /// older Windows versions may result in undefined behaviors & thus not recommended.
  ///
  static Future<void> ensureInitialized({
    required String application,
    bool? enableCustomFrame,
  }) async {
    _instance?._enableCustomFrame =
        enableCustomFrame ?? WindowsInfo.instance.isWindows10RS1OrGreater;
    if (Platform.isWindows) {
      _instance = WindowPlus._(application: application);
      // Make the window visible based on saved state.
      _instance?.hwnd = await _channel.invokeMethod(
        kEnsureInitializedMethodName,
        {
          'enableCustomFrame': _instance?._enableCustomFrame,
          'savedWindowState': (await _instance?.savedWindowState)?.toJson(),
        },
      );
      debugPrint(_instance?.hwnd.toString());
      debugPrint(_instance?.captionPadding.toString());
      debugPrint(_instance?.captionHeight.toString());
      debugPrint(_instance?.captionButtonSize.toString());
    }
  }

  /// Whether the window is minimized.
  bool get minimized {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      return IsIconic(hwnd) != 0;
    }
    // TODO: Missing implementation.
    return false;
  }

  /// Whether the window is maximized.
  bool get maximized {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      return IsZoomed(hwnd) != 0;
    }
    // TODO: Missing implementation.
    return false;
  }

  /// Whether the window is fullscreen.
  bool get fullscreen {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      final style = GetWindowLongPtr(hwnd, GWL_STYLE);
      return !(style & WS_OVERLAPPEDWINDOW > 0);
    }
    // TODO: Missing implementation.
    return false;
  }

  /// This method must be called before [ensureInitialized].
  ///
  /// Sets a function to handle window close events.
  /// This may be used to intercept the close event and perform some actions before closing the window
  /// or prevent window from being closed completely.
  ///
  /// e.g.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   WindowPlus.ensureInitialized(
  ///     application: 'com.alexmercerind.window_plus',
  ///   );
  ///   WindowPlus.instance.setWindowShouldCloseHandler(
  ///     () async {
  ///       if (isSomeOperationInProgress) {
  ///         return false;
  ///       }
  ///       return true;
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// When a user click on the close button on a window, the plug-in redirects
  /// the event to your function. The function should return a future that
  /// returns a boolean to tell the plug-in whether the user really wants to
  /// close the window or not. True will let the window to be closed, while
  /// false let the window to remain open.
  ///
  /// By default there is no handler, and the window will be directly closed
  /// when a window close event happens. You can also reset the handler by
  /// passing null to the method.
  ///
  void setWindowCloseHandler(
    Future<bool> Function()? windowCloseHandler,
  ) {
    assert(
      _windowCloseHandler == null,
      '[WindowPlus.setWindowCloseHandler] is already set.',
    );
    _windowCloseHandler = windowCloseHandler;
  }

  /// Enables or disables the fullscreen mode.
  ///
  /// If [enabled] is `true`, the window will be made fullscreen.
  /// Once [enabled] is passed as `false` in future, window will be restored back to it's prior state i.e. maximized or restored at same position & size.
  ///
  Future<void> setIsFullscreen(bool enabled) async {
    assertEnsureInitialized();
    // The primary idea here is to revolve around |WS_OVERLAPPEDWINDOW| & detect/set fullscreen based on it.
    // On the native plugin side implementation, this is separately handled.
    // If there is no |WS_OVERLAPPEDWINDOW| style on the window i.e. in fullscreen, then no area is left for
    // |WM_NCHITTEST|, accordingly client area is also expanded to fill whole monitor using |WM_NCCALCSIZE|.
    if (Platform.isWindows) {
      final style = GetWindowLongPtr(hwnd, GWL_STYLE);
      // If the window has |WS_OVERLAPPEDWINDOW| style, it is not fullscreen.
      if (enabled && style & WS_OVERLAPPEDWINDOW > 0) {
        final placement = calloc<WINDOWPLACEMENT>();
        final monitor = calloc<MONITORINFO>();
        placement.ref.length = sizeOf<WINDOWPLACEMENT>();
        monitor.ref.cbSize = sizeOf<MONITORINFO>();
        GetWindowPlacement(hwnd, placement);
        // Save current window position & size as class attribute.
        _savedWindowStateBeforeFullscreen = SavedWindowState(
          placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.top,
          placement.ref.rcNormalPosition.right -
              placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.bottom -
              placement.ref.rcNormalPosition.top,
          maximized,
        );
        GetMonitorInfo(
          MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST),
          monitor,
        );
        SetWindowLongPtr(hwnd, GWL_STYLE, style & ~WS_OVERLAPPEDWINDOW);
        SetWindowPos(
          hwnd,
          HWND_TOP,
          monitor.ref.rcMonitor.left,
          monitor.ref.rcMonitor.top,
          monitor.ref.rcMonitor.right - monitor.ref.rcMonitor.left,
          monitor.ref.rcMonitor.bottom - monitor.ref.rcMonitor.top,
          SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
        );
        calloc.free(placement);
        calloc.free(monitor);
        // calloc.free(flutterWindowClassName);
        // calloc.free(rect);
      }
      // Restore to original state.
      else if (!enabled) {
        SetWindowLongPtr(hwnd, GWL_STYLE, style | WS_OVERLAPPEDWINDOW);
        // Leave as it is, if the window was maximized before fullscreen.
        if (IsZoomed(hwnd) == 0) {
          SetWindowPos(
            hwnd,
            NULL,
            _savedWindowStateBeforeFullscreen.x,
            _savedWindowStateBeforeFullscreen.y,
            _savedWindowStateBeforeFullscreen.width,
            _savedWindowStateBeforeFullscreen.height,
            SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
          );
        } else {
          // Refresh the parent [hwnd].
          SetWindowPos(
            hwnd,
            NULL,
            0,
            0,
            0,
            0,
            SWP_NOMOVE |
                SWP_NOSIZE |
                SWP_NOZORDER |
                SWP_NOOWNERZORDER |
                SWP_FRAMECHANGED,
          );
          // Correctly resize & position the child Flutter view [HWND].
          final rect = calloc<RECT>();
          final flutterWindowClassName =
              kWin32FlutterViewWindowClass.toNativeUtf16();
          final flutterWindowHWND = FindWindowEx(
            hwnd,
            0,
            flutterWindowClassName,
            nullptr,
          );
          GetClientRect(hwnd, rect);
          SetWindowPos(
            flutterWindowHWND,
            NULL,
            rect.ref.left,
            rect.ref.top,
            rect.ref.right - rect.ref.left,
            rect.ref.bottom - rect.ref.top,
            SWP_FRAMECHANGED,
          );
          calloc.free(flutterWindowClassName);
          calloc.free(rect);
        }
      }
    }
    // TODO: Missing implementation.
    return Future.value(null);
  }

  /// Maximizes the window holding Flutter view.
  FutureOr<void> maximize() {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      PostMessage(
        hwnd,
        WM_SYSCOMMAND,
        SC_MAXIMIZE,
        0,
      );
    }
    // TODO: Missing implementation.
  }

  /// Restores the window holding Flutter view.
  FutureOr<void> restore() {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      PostMessage(
        hwnd,
        WM_SYSCOMMAND,
        SC_RESTORE,
        0,
      );
    }
    // TODO: Missing implementation.
  }

  /// Minimizes the window holding Flutter view.
  FutureOr<void> minimize() {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      PostMessage(
        hwnd,
        WM_SYSCOMMAND,
        SC_MINIMIZE,
        0,
      );
    }
    // TODO: Missing implementation.
  }

  /// Closes the window holding Flutter view.
  ///
  /// This method respects the callback set by [setWindowCloseHandler] & saves window state before exit.
  ///
  /// If the set callback returns `false`, the window will not be closed.
  ///
  FutureOr<void> close() {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      PostMessage(
        hwnd,
        WM_CLOSE,
        0,
        0,
      );
    }
    // TODO: Missing implementation.
  }

  /// Destroys the window holding Flutter view.
  ///
  /// This method does not respect the callback set by [setWindowCloseHandler] & does not save window state before exit.
  ///
  Future<void> destroy() async {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      PostMessage(
        hwnd,
        WM_DESTROY,
        0,
        0,
      );
    }
    // TODO: Missing implementation.
  }

  double get captionPadding {
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
      return getSystemMetrics(SM_CXBORDER);
    }
    return 0.0;
  }

  double get captionHeight {
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
      return getSystemMetrics(SM_CYCAPTION) +
          getSystemMetrics(SM_CYSIZEFRAME) +
          getSystemMetrics(SM_CXPADDEDBORDER);
    }
    return 0.0;
  }

  Size get captionButtonSize {
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
      final dx = getSystemMetrics(SM_CYCAPTION) * 2;
      final dy = captionHeight - captionPadding;
      return Size(dx, dy);
    }
    return Size.zero;
  }

  double getSystemMetrics(int index) {
    assertEnsureInitialized();
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
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

  void assertEnsureInitialized() {
    assert(
      _instance != null && hwnd != 0,
      'Either [WindowPlus.ensureInitialized] is not called or window [HWND] could not be retrieved.',
    );
  }

  /// Whether a custom window frame should be used or not.
  bool _enableCustomFrame = false;

  /// Only used on Windows.
  /// Window [Rect] before entering fullscreen.
  SavedWindowState _savedWindowStateBeforeFullscreen =
      const SavedWindowState(0, 0, 0, 0, false);

  /// [MethodChannel] for communicating with the native side.
  static final MethodChannel _channel = const MethodChannel(kMethodChannelName)
    ..setMethodCallHandler((call) async {
      debugPrint(call.method);
      switch (call.method) {
        case kWindowCloseReceivedMethodName:
          {
            // Save the window state before closing the window.
            try {
              await WindowPlus.instance.save();
            } catch (exception, stacktrace) {
              debugPrint(exception.toString());
              debugPrint(stacktrace.toString());
            }
            // Call the public handler.
            final destroy =
                await (_windowCloseHandler?.call() ?? Future.value(true));
            if (destroy) {
              _instance?.destroy();
            }
            break;
          }
      }
    });

  /// The method which gets called when the window close event happens.
  /// This may be used to intercept the event and prevent the window from closing.
  ///
  static Future<bool> Function()? _windowCloseHandler;
}
