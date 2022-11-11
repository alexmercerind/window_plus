// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/monitor.dart';
import 'package:window_plus/src/platform/platform_window.dart';

/// Linux implementation for [PlatformWindow].
class GTKWindow extends PlatformWindow {
  GTKWindow({
    required super.application,
    required super.enableCustomFrame,
  });

  @override
  Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case kWindowStateEventReceivedMethodName:
        {
          try {
            minimizedStreamController.add(
              call.arguments['minimized'],
            );
            maximizedStreamController.add(
              call.arguments['maximized'],
            );
            fullscreenStreamController.add(
              call.arguments['fullscreen'],
            );
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
          break;
        }
      case kConfigureEventReceivedMethodName:
        {
          try {
            positionStreamController.add(
              Offset(
                call.arguments['position']['dx'] * 1.0,
                call.arguments['position']['dy'] * 1.0,
              ),
            );
            sizeStreamController.add(
              Rect.fromLTRB(
                call.arguments['size']['left'] * 1.0,
                call.arguments['size']['top'] * 1.0,
                call.arguments['size']['right'] * 1.0,
                call.arguments['size']['bottom'] * 1.0,
              ),
            );
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
          debugPrint(call.method.toString());
          debugPrint(call.arguments.toString());
          break;
        }
    }
  }

  /// Whether the window is minimized.
  @override
  Future<bool> get minimized async {
    assert_();
    return await channel.invokeMethod(kGetIsMinimizedMethodName);
  }

  /// Whether the window is maximized.
  @override
  Future<bool> get maximized async {
    assert_();
    return await channel.invokeMethod(kGetIsMaximizedMethodName);
  }

  /// Whether the window is fullscreen.
  @override
  Future<bool> get fullscreen async {
    assert_();
    return await channel.invokeMethod(kGetIsFullscreenMethodName);
  }

  /// Gets the position of the window on the screen.
  @override
  Future<Offset> get position async {
    assert_();
    final position = await channel.invokeMethod(
      kGetPositionMethodName,
    );
    return Offset(
      position['dx'] * 1.0,
      position['dy'] * 1.0,
    );
  }

  /// Gets the size of the window on the screen.
  @override
  Future<Rect> get size async {
    assert_();
    final size = await channel.invokeMethod(
      kGetSizeMethodName,
    );
    return Rect.fromLTRB(
      size['left'] * 1.0,
      size['top'] * 1.0,
      size['right'] * 1.0,
      size['bottom'] * 1.0,
    );
  }

  /// Enables or disables the fullscreen mode.
  ///
  /// If [enabled] is `true`, the window will be made fullscreen.
  /// Once [enabled] is passed as `false` in future, window will be restored back to it's prior state i.e. maximized or restored at same position & size.
  ///
  @override
  Future<void> setIsFullscreen(bool enabled) async {
    assert_();
    await channel.invokeMethod(
      kSetIsFullscreenMethodName,
      {
        'enabled': enabled,
      },
    );
  }

  /// Maximizes the window holding Flutter view.
  @override
  Future<void> maximize() async {
    assert_();
    await channel.invokeMethod(kMaximizeMethodName);
  }

  /// Restores the window holding Flutter view.
  @override
  Future<void> restore() async {
    assert_();
    await channel.invokeMethod(kRestoreMethodName);
  }

  /// Minimizes the window holding Flutter view.
  @override
  Future<void> minimize() async {
    assert_();
    await channel.invokeMethod(kMinimizeMethodName);
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
    await channel.invokeMethod(kCloseMethodName);
  }

  /// Destroys the window holding Flutter view.
  ///
  /// This method does not respect the callback set by [setWindowCloseHandler] & does not save window state before exit.
  ///
  @override
  Future<void> destroy() async {
    assert_();
    await channel.invokeMethod(kDestroyMethodName);
  }

  /// Moves (or sets position of the window) holding Flutter view on the screen.
  @override
  Future<void> move(int x, int y) async {
    assert_();
    await channel.invokeMethod(
      kMoveMethodName,
      {
        'x': x,
        'y': y,
      },
    );
  }

  /// Resizes (or sets size of the window) holding Flutter view on the screen.
  @override
  Future<void> resize(int width, int height) async {
    assert_();
    await channel.invokeMethod(
      kResizeMethodName,
      {
        'width': width,
        'height': height,
      },
    );
  }

  /// Hides the window holding Flutter view.
  @override
  Future<void> hide() async {
    assert_();
    await channel.invokeMethod(kHideMethodName);
  }

  /// Shows the window holding Flutter view.
  @override
  Future<void> show() async {
    assert_();
    await channel.invokeMethod(kShowMethodName);
  }

  @override
  Future<List<Monitor>> get monitors async {
    assert_();
    final monitors = await channel.invokeMethod(kGetMonitorsMethodName);
    return List<Monitor>.from(
      monitors.map(
        (monitor) => Monitor(
          Rect.fromLTRB(
            monitor['workarea']['left'] * 1.0,
            monitor['workarea']['top'] * 1.0,
            monitor['workarea']['right'] * 1.0,
            monitor['workarea']['bottom'] * 1.0,
          ),
          Rect.fromLTRB(
            monitor['bounds']['left'] * 1.0,
            monitor['bounds']['top'] * 1.0,
            monitor['bounds']['right'] * 1.0,
            monitor['bounds']['bottom'] * 1.0,
          ),
        ),
      ),
    );
  }

  @override
  double get captionPadding {
    return 0.0;
  }

  @override
  double get captionHeight {
    return 0.0;
  }

  @override
  Size get captionButtonSize {
    return Size.zero;
  }
}
