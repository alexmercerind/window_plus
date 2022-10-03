import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

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
      final rect = calloc<RECT>();
      final zoomed = IsZoomed(hwnd) == 1;
      GetWindowRect(hwnd, rect);
      final result = SavedWindowState(
        rect.ref.left,
        rect.ref.top,
        rect.ref.right - rect.ref.left,
        rect.ref.bottom - rect.ref.top,
        zoomed,
      );
      calloc.free(rect);
      await storage?.write(result.toJson());
      debugPrint(result.toString());
    } else {
      // TODO: Missing implementation.
      throw MissingPluginException(
        'No implementation found for [State.save] for ${Platform.operatingSystem}.',
      );
    }
  }

  /// A helper getter to get the path to the cached window state [File].
  String get localStorageFilePath {
    switch (Platform.operatingSystem) {
      case 'windows':
        return join(
          Platform.environment['USERPROFILE']!,
          'AppData',
          'Roaming',
          application,
          'window_state.json',
        );
      case 'linux':
        return join(
          Platform.environment['HOME']!,
          '.config',
          application,
          'window_state.json',
        );
      default:
        throw Exception(
          'No implementation found for [State.save] for ${Platform.operatingSystem}.',
        );
    }
  }

  /// The window handle to which this Flutter view is bound. Only Windows specific.
  int hwnd = 0;
}