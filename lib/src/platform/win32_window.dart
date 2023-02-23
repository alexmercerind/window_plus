// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:ui';
import 'dart:ffi' hide Size;
import 'dart:async';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/monitor.dart';
import 'package:window_plus/src/utils/windows_info.dart';
import 'package:window_plus/src/platform/platform_window.dart';
import 'package:window_plus/src/models/saved_window_state.dart';

/// Windows implementation for [PlatformWindow].
class Win32Window extends PlatformWindow {
  Win32Window({
    required super.application,
    required super.enableCustomFrame,
    required super.enableEventStreams,
  });

  @override
  Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case kWindowActivatedMethodName:
        {
          try {
            activatedStreamController.add(await activated);
          } on AssertionError catch (_) {
            // NOTE: [WindowsPlus.instance.hwnd] is `0` during fresh start until [WindowPlus.ensureInitialized] resolves.
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kWindowMovedMethodName:
        {
          try {
            positionStreamController.add(await position);
          } on AssertionError catch (_) {
            // NOTE: [WindowsPlus.instance.hwnd] is `0` during fresh start until [WindowPlus.ensureInitialized] resolves.
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kWindowResizedMethodName:
        {
          try {
            sizeStreamController.add(await size);
          } on AssertionError catch (_) {
            // NOTE: [WindowsPlus.instance.hwnd] is `0` during fresh start until [WindowPlus.ensureInitialized] resolves.
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kWindowFullScreenMethodName:
        {
          try {
            fullscreenStreamController.add(await fullscreen);
          } on AssertionError catch (_) {
            // NOTE: [WindowsPlus.instance.hwnd] is `0` during fresh start until [WindowPlus.ensureInitialized] resolves.
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kSingleInstanceDataReceivedMethodName:
        {
          try {
            singleInstanceArgumentsHandler?.call(
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
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          // Call the public handler.
          final result =
              await (windowCloseHandler?.call() ?? Future.value(true));
          if (result) {
            destroy();
          }
          break;
        }
      default:
        {
          // TODO (@alexmercerind): Implement remaining streams.
          debugPrint(call.method.toString());
          debugPrint(call.arguments.toString());
          break;
        }
    }
  }

  /// Whether the window is activated.
  @override
  Future<bool> get activated async {
    assert_();
    return GetForegroundWindow() == hwnd;
  }

  /// Whether the window is minimized.
  @override
  Future<bool> get minimized async {
    assert_();
    return IsIconic(hwnd) != 0;
  }

  /// Whether the window is maximized.
  @override
  Future<bool> get maximized async {
    assert_();
    return IsZoomed(hwnd) != 0;
  }

  /// Gets the minimum size of the window on the screen.
  @override
  Future<Size> get minimumSize async {
    assert_();
    final Map<Object?, Object?> sizeMap = await channel.invokeMethod(
      kGetMinimumSizeMethodName,
    );
    return Size(
      (sizeMap['width'] as int).toDouble(), 
      (sizeMap['height'] as int).toDouble(),
    );
  }

  /// Whether the window is fullscreen.
  @override
  Future<bool> get fullscreen async {
    assert_();
    final style = GetWindowLongPtr(hwnd, GWL_STYLE);
    return !(style & WS_OVERLAPPEDWINDOW > 0);
  }

  /// Whether the window is always on top.
  @override
  Future<bool> get alwaysOnTop async {
    assert_();
    final style = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    return (style & WS_EX_TOPMOST) > 0;
  }

  /// Gets the position of the window on the screen.
  @override
  Future<Offset> get position async {
    assert_();
    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);
    final result = Offset(
      rect.ref.left.toDouble(),
      rect.ref.top.toDouble(),
    );
    calloc.free(rect);
    return result;
  }

  /// Gets the size of the window on the screen.
  @override
  Future<Rect> get size async {
    assert_();
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

  /// Sets the minimum size of the window holding Flutter view.
  @override
  Future<void> setMinimumSize(Size? size) async {
    assert_();
    try {
      await channel.invokeMethod(
        kSetMinimumSizeMethodName,
        {
          'width': size?.width ?? 0,
          'height': size?.height ?? 0,
        },
      );
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Enables or disables the fullscreen mode.
  ///
  /// If [enabled] is `true`, the window will be made fullscreen.
  /// Once [enabled] is passed as `false` in future, window will be restored back to it's prior state i.e. maximized or restored at same position & size.
  ///
  @override
  Future<void> setIsFullscreen(bool enabled) async {
    assert_();
    // The primary idea here is to revolve around |WS_OVERLAPPEDWINDOW| & detect/set fullscreen based on it.
    // On the native plugin side implementation, this is separately handled.
    // If there is no |WS_OVERLAPPEDWINDOW| style on the window i.e. in fullscreen, then no area is left for
    // |WM_NCHITTEST|, accordingly client area is also expanded to fill whole monitor using |WM_NCCALCSIZE|.
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
        await maximized,
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
        final shift = enableCustomFrame
            ? (_getSystemMetrics(SM_CYFRAME) +
                    _getSystemMetrics(SM_CXPADDEDBORDER)) *
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
              (await maximized && !await fullscreen ? 2 : 1) * shift,
          SWP_FRAMECHANGED,
        );
        calloc.free(flutterWindowClassName);
        calloc.free(rect);
      }
    }
  }

  /// Enables or disables the always on top mode.
  ///
  /// If [enabled] is `true`, the window will be made topmost.
  /// Once [enabled] is passed as `false` in future, window will be normal.
  ///
  @override
  Future<void> setIsAlwaysOnTop(bool enabled) async {
    assert_();
    final order = enabled ? HWND_TOPMOST : HWND_NOTOPMOST;
    SetWindowPos(hwnd, order, NULL, NULL, NULL, NULL, SWP_NOMOVE | SWP_NOSIZE);
  }

  /// Maximizes the window holding Flutter view.
  @override
  Future<void> maximize() async {
    assert_();
    PostMessage(
      hwnd,
      WM_SYSCOMMAND,
      SC_MAXIMIZE,
      0,
    );
  }

  /// Restores the window holding Flutter view.
  @override
  Future<void> restore() async {
    assert_();
    PostMessage(
      hwnd,
      WM_SYSCOMMAND,
      SC_RESTORE,
      0,
    );
  }

  /// Activates the window holding Flutter view.
  @override
  Future<void> activate() async {
    assert_();
    if (await minimized) {
      await restore();
    }
    SetForegroundWindow(hwnd);
  }

  /// Deactivates the window holding Flutter view.
  @override
  Future<void> deactivate() async {
    assert_();
    int next_hwnd = GetWindow(hwnd, GW_HWNDNEXT);
    while (next_hwnd != hwnd) {
      if (IsWindowVisible(next_hwnd) == TRUE) {
        final cloaked = calloc<Int>();
        final dwmWindowAttribute = DwmGetWindowAttribute(next_hwnd, 
          DWMWINDOWATTRIBUTE.DWMWA_CLOAKED,
          cloaked,
          sizeOf<Int>(),
        );
        if (dwmWindowAttribute != S_OK)
        {
          cloaked.value = 0;
        }
        if (cloaked.value == 0){
          SetForegroundWindow(next_hwnd);
          free(cloaked);
          return;
        }
        free(cloaked);
      }
      next_hwnd = GetWindow(next_hwnd, GW_HWNDNEXT);
    }
    SetForegroundWindow(GetDesktopWindow());
  }

  /// Minimizes the window holding Flutter view.
  @override
  Future<void> minimize() async {
    assert_();
    PostMessage(
      hwnd,
      WM_SYSCOMMAND,
      SC_MINIMIZE,
      0,
    );
  }

  /// Closes the window holding Flutter view.
  ///
  /// This method respects the callback set by [setWindowCloseHandler] & saves window state before exit.
  ///
  /// If the set callback returns `false`, the window will not be closed.
  ///
  @override
  Future<void> close() async {
    assert_();
    PostMessage(
      hwnd,
      WM_CLOSE,
      0,
      0,
    );
  }

  /// Destroys the window holding Flutter view.
  ///
  /// This method does not respect the callback set by [setWindowCloseHandler] & does not save window state before exit.
  ///
  @override
  Future<void> destroy() async {
    assert_();
    PostMessage(
      hwnd,
      WM_NOTIFYDESTROY,
      0,
      0,
    );
  }

  /// Moves (or sets position of the window) holding Flutter view on the screen.
  @override
  Future<void> move(int x, int y) async {
    assert_();
    SetWindowPos(
      hwnd,
      NULL,
      x,
      y,
      0,
      0,
      SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER,
    );
  }

  /// Resizes (or sets size of the window) holding Flutter view on the screen.
  @override
  Future<void> resize(int width, int height) async {
    assert_();
    SetWindowPos(
      hwnd,
      NULL,
      0,
      0,
      width,
      height,
      SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER,
    );
  }

  /// Hides the window holding Flutter view.
  @override
  Future<void> hide() async {
    assert_();
    ShowWindow(
      hwnd,
      SW_HIDE,
    );
  }

  /// Shows the window holding Flutter view.
  @override
  Future<void> show() async {
    assert_();
    ShowWindow(
      hwnd,
      SW_SHOW,
    );
  }

  @override
  Future<List<Monitor>> get monitors async {
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
  }

  @override
  double get captionPadding {
    if (enableCustomFrame) {
      return _getSystemMetrics(SM_CXBORDER);
    }
    return 0.0;
  }

  @override
  double get captionHeight {
    if (enableCustomFrame) {
      return _getSystemMetrics(SM_CYCAPTION) +
          _getSystemMetrics(SM_CYSIZEFRAME) +
          _getSystemMetrics(SM_CXPADDEDBORDER);
    }
    return 0.0;
  }

  @override
  Size get captionButtonSize {
    if (enableCustomFrame) {
      final dx = _getSystemMetrics(SM_CYCAPTION) * 2;
      final dy = captionHeight - captionPadding;
      return Size(dx, dy);
    }
    return Size.zero;
  }

  double _getSystemMetrics(int index) {
    assert_();
    if (enableCustomFrame) {
      try {
        // Use DPI aware API [GetSystemMetricsForDpi] on Windows 10 Anniversary Update i.e. 14393.
        // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetricsfordpi
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
    // Older Windows versions.
    return 0.0;
  }

  /// Window [Rect] before entering fullscreen.
  SavedWindowState _savedWindowStateBeforeFullscreen = const SavedWindowState(
    0,
    0,
    0,
    0,
    false,
  );
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
