import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/models/monitor.dart';
import 'package:window_plus/src/platform/platform_window.dart';

class NSWindow extends PlatformWindow {
  NSWindow({
    required super.application,
    required super.enableCustomFrame,
    required super.enableEventStreams,
  });

  @override
  Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
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
  Future<void> ensureInitialized() async {
    await super.ensureInitialized();
    _captionHeightValue = await channel.invokeMethod(kGetCaptionHeight);
  }

  @override
  Future<bool> get activated async {
    throw UnimplementedError();
  }

  @override
  Future<bool> get minimized async {
    throw UnimplementedError();
  }

  @override
  Future<bool> get maximized async {
    return await channel.invokeMethod(kGetIsMaximizedMethodName);
  }

  @override
  Future<bool> get fullscreen async {
    return await channel.invokeMethod(kGetIsFullscreenMethodName);
  }

  @override
  Future<Offset> get position async {
    throw UnimplementedError();
  }

  @override
  Future<Rect> get size async {
    throw UnimplementedError();
  }

  @override
  Future<bool> get alwaysOnTop async {
    throw UnimplementedError();
  }

  @override
  Future<Size> get minimumSize async {
    throw UnimplementedError();
  }

  @override
  Future<void> setIsFullscreen(bool enabled) async {
    await channel.invokeMethod(
      kSetIsFullscreenMethodName,
      {
        'enabled': enabled,
      },
    );
  }

  @override
  Future<void> setMinimumSize(Size? size) async {
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
    await channel.invokeMethod(kMaximizeMethodName);
  }

  @override
  Future<void> restore() async {
    await channel.invokeMethod(kRestoreMethodName);
  }

  @override
  Future<void> minimize() async {
    throw UnimplementedError();
  }

  @override
  Future<void> activate() async {
    throw UnimplementedError();
  }

  @override
  Future<void> deactivate() async {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    await channel.invokeMethod(kCloseMethodName);
  }

  @override
  Future<void> destroy() async {
    await channel.invokeMethod(kDestroyMethodName);
  }

  @override
  Future<void> move(int x, int y) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resize(int width, int height) async {
    throw UnimplementedError();
  }

  @override
  Future<void> hide() async {
    throw UnimplementedError();
  }

  @override
  Future<void> show() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Monitor>> get monitors async {
    throw UnimplementedError();
  }

  @override
  double get captionPadding {
    return 0.0;
  }

  @override
  double get captionHeight {
    return _captionHeightValue;
  }

  @override
  Size get captionButtonSize {
    return Size.zero;
  }

  double _captionHeightValue = 0.0;
}
