import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:flutter/foundation.dart';

class WindowsInfo {
  static WindowsInfo instance = WindowsInfo._();

  OSVERSIONINFOEX? data;

  static const int _kWindows10RTM = 10240;
  static const int _kWindows10RS1 = 14393;

  /// Whether the current OS is Windows 10 or later.
  bool isWindows10OrGreater = false;

  /// Whether the current Windows version is Windows 10 Anniversary Update or later.
  /// i.e. version 1607 & build 14393.
  ///
  /// Used for safely invoking DPI aware APIs. Namely [GetDpiForWindow] & [GetSystemMetricsForDpi].
  bool isWindows10RS1OrGreater = false;

  WindowsInfo._() {
    if (Platform.isWindows) {
      try {
        final pointer = calloc<OSVERSIONINFOEX>();
        pointer.ref
          ..dwOSVersionInfoSize = sizeOf<OSVERSIONINFOEX>()
          ..dwBuildNumber = 0
          ..dwMajorVersion = 0
          ..dwMinorVersion = 0
          ..dwPlatformId = 0
          ..szCSDVersion = ''
          ..wServicePackMajor = 0
          ..wServicePackMinor = 0
          ..wSuiteMask = 0
          ..wProductType = 0
          ..wReserved = 0;
        final rtlGetVersion = DynamicLibrary.open('ntdll.dll').lookupFunction<
            Void Function(Pointer<OSVERSIONINFOEX>),
            void Function(Pointer<OSVERSIONINFOEX>)>('RtlGetVersion');
        rtlGetVersion(pointer);
        data = pointer.ref;
        isWindows10OrGreater = pointer.ref.dwBuildNumber >= _kWindows10RTM;
        isWindows10RS1OrGreater = pointer.ref.dwBuildNumber >= _kWindows10RS1;
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        isWindows10OrGreater = false;
        isWindows10RS1OrGreater = false;
      }
    } else {
      isWindows10OrGreater = false;
      isWindows10RS1OrGreater = false;
    }
  }
}
