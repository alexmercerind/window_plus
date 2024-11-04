import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';

typedef RtlGetVersionNative = Void Function(Pointer<OSVERSIONINFOEX>);
typedef RtlGetVersionDart = void Function(Pointer<OSVERSIONINFOEX>);

class WindowsInfo {
  static const int kWindows10RTM = 10240;
  static const int kWindows10RS1 = 14393;

  static WindowsInfo instance = WindowsInfo._();

  bool isWindows10RTMOrGreater = false;
  bool isWindows10RS1OrGreater = false;

  WindowsInfo._() {
    try {
      if (Platform.isWindows) {
        final osVersionInfo = calloc<OSVERSIONINFOEX>();
        osVersionInfo.ref
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
        final rtlGetVersion = DynamicLibrary.open('ntdll.dll').lookupFunction<RtlGetVersionNative, RtlGetVersionDart>('RtlGetVersion');
        rtlGetVersion(osVersionInfo);
        isWindows10RTMOrGreater = osVersionInfo.ref.dwBuildNumber >= kWindows10RTM;
        isWindows10RS1OrGreater = osVersionInfo.ref.dwBuildNumber >= kWindows10RS1;
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }
}
