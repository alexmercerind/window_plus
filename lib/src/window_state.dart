// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

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
  /// [String] value used to uniquely identify the application.
  final String application;

  /// Whether a custom window frame should be used or not.
  final bool enableCustomFrame;

  /// Whether [Stream]s should be enabled for listening to window state changes
  /// e.g. minimize, maximize, restore, position, size, etc.
  final bool enableEventStreams;

  WindowState({
    required this.application,
    required this.enableCustomFrame,
    required this.enableEventStreams,
  }) {
    // Register the platform channel method call handler.
    channel.setMethodCallHandler(methodCallHandler);
    try {
      storage ??= SafeLocalStorage(localStorageFilePath);
      savedWindowState.then((value) => debugPrint(value.toString()));
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Currently saved window state (on the disk as cache) deserialized as [SavedWindowState].
  ///
  /// This getter is accessed on a fresh start for restoring the window state.
  ///
  Future<SavedWindowState?> get savedWindowState async {
    try {
      final saved = await storage?.read();
      if (saved != null && saved.isNotEmpty) {
        final result = SavedWindowState.fromJson(saved);
        debugPrint(result.toString());
        return result;
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return Future.value(null);
  }

  /// Saves the window position, size & maximized state to the cache before exit.
  Future<void> save() async {
    if (Platform.isWindows) {
      assert(handle != 0);
      // Only save the window state if the window is not minimized.
      if (IsIconic(handle) == 0) {
        final maximized = IsZoomed(handle) != 0;
        final placement = calloc<WINDOWPLACEMENT>();
        placement.ref.length = sizeOf<WINDOWPLACEMENT>();
        GetWindowPlacement(handle, placement);
        final result = SavedWindowState(
          placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.top,
          placement.ref.rcNormalPosition.right - placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.bottom - placement.ref.rcNormalPosition.top,
          maximized,
        );
        calloc.free(placement);
        await storage?.write(result.toJson());
        debugPrint(result.toString());
      }
    } else {
      final result = await channel.invokeMethod(
        kGetStateMethodName,
        {
          'savedWindowState': (await savedWindowState)?.toJson(),
        },
      );
      final state = Map<String, dynamic>.from(result);
      await storage?.write(state);
      debugPrint(state.toString());
    }
  }

  /// A helper getter to get the path to the cached window state [File].
  String get localStorageFilePath {
    switch (Platform.operatingSystem) {
      case 'windows':
        // `SHGetKnownFolderPath` Win32 API call.
        final rfid = GUIDFromString(FOLDERID_RoamingAppData);
        final result = calloc<PWSTR>();
        try {
          final hr = SHGetKnownFolderPath(
            rfid,
            KNOWN_FOLDER_FLAG.KF_FLAG_DEFAULT,
            NULL,
            result,
          );
          if (FAILED(hr)) {
            throw WindowsException(hr);
          }
          return join(
            normalize(result.value.toDartString()),
            application,
            'WindowState.JSON',
          );
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
          // Fallback solution for retrieving the user's `AppData/Roaming` [Directory] using environment variables.
          return join(
            Platform.environment['USERPROFILE']!,
            'AppData',
            'Roaming',
            application,
            'WindowState.JSON',
          );
        } finally {
          calloc.free(rfid);
          calloc.free(result);
        }
      case 'linux':
        return join(
          Platform.environment['HOME']!,
          '.config',
          application,
          'WindowState.JSON',
        );
      default:
        throw Exception(
          'No implementation found for [State.save] for ${Platform.operatingSystem}.',
        );
    }
  }

  /// Platform channel method call handler.
  /// Used to receive method calls & event callbacks from the platform specific implementation.
  Future<dynamic> methodCallHandler(MethodCall call) async {}

  /// Initializes the [WindowState].
  /// This method is called through [WindowPlus.ensureInitialized] since it is asynchronous in nature.
  Future<void> initialize() async {
    try {
      handle = await channel.invokeMethod(
        kEnsureInitializedMethodName,
        {
          'enableCustomFrame': enableCustomFrame,
          'enableEventStreams': enableEventStreams,
          'savedWindowState': (await savedWindowState)?.toJson(),
        },
      );
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    // Display the window after the first frame has been rasterized.
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) async {
      try {
        await channel.invokeMethod(
          kNotifyFirstFrameRasterizedMethodName,
          {
            'savedWindowState': (await savedWindowState)?.toJson(),
          },
        );
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    });
  }

  void ensureHandleAvailable() {
    assert(handle > 0);
  }

  /// [SafeLocalStorage] used for saving the window position, size & maximized state before exit.
  SafeLocalStorage? storage;

  /// The window handle to which this Flutter view is bound.
  int handle = 0;

  /// [MethodChannel] for communicating with the native side.
  final MethodChannel channel = const MethodChannel(kMethodChannelName);
}
