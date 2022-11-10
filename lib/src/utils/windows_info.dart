// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:flutter/foundation.dart';

typedef RtlGetVersionNative = Void Function(Pointer<OSVERSIONINFOEX>);
typedef RtlGetVersionDart = void Function(Pointer<OSVERSIONINFOEX>);

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
        final rtlGetVersion = DynamicLibrary.open(
          'ntdll.dll',
        ).lookupFunction<RtlGetVersionNative, RtlGetVersionDart>(
          'RtlGetVersion',
        );
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
