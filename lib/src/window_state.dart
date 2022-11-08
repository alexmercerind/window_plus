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

  /// [SafeLocalStorage] used for saving the window position, size & maximized state before exit.
  SafeLocalStorage? storage;

  WindowState({
    required this.application,
  }) {
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
      assert(hwnd != 0);
      // Only save the window state if the window is not minimized.
      if (IsIconic(hwnd) == 0) {
        final maximized = IsZoomed(hwnd) != 0;
        final placement = calloc<WINDOWPLACEMENT>();
        placement.ref.length = sizeOf<WINDOWPLACEMENT>();
        GetWindowPlacement(hwnd, placement);
        final result = SavedWindowState(
          placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.top,
          placement.ref.rcNormalPosition.right -
              placement.ref.rcNormalPosition.left,
          placement.ref.rcNormalPosition.bottom -
              placement.ref.rcNormalPosition.top,
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
            KF_FLAG_DEFAULT,
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

  /// The window handle to which this Flutter view is bound. Only Windows specific.
  int hwnd = 0;

  /// [MethodChannel] for communicating with the native side.
  final MethodChannel channel = const MethodChannel(kMethodChannelName);
}
