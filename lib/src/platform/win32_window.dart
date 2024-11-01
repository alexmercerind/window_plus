// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

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
          final result = (await windowCloseHandler?.call()) ?? true;
          if (result) {
            destroy();
          }
          break;
        }
      default:
        {
          debugPrint(call.method.toString());
          debugPrint(call.arguments.toString());
          break;
        }
    }
  }

  /// Whether the window is activated.
  @override
  Future<bool> get activated async {
    ensureHandleAvailable();
    return GetForegroundWindow() == handle;
  }

  /// Whether the window is minimized.
  @override
  Future<bool> get minimized async {
    ensureHandleAvailable();
    return IsIconic(handle) != 0;
  }

  /// Whether the window is maximized.
  @override
  Future<bool> get maximized async {
    ensureHandleAvailable();
    return IsZoomed(handle) != 0;
  }

  /// Gets the minimum size of the window on the screen.
  @override
  Future<Size> get minimumSize async {
    ensureHandleAvailable();
    final result = await channel.invokeMethod(
      kGetMinimumSizeMethodName,
    );
    return Size(
      (result['width'] as int).toDouble(),
      (result['height'] as int).toDouble(),
    );
  }

  /// Whether the window is fullscreen.
  @override
  Future<bool> get fullscreen async {
    ensureHandleAvailable();
    final style = GetWindowLongPtr(handle, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    return !(style & WINDOW_STYLE.WS_OVERLAPPEDWINDOW > 0);
  }

  /// Whether the window is always on top.
  @override
  Future<bool> get alwaysOnTop async {
    ensureHandleAvailable();
    final style = GetWindowLongPtr(handle, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE);
    return (style & WINDOW_EX_STYLE.WS_EX_TOPMOST) > 0;
  }

  /// Gets the position of the window on the screen.
  @override
  Future<Offset> get position async {
    ensureHandleAvailable();
    final rect = calloc<RECT>();
    GetWindowRect(handle, rect);
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
    ensureHandleAvailable();
    final rect = calloc<RECT>();
    GetWindowRect(handle, rect);
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
    ensureHandleAvailable();
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
    ensureHandleAvailable();
    // The primary idea here is to revolve around |WS_OVERLAPPEDWINDOW| & detect/set fullscreen based on it.
    // On the native plugin side implementation, this is separately handled.
    // If there is no |WS_OVERLAPPEDWINDOW| style on the window i.e. in fullscreen, then no area is left for
    // |WM_NCHITTEST|, accordingly client area is also expanded to fill whole monitor using |WM_NCCALCSIZE|.
    final style = GetWindowLongPtr(handle, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    // If the window has |WS_OVERLAPPEDWINDOW| style, it is not fullscreen.
    if (enabled && style & WINDOW_STYLE.WS_OVERLAPPEDWINDOW > 0) {
      final placement = calloc<WINDOWPLACEMENT>();
      final monitor = calloc<MONITORINFO>();
      placement.ref.length = sizeOf<WINDOWPLACEMENT>();
      monitor.ref.cbSize = sizeOf<MONITORINFO>();
      GetWindowPlacement(handle, placement);
      // Save current window position & size as class attribute.
      _savedWindowStateBeforeFullscreen = SavedWindowState(
        placement.ref.rcNormalPosition.left,
        placement.ref.rcNormalPosition.top,
        placement.ref.rcNormalPosition.right - placement.ref.rcNormalPosition.left,
        placement.ref.rcNormalPosition.bottom - placement.ref.rcNormalPosition.top,
        await maximized,
      );
      GetMonitorInfo(
        MonitorFromWindow(handle, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONEAREST),
        monitor,
      );
      SetWindowLongPtr(handle, WINDOW_LONG_PTR_INDEX.GWL_STYLE, style & ~WINDOW_STYLE.WS_OVERLAPPEDWINDOW);
      SetWindowPos(
        handle,
        HWND_TOP,
        monitor.ref.rcMonitor.left,
        monitor.ref.rcMonitor.top,
        monitor.ref.rcMonitor.right - monitor.ref.rcMonitor.left,
        monitor.ref.rcMonitor.bottom - monitor.ref.rcMonitor.top,
        SET_WINDOW_POS_FLAGS.SWP_NOOWNERZORDER | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
      );
      calloc.free(placement);
      calloc.free(monitor);
    }
    // Restore to original state.
    else if (!enabled) {
      SetWindowLongPtr(
        handle,
        WINDOW_LONG_PTR_INDEX.GWL_STYLE,
        style | WINDOW_STYLE.WS_OVERLAPPEDWINDOW,
      );
      // Leave as it is, if the window was maximized before fullscreen.
      if (IsZoomed(handle) == 0) {
        SetWindowPos(
          handle,
          NULL,
          _savedWindowStateBeforeFullscreen.x,
          _savedWindowStateBeforeFullscreen.y,
          _savedWindowStateBeforeFullscreen.width,
          _savedWindowStateBeforeFullscreen.height,
          SET_WINDOW_POS_FLAGS.SWP_NOOWNERZORDER | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
        );
      } else {
        // Refresh the parent [hwnd].
        SetWindowPos(
          handle,
          NULL,
          0,
          0,
          0,
          0,
          SET_WINDOW_POS_FLAGS.SWP_NOMOVE | SET_WINDOW_POS_FLAGS.SWP_NOSIZE | SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_NOOWNERZORDER | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
        );
        // Correctly resize & position the child Flutter view [HWND].
        final rect = calloc<RECT>();
        final flutterWindowClassName = kWin32FlutterViewWindowClass.toNativeUtf16();
        final flutterWindowHWND = FindWindowEx(
          handle,
          0,
          flutterWindowClassName,
          nullptr,
        );
        GetClientRect(handle, rect);
        final shift = enableCustomFrame ? (_getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYFRAME) + _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXPADDEDBORDER)) * _devicePixelRatio ~/ 1 : 0;
        SetWindowPos(
          flutterWindowHWND,
          NULL,
          rect.ref.left,
          rect.ref.top + shift,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top - (await maximized && !await fullscreen ? 2 : 1) * shift,
          SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
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
    ensureHandleAvailable();
    final order = enabled ? HWND_TOPMOST : HWND_NOTOPMOST;
    SetWindowPos(
      handle,
      order,
      NULL,
      NULL,
      NULL,
      NULL,
      SET_WINDOW_POS_FLAGS.SWP_NOMOVE | SET_WINDOW_POS_FLAGS.SWP_NOSIZE,
    );
  }

  /// Maximizes the window holding Flutter view.
  @override
  Future<void> maximize() async {
    ensureHandleAvailable();
    PostMessage(
      handle,
      WM_SYSCOMMAND,
      SC_MAXIMIZE,
      0,
    );
  }

  /// Restores the window holding Flutter view.
  @override
  Future<void> restore() async {
    ensureHandleAvailable();
    PostMessage(
      handle,
      WM_SYSCOMMAND,
      SC_RESTORE,
      0,
    );
  }

  /// Activates the window holding Flutter view.
  @override
  Future<void> activate() async {
    ensureHandleAvailable();
    if (await minimized) {
      await restore();
    }
    SetForegroundWindow(handle);
  }

  /// Deactivates the window holding Flutter view.
  @override
  Future<void> deactivate() async {
    ensureHandleAvailable();
    int next_hwnd = GetWindow(handle, GET_WINDOW_CMD.GW_HWNDNEXT);
    while (next_hwnd != handle) {
      if (IsWindowVisible(next_hwnd) == TRUE) {
        final cloaked = calloc<Int>();
        final dwmWindowAttribute = DwmGetWindowAttribute(
          next_hwnd,
          DWMWINDOWATTRIBUTE.DWMWA_CLOAKED,
          cloaked,
          sizeOf<Int>(),
        );
        if (dwmWindowAttribute != S_OK) {
          cloaked.value = 0;
        }
        if (cloaked.value == 0) {
          SetForegroundWindow(next_hwnd);
          free(cloaked);
          return;
        }
        free(cloaked);
      }
      next_hwnd = GetWindow(next_hwnd, GET_WINDOW_CMD.GW_HWNDNEXT);
    }
    SetForegroundWindow(GetDesktopWindow());
  }

  /// Minimizes the window holding Flutter view.
  @override
  Future<void> minimize() async {
    ensureHandleAvailable();
    PostMessage(
      handle,
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
    ensureHandleAvailable();
    PostMessage(
      handle,
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
    ensureHandleAvailable();
    PostMessage(
      handle,
      WM_NOTIFYDESTROY,
      0,
      0,
    );
  }

  /// Moves (or sets position of the window) holding Flutter view on the screen.
  @override
  Future<void> move(int x, int y) async {
    ensureHandleAvailable();
    SetWindowPos(
      handle,
      NULL,
      x,
      y,
      0,
      0,
      SET_WINDOW_POS_FLAGS.SWP_NOSIZE | SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_NOOWNERZORDER,
    );
  }

  /// Resizes (or sets size of the window) holding Flutter view on the screen.
  @override
  Future<void> resize(int width, int height) async {
    ensureHandleAvailable();
    SetWindowPos(
      handle,
      NULL,
      0,
      0,
      width,
      height,
      SET_WINDOW_POS_FLAGS.SWP_NOMOVE | SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_NOOWNERZORDER,
    );
  }

  /// Hides the window holding Flutter view.
  @override
  Future<void> hide() async {
    ensureHandleAvailable();
    ShowWindow(
      handle,
      SHOW_WINDOW_CMD.SW_HIDE,
    );
  }

  /// Shows the window holding Flutter view.
  @override
  Future<void> show() async {
    ensureHandleAvailable();
    ShowWindow(
      handle,
      SHOW_WINDOW_CMD.SW_SHOW,
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
      Pointer.fromFunction<MONITORENUMPROC>(_enumDisplayMonitorsProc, TRUE),
      data.address,
    );
    for (int i = 0; i < data.ref.count; i++) {
      final monitor = data.ref.monitors + i;
      result.add(
        Monitor(
          Rect.fromLTRB(
            monitor.ref.workLeft.toDouble(),
            monitor.ref.workTop.toDouble(),
            monitor.ref.workRight.toDouble(),
            monitor.ref.workBottom.toDouble(),
          ),
          Rect.fromLTRB(
            monitor.ref.left.toDouble(),
            monitor.ref.top.toDouble(),
            monitor.ref.right.toDouble(),
            monitor.ref.bottom.toDouble(),
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
      return _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXBORDER);
    }
    return 0.0;
  }

  @override
  double get captionHeight {
    if (enableCustomFrame) {
      return _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYCAPTION) + _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSIZEFRAME) + _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXPADDEDBORDER);
    }
    return 0.0;
  }

  @override
  Size get captionButtonSize {
    if (enableCustomFrame) {
      final dx = _getSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYCAPTION) * 2;
      final dy = captionHeight - captionPadding;
      return Size(dx, dy);
    }
    return Size.zero;
  }

  double _getSystemMetrics(int index) {
    ensureHandleAvailable();
    if (enableCustomFrame) {
      try {
        if (WindowsInfo.instance.isWindows10RS1OrGreater) {
          final dpi = GetDpiForWindow(handle);
          return GetSystemMetricsForDpi(index, dpi) / _devicePixelRatio;
        }
        return GetSystemMetrics(index) / _devicePixelRatio;
      } catch (exception, stacktrace) {
        // Fallback.
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        return GetSystemMetrics(index) / _devicePixelRatio;
      }
    }
    // Older Windows versions.
    return 0.0;
  }

  double get _devicePixelRatio {
    ensureHandleAvailable();
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
      return GetDpiForWindow(handle) / 96.0;
    }
    final hdc = GetDC(handle);
    final x = GetDeviceCaps(hdc, GET_DEVICE_CAPS_INDEX.LOGPIXELSX);
    ReleaseDC(handle, hdc);
    return x / 96.0;
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

/// A native typed struct to retrieve monitor information.
class _MonitorsUserData extends Struct {
  @Int32()
  external int count;

  external Pointer<_Monitor> monitors;
}

/// A native typed struct to pack monitor information.
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
  external int workLeft;
  @Int32()
  external int workTop;
  @Int32()
  external int workRight;
  @Int32()
  external int workBottom;
  @Int32()
  external int dpi;
}

/// Helper method to enumerate all the monitors on Windows using package:win32 through dart:ffi.
int _enumDisplayMonitorsProc(
  int monitor,
  int _,
  Pointer<NativeType> __,
  int lparam,
) {
  final info = calloc<MONITORINFO>();
  info.ref.cbSize = sizeOf<MONITORINFO>();
  GetMonitorInfo(monitor, info);
  final data = Pointer<_MonitorsUserData>.fromAddress(lparam);
  final current = data.ref.monitors + data.ref.count;
  current.ref.left = info.ref.rcMonitor.left;
  current.ref.top = info.ref.rcMonitor.top;
  current.ref.right = info.ref.rcMonitor.right;
  current.ref.bottom = info.ref.rcMonitor.bottom;
  current.ref.workLeft = info.ref.rcWork.left;
  current.ref.workTop = info.ref.rcWork.top;
  current.ref.workRight = info.ref.rcWork.right;
  current.ref.workBottom = info.ref.rcWork.bottom;
  data.ref.count++;
  calloc.free(info);
  return TRUE;
}
