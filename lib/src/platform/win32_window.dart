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

  @override
  Future<bool> get activated async {
    ensureHandleAvailable();
    return GetForegroundWindow() == hwnd;
  }

  @override
  Future<bool> get minimized async {
    ensureHandleAvailable();
    return IsIconic(hwnd);
  }

  @override
  Future<bool> get maximized async {
    ensureHandleAvailable();
    return IsZoomed(hwnd);
  }

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

  @override
  Future<bool> get fullscreen async {
    ensureHandleAvailable();
    final style = GetWindowLongPtr(hwnd, GWL_STYLE).value;
    return !(style & WS_OVERLAPPEDWINDOW > 0);
  }

  @override
  Future<bool> get alwaysOnTop async {
    ensureHandleAvailable();
    final style = GetWindowLongPtr(hwnd, GWL_EXSTYLE).value;
    return (style & WS_EX_TOPMOST) > 0;
  }

  @override
  Future<Offset> get position async {
    ensureHandleAvailable();
    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);
    final result = Offset(rect.ref.left.toDouble(), rect.ref.top.toDouble());
    calloc.free(rect);
    return result;
  }

  @override
  Future<Rect> get size async {
    ensureHandleAvailable();
    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);
    final result = Rect.fromLTRB(
      0,
      0,
      (rect.ref.right - rect.ref.left).toDouble(),
      (rect.ref.bottom - rect.ref.top).toDouble(),
    );
    calloc.free(rect);
    return result;
  }

  @override
  Future<void> setIsFullscreen(bool enabled) async {
    ensureHandleAvailable();
    final style = GetWindowLongPtr(hwnd, GWL_STYLE).value;
    if (enabled && style & WS_OVERLAPPEDWINDOW > 0) {
      final windowPlacement = calloc<WINDOWPLACEMENT>();
      final monitor = calloc<MONITORINFO>();
      windowPlacement.ref.length = sizeOf<WINDOWPLACEMENT>();
      monitor.ref.cbSize = sizeOf<MONITORINFO>();
      GetWindowPlacement(hwnd, windowPlacement);
      _savedWindowStateBeforeFullscreen = SavedWindowState(
        windowPlacement.ref.rcNormalPosition.left,
        windowPlacement.ref.rcNormalPosition.top,
        windowPlacement.ref.rcNormalPosition.right - windowPlacement.ref.rcNormalPosition.left,
        windowPlacement.ref.rcNormalPosition.bottom - windowPlacement.ref.rcNormalPosition.top,
        await maximized,
      );
      GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), monitor);
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
      calloc.free(windowPlacement);
      calloc.free(monitor);
    } else if (!enabled) {
      SetWindowLongPtr(
        hwnd,
        GWL_STYLE,
        style | WS_OVERLAPPEDWINDOW,
      );
      if (!IsZoomed(hwnd)) {
        SetWindowPos(
          hwnd,
          null,
          _savedWindowStateBeforeFullscreen.x,
          _savedWindowStateBeforeFullscreen.y,
          _savedWindowStateBeforeFullscreen.width,
          _savedWindowStateBeforeFullscreen.height,
          SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
        );
      } else {
        SetWindowPos(
          hwnd,
          null,
          0,
          0,
          0,
          0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
        );
        final rect = calloc<RECT>();
        final flutterWindowClassName = kWin32FlutterViewWindowClass.toPcwstr();
        final flutterWindowHwnd = FindWindowEx(hwnd, null, flutterWindowClassName, null).value;
        GetClientRect(hwnd, rect);
        SetWindowPos(
          flutterWindowHwnd,
          null,
          rect.ref.left,
          rect.ref.top,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top,
          SWP_FRAMECHANGED,
        );
        calloc.free(rect);
        calloc.free(flutterWindowClassName);
      }
    }
  }

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

  @override
  Future<void> setIsAlwaysOnTop(bool enabled) async {
    ensureHandleAvailable();
    final order = enabled ? HWND_TOPMOST : HWND_NOTOPMOST;
    SetWindowPos(
      hwnd,
      order,
      0,
      0,
      0,
      0,
      SWP_NOMOVE | SWP_NOSIZE,
    );
  }

  @override
  Future<void> maximize() async {
    ensureHandleAvailable();
    PostMessage(hwnd, WM_SYSCOMMAND, const WPARAM(SC_MAXIMIZE), const LPARAM(0));
  }

  @override
  Future<void> restore() async {
    ensureHandleAvailable();
    PostMessage(hwnd, WM_SYSCOMMAND, const WPARAM(SC_RESTORE), const LPARAM(0));
  }

  @override
  Future<void> activate() async {
    ensureHandleAvailable();
    if (await minimized) {
      await restore();
    }
    SetForegroundWindow(hwnd);
  }

  @override
  Future<void> deactivate() async {
    ensureHandleAvailable();
    HWND next = GetWindow(hwnd, GW_HWNDNEXT).value;
    while (next != hwnd) {
      if (IsWindowVisible(next)) {
        final cloaked = calloc<Int>();
        try {
          DwmGetWindowAttribute(next, DWMWA_CLOAKED, cloaked, sizeOf<Int>());
        } on WindowsException {
          cloaked.value = 0;
        }
        if (cloaked.value == 0) {
          SetForegroundWindow(next);
          free(cloaked);
          return;
        }
        free(cloaked);
      }
      next = GetWindow(next, GW_HWNDNEXT).value;
    }
    SetForegroundWindow(GetDesktopWindow());
  }

  @override
  Future<void> minimize() async {
    ensureHandleAvailable();
    PostMessage(hwnd, WM_SYSCOMMAND, const WPARAM(SC_MINIMIZE), const LPARAM(0));
  }

  @override
  Future<void> close() async {
    ensureHandleAvailable();
    PostMessage(hwnd, WM_CLOSE, const WPARAM(0), const LPARAM(0));
  }

  @override
  Future<void> destroy() async {
    ensureHandleAvailable();
    PostMessage(hwnd, WM_NOTIFYDESTROY, const WPARAM(0), const LPARAM(0));
  }

  @override
  Future<void> move(int x, int y) async {
    ensureHandleAvailable();
    SetWindowPos(
      hwnd,
      null,
      x,
      y,
      0,
      0,
      SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER,
    );
  }

  @override
  Future<void> resize(int width, int height) async {
    ensureHandleAvailable();
    SetWindowPos(
      hwnd,
      null,
      0,
      0,
      width,
      height,
      SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER,
    );
  }

  @override
  Future<void> hide() async {
    ensureHandleAvailable();
    ShowWindow(hwnd, SW_HIDE);
  }

  @override
  Future<void> show() async {
    ensureHandleAvailable();
    ShowWindow(hwnd, SW_SHOW);
  }

  @override
  Future<List<Monitor>> get monitors async {
    final data = calloc<_MonitorsUserData>();
    final monitors = calloc<_Monitor>(kWin32MaximumMonitorCount);
    data.ref.count = 0;
    data.ref.monitors = monitors;
    final result = <Monitor>[];
    EnumDisplayMonitors(
      null,
      nullptr,
      Pointer.fromFunction<MONITORENUMPROC>(_enumDisplayMonitorsProc, TRUE),
      LPARAM(data.address),
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
      return _getSystemMetrics(SM_CXBORDER);
    }
    return 0.0;
  }

  @override
  double get captionHeight {
    if (enableCustomFrame) {
      return _getSystemMetrics(SM_CYCAPTION) + _getSystemMetrics(SM_CYSIZEFRAME) + _getSystemMetrics(SM_CXPADDEDBORDER);
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

  double _getSystemMetrics(SYSTEM_METRICS_INDEX index) {
    ensureHandleAvailable();
    if (enableCustomFrame) {
      try {
        if (WindowsInfo.instance.isWindows10RS1OrGreater) {
          final dpi = GetDpiForWindow(hwnd);
          return GetSystemMetricsForDpi(index, dpi).value / _devicePixelRatio;
        }
        return GetSystemMetrics(index) / _devicePixelRatio;
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        return GetSystemMetrics(index) / _devicePixelRatio;
      }
    }

    return 0.0;
  }

  double get _devicePixelRatio {
    ensureHandleAvailable();
    if (WindowsInfo.instance.isWindows10RS1OrGreater) {
      return GetDpiForWindow(hwnd) / 96.0;
    }
    final hdc = GetDC(hwnd);
    final x = GetDeviceCaps(hdc, LOGPIXELSX);
    ReleaseDC(hwnd, hdc);
    return x / 96.0;
  }

  SavedWindowState _savedWindowStateBeforeFullscreen = const SavedWindowState(0, 0, 0, 0, false);
}

class _MonitorsUserData extends Struct {
  @Int32()
  external int count;
  external Pointer<_Monitor> monitors;
}

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

int _enumDisplayMonitorsProc(
  Pointer monitor,
  Pointer hdc,
  Pointer<RECT> lprect,
  int lparam,
) {
  final info = calloc<MONITORINFO>();
  info.ref.cbSize = sizeOf<MONITORINFO>();
  GetMonitorInfo(HMONITOR(monitor), info);
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
