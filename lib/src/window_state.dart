import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/saved_window_state.dart';

class WindowState {
  final String application;
  final bool enableCustomFrame;
  final bool enableEventStreams;

  WindowState({
    required this.application,
    required this.enableCustomFrame,
    required this.enableEventStreams,
  }) {
    channel.setMethodCallHandler(methodCallHandler);
  }

  Future<void> ensureInitialized() async {
    try {
      handle = await channel.invokeMethod(
        kEnsureInitializedMethodName,
        {
          'enableCustomFrame': enableCustomFrame,
          'enableEventStreams': enableEventStreams,
          'savedWindowState': (await savedWindowState)?.toJson(),
        },
      );
    } catch (_) {}

    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) async {
      try {
        await channel.invokeMethod(
          kNotifyFirstFrameRasterizedMethodName,
          {
            'savedWindowState': (await savedWindowState)?.toJson(),
          },
        );
      } catch (_) {}
    });
  }

  Future<dynamic> methodCallHandler(MethodCall call) async {}

  void ensureHandleAvailable() {
    assert(handle > 0);
  }

  Future<void> save() async {
    ensureHandleAvailable();
    if (Platform.isMacOS) {
      // TODO: Missing implementation.
    } else if (Platform.isWindows) {
      if (IsIconic(handle) == 0) {
        final maximized = IsZoomed(handle) != 0;
        final windowPlacement = calloc<WINDOWPLACEMENT>();
        windowPlacement.ref.length = sizeOf<WINDOWPLACEMENT>();
        GetWindowPlacement(handle, windowPlacement);
        final result = SavedWindowState(
          windowPlacement.ref.rcNormalPosition.left,
          windowPlacement.ref.rcNormalPosition.top,
          windowPlacement.ref.rcNormalPosition.right - windowPlacement.ref.rcNormalPosition.left,
          windowPlacement.ref.rcNormalPosition.bottom - windowPlacement.ref.rcNormalPosition.top,
          maximized,
        );
        calloc.free(windowPlacement);
        await storage.write(result.toJson());
        debugPrint(result.toString());
      }
    } else if (Platform.isLinux) {
      final result = await channel.invokeMethod(
        kGetStateMethodName,
        {
          'savedWindowState': (await savedWindowState)?.toJson(),
        },
      );
      await storage.write(result);
      debugPrint(result.toString());
    }
  }

  Future<SavedWindowState?> get savedWindowState async {
    try {
      final data = await storage.read();
      return SavedWindowState.fromJson(data);
    } catch (_) {}
    return null;
  }

  int handle = 0;
  late final MethodChannel channel = const MethodChannel(kMethodChannelName);
  late final SafeLocalStorage storage = SafeLocalStorage(getStoragePath(application));

  static String getStoragePath(String application) {
    if (Platform.isMacOS) {
      // TODO: Missing implementation.
    } else if (Platform.isWindows) {
      final rfid = GUIDFromString(FOLDERID_RoamingAppData);
      final result = calloc<PWSTR>();
      try {
        final hr = SHGetKnownFolderPath(rfid, KNOWN_FOLDER_FLAG.KF_FLAG_DEFAULT, NULL, result);
        if (FAILED(hr)) {
          throw WindowsException(hr);
        }
        return join(normalize(result.value.toDartString()), application, 'WindowState.JSON');
      } catch (_) {
        return join(Platform.environment['USERPROFILE']!, 'AppData', 'Roaming', application, 'WindowState.JSON');
      } finally {
        calloc.free(rfid);
        calloc.free(result);
      }
    } else if (Platform.isLinux) {
      return join(Platform.environment['HOME']!, '.config', application, 'WindowState.JSON');
    }
    throw UnimplementedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
