import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/monitor.dart';
import 'package:window_plus/src/platform/platform_window.dart';

class GTKWindow extends PlatformWindow {
  GTKWindow({
    required super.application,
    required super.enableCustomFrame,
    required super.enableEventStreams,
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
                call.arguments['position']['x'] * 1.0,
                call.arguments['position']['y'] * 1.0,
              ),
            );
            sizeStreamController.add(
              Rect.fromLTWH(
                call.arguments['size']['left'] * 1.0,
                call.arguments['size']['top'] * 1.0,
                call.arguments['size']['width'] * 1.0,
                call.arguments['size']['height'] * 1.0,
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
  Future<bool> get minimized async {
    ensureHandleAvailable();
    return await channel.invokeMethod(kGetIsMinimizedMethodName);
  }

  @override
  Future<bool> get maximized async {
    ensureHandleAvailable();
    return await channel.invokeMethod(kGetIsMaximizedMethodName);
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
    return await channel.invokeMethod(kGetIsFullscreenMethodName);
  }

  @override
  Future<Offset> get position async {
    ensureHandleAvailable();
    final position = await channel.invokeMethod(
      kGetPositionMethodName,
    );
    return Offset(
      position['dx'] * 1.0,
      position['dy'] * 1.0,
    );
  }

  @override
  Future<Rect> get size async {
    ensureHandleAvailable();
    final size = await channel.invokeMethod(
      kGetSizeMethodName,
    );
    return Rect.fromLTWH(
      size['left'] * 1.0,
      size['top'] * 1.0,
      size['width'] * 1.0,
      size['height'] * 1.0,
    );
  }

  @override
  Future<void> setIsFullscreen(bool enabled) async {
    ensureHandleAvailable();
    await channel.invokeMethod(
      kSetIsFullscreenMethodName,
      {
        'enabled': enabled,
      },
    );
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
  Future<void> maximize() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kMaximizeMethodName);
  }

  @override
  Future<void> restore() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kRestoreMethodName);
  }

  @override
  Future<void> minimize() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kMinimizeMethodName);
  }

  @override
  Future<void> close() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kCloseMethodName);
  }

  @override
  Future<void> destroy() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kDestroyMethodName);
  }

  @override
  Future<void> move(int x, int y) async {
    ensureHandleAvailable();
    await channel.invokeMethod(
      kMoveMethodName,
      {
        'x': x,
        'y': y,
      },
    );
  }

  @override
  Future<void> resize(int width, int height) async {
    ensureHandleAvailable();
    await channel.invokeMethod(
      kResizeMethodName,
      {
        'width': width,
        'height': height,
      },
    );
  }

  @override
  Future<void> hide() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kHideMethodName);
  }

  @override
  Future<void> show() async {
    ensureHandleAvailable();
    await channel.invokeMethod(kShowMethodName);
  }

  @override
  Future<List<Monitor>> get monitors async {
    ensureHandleAvailable();
    final monitors = await channel.invokeMethod(kGetMonitorsMethodName);
    return List<Monitor>.from(
      monitors.map(
        (monitor) => Monitor(
          Rect.fromLTWH(
            monitor['workarea']['left'] * 1.0,
            monitor['workarea']['top'] * 1.0,
            monitor['workarea']['width'] * 1.0,
            monitor['workarea']['height'] * 1.0,
          ),
          Rect.fromLTWH(
            monitor['bounds']['left'] * 1.0,
            monitor['bounds']['top'] * 1.0,
            monitor['bounds']['width'] * 1.0,
            monitor['bounds']['height'] * 1.0,
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
