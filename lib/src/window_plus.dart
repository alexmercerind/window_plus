// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/window_state.dart';
import 'package:window_plus/src/models/monitor.dart';
import 'package:window_plus/src/utils/windows_info.dart';
import 'package:window_plus/src/models/saved_window_state.dart';

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
    required super.application,
    bool? enableCustomFrame,
  }) {
    _enableCustomFrame =
        enableCustomFrame ?? WindowsInfo.instance.isWindows10RS1OrGreater;
  }

  /// Performs the initialization of the [WindowPlus] object & `async` operations.
  Future<void> setup() async {
    hwnd = await channel.invokeMethod(
      kEnsureInitializedMethodName,
      {
        'enableCustomFrame': _enableCustomFrame,
        'savedWindowState': (await savedWindowState)?.toJson(),
      },
    );
    // Display the window after the first frame has been rasterized.
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) async {
      channel.invokeMethod(
        kNotifyFirstFrameRasterizedMethodName,
        {
          'savedWindowState': (await savedWindowState)?.toJson(),
        },
      );
    });
    debugPrint(hwnd.toString());
    debugPrint(captionPadding.toString());
    debugPrint(captionHeight.toString());
    debugPrint(captionButtonSize.toString());
  }

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
  }) {
    _instance = WindowPlus._(
      application: application,
      enableCustomFrame: enableCustomFrame,
    );
    return _instance?.setup() ?? Future.value();
  }

  /// Platform channel method call handler.
  /// Used to receive method calls & event callbacks from the platform specific implementation.
  @override
  Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case kWindowMovedMethodName:
        {
          try {
            _position.add(position);
          } catch (exception) {
            //
          }
          break;
        }
      case kWindowResizedMethodName:
        {
          try {
            _size.add(size);
          } catch (exception) {
            //
          }
          break;
        }

      case kSingleInstanceDataReceivedMethodName:
        {
          try {
            _singleInstanceArgumentsHandler?.call(
              List<String>.from(call.arguments),
            );
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kWindowCloseReceivedMethodName:
        {
          try {
            await save();
          } catch (exception) {
            //
          }
          // Call the public handler.
          final result =
              await (_windowCloseHandler?.call() ?? Future.value(true));
          if (result) {
            destroy();
          }
          break;
        }
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

  /// Gets the position of the window on the screen.
  Offset get position {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      final rect = calloc<RECT>();
      GetWindowRect(hwnd, rect);
      final result = Offset(
        rect.ref.left.toDouble(),
        rect.ref.top.toDouble(),
      );
      calloc.free(rect);
      return result;
    }
    // TODO: Missing implementation.
    return Offset.zero;
  }

  /// Gets the size of the window on the screen.
  Rect get size {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      final rect = calloc<RECT>();
      GetWindowRect(hwnd, rect);
      final result = Rect.fromLTRB(
        0,
        0,
        rect.ref.right.toDouble() - rect.ref.left.toDouble(),
        rect.ref.bottom.toDouble() - rect.ref.top.toDouble(),
      );
      calloc.free(rect);
      return result;
    }
    // TODO: Missing implementation.
    return Rect.zero;
  }

  /// Current window position.
  late final Stream<Offset> positionStream = _position.stream;

  /// Current window size.
  late final Stream<Rect> sizeStream = _size.stream;

  /// Sets a function to handle window close events.
  /// This may be used to intercept the close event and perform some actions before closing the window
  /// or prevent window from being closed completely.
  ///
  /// e.g.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await WindowPlus.ensureInitialized(
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
    _windowCloseHandler = windowCloseHandler;
  }

  /// Sets a function to receive the arguments passed to the application when
  /// single instance is enabled.
  ///
  /// This method gets called when the application is opened with single instance
  /// mode enabled. This may be used to handle the event & receieve the arguments.
  ///
  /// **NOTE:**
  /// Currently only single argument is sent/received.
  /// However, `List<String>` is used to prevent breaking changes in the future.
  ///
  /// e.g.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await WindowPlus.ensureInitialized(
  ///     application: 'com.alexmercerind.window_plus',
  ///   );
  ///   WindowPlus.instance.setSingleInstanceArgumentsHandler(
  ///     (List<String> args) async {
  ///       print(args);
  ///     },
  ///   );
  /// }
  /// ```
  ///
  void setSingleInstanceArgumentsHandler(
      void Function(List<String>)? singleInstanceArgumentsHandler) {
    _singleInstanceArgumentsHandler = singleInstanceArgumentsHandler;
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
          final shift = _enableCustomFrame
              ? (getSystemMetrics(SM_CYFRAME) +
                      getSystemMetrics(SM_CXPADDEDBORDER)) *
                  window.devicePixelRatio ~/
                  1
              : 0;
          SetWindowPos(
            flutterWindowHWND,
            NULL,
            rect.ref.left,
            rect.ref.top + shift,
            rect.ref.right - rect.ref.left,
            rect.ref.bottom -
                rect.ref.top -
                (maximized && !fullscreen ? 2 : 1) * shift,
            SWP_FRAMECHANGED,
          );
          calloc.free(flutterWindowClassName);
          calloc.free(rect);
        }
      }
    } else {
      return channel.invokeMethod<void>(
        kSetIsFullscreenMethodName,
        {
          'enabled': enabled,
        },
      );
    }
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
    } else {
      return channel.invokeMethod<void>(kCloseMethodName, {});
    }
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
    } else {
      return channel.invokeMethod<void>(kDestroyMethodName, {});
    }
  }

  /// Moves (or sets position of the window) holding Flutter view on the screen.
  Future<void> move(int x, int y) async {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      SetWindowPos(
        hwnd,
        NULL,
        x,
        y,
        0,
        0,
        SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER,
      );
    } else {
      // TODO: Missing implementation.
      return channel.invokeMethod<void>(
        kMoveMethodName,
        {
          'x': x,
          'y': y,
        },
      );
    }
  }

  /// Resizes (or sets size of the window) holding Flutter view on the screen.
  Future<void> resize(int width, int height) async {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      SetWindowPos(
        hwnd,
        NULL,
        0,
        0,
        width,
        height,
        SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER,
      );
    } else {
      // TODO: Missing implementation.
      return channel.invokeMethod<void>(
        kResizeMethodName,
        {
          'width': width,
          'height': height,
        },
      );
    }
  }

  /// Hides the window holding Flutter view.
  Future<void> hide() async {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      ShowWindow(hwnd, SW_HIDE);
    } else {
      // TODO: Missing implementation.
    }
  }

  /// Shows the window holding Flutter view.
  Future<void> show() async {
    assertEnsureInitialized();
    if (Platform.isWindows) {
      ShowWindow(hwnd, SW_SHOW);
    } else {
      // TODO: Missing implementation.
    }
  }

  Future<List<Monitor>> get monitors async {
    if (Platform.isWindows) {
      final data = calloc<_MonitorsUserData>();
      final monitors = calloc<_Monitor>(kMaximumMonitorCount);
      data.ref.count = 0;
      data.ref.monitors = monitors;
      final result = <Monitor>[];
      EnumDisplayMonitors(
        0,
        nullptr,
        Pointer.fromFunction<MonitorEnumProc>(
          _enumDisplayMonitorsProc,
          TRUE,
        ),
        data.address,
      );
      for (int i = 0; i < data.ref.count; i++) {
        final monitor = data.ref.monitors.elementAt(i).ref;
        result.add(
          Monitor(
            Rect.fromLTRB(
              monitor.work_left.toDouble(),
              monitor.work_top.toDouble(),
              monitor.work_right.toDouble(),
              monitor.work_bottom.toDouble(),
            ),
            Rect.fromLTRB(
              monitor.left.toDouble(),
              monitor.top.toDouble(),
              monitor.right.toDouble(),
              monitor.bottom.toDouble(),
            ),
          ),
        );
      }
      calloc.free(monitors);
      calloc.free(data);
      return result;
    } else {
      // TODO: Missing implementation.
      return [];
    }
  }

  double get captionPadding {
    if (_enableCustomFrame) {
      return getSystemMetrics(SM_CXBORDER);
    }
    return 0.0;
  }

  double get captionHeight {
    if (_enableCustomFrame) {
      return getSystemMetrics(SM_CYCAPTION) +
          getSystemMetrics(SM_CYSIZEFRAME) +
          getSystemMetrics(SM_CXPADDEDBORDER);
    }
    return 0.0;
  }

  Size get captionButtonSize {
    if (_enableCustomFrame) {
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

  /// Window [Rect] before entering fullscreen.
  SavedWindowState _savedWindowStateBeforeFullscreen =
      const SavedWindowState(0, 0, 0, 0, false);

  /// The method gets called when the window close event happens.
  /// This may be used to intercept the event and prevent the window from closing.
  ///
  static Future<bool> Function()? _windowCloseHandler;

  /// This method gets called when the application is opened with single instance mode enabled.
  /// This may be used to handle the event and receieve the arguments.
  ///
  /// **NOTE:**
  /// Currently only single argument is sent/received.
  /// However, `List<String>` is used to prevent breaking changes in the future.
  static void Function(List<String> arguments)? _singleInstanceArgumentsHandler;

  final StreamController<Offset> _position = StreamController.broadcast();
  final StreamController<Rect> _size = StreamController.broadcast();
}

/// A native typed `struct` to retrieve monitor information.
class _MonitorsUserData extends Struct {
  @Int32()
  external int count;

  external Pointer<_Monitor> monitors;
}

/// A native typed `struct` to pack monitor information.
class _Monitor extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
  @Int32()
  external int work_left;
  @Int32()
  external int work_top;
  @Int32()
  external int work_right;
  @Int32()
  external int work_bottom;
  @Int32()
  external int dpi;
}

/// Helper method to enumerate all the monitors on Windows using `package:win32` through `dart:ffi`.
int _enumDisplayMonitorsProc(int monitor, int _, Pointer<RECT> __, int lparam) {
  final info = calloc<MONITORINFO>();
  info.ref.cbSize = sizeOf<MONITORINFO>();
  GetMonitorInfo(monitor, info);
  final data = Pointer<_MonitorsUserData>.fromAddress(lparam);
  final current = data.ref.monitors.elementAt(data.ref.count);
  current.ref.left = info.ref.rcMonitor.left;
  current.ref.top = info.ref.rcMonitor.top;
  current.ref.right = info.ref.rcMonitor.right;
  current.ref.bottom = info.ref.rcMonitor.bottom;
  current.ref.work_left = info.ref.rcWork.left;
  current.ref.work_top = info.ref.rcWork.top;
  current.ref.work_right = info.ref.rcWork.right;
  current.ref.work_bottom = info.ref.rcWork.bottom;
  data.ref.count++;
  calloc.free(info);
  return TRUE;
}
