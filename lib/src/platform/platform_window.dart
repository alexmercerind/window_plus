import 'dart:ui';
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:window_plus/src/window_state.dart';
import 'package:window_plus/src/models/monitor.dart';

class PlatformWindow extends WindowState {
  PlatformWindow({
    required super.application,
    required super.enableCustomFrame,
    required super.enableEventStreams,
  });

  Future<bool> get activated async {
    throw UnimplementedError();
  }

  Future<bool> get minimized async {
    throw UnimplementedError();
  }

  Future<bool> get maximized async {
    throw UnimplementedError();
  }

  Future<bool> get fullscreen async {
    throw UnimplementedError();
  }

  Future<Offset> get position async {
    throw UnimplementedError();
  }

  Future<Rect> get size async {
    throw UnimplementedError();
  }

  Future<bool> get alwaysOnTop async {
    throw UnimplementedError();
  }

  Future<Size> get minimumSize async {
    throw UnimplementedError();
  }

  Stream<bool> get activatedStream => activatedStreamController.stream;

  Stream<bool> get minimizedStream => minimizedStreamController.stream;

  Stream<bool> get maximizedStream => maximizedStreamController.stream;

  Stream<bool> get fullscreenStream => fullscreenStreamController.stream;

  Stream<Offset> get positionStream => positionStreamController.stream;

  Stream<Rect> get sizeStream => sizeStreamController.stream;

  void setWindowCloseHandler(Future<bool> Function()? value) {
    windowCloseHandler = value;
  }

  void setSingleInstanceArgumentsHandler(void Function(List<String>)? value) {
    singleInstanceArgumentsHandler = value;
  }

  Future<void> setIsAlwaysOnTop(bool enabled) async {
    throw UnimplementedError();
  }

  Future<void> setIsFullscreen(bool enabled) async {
    throw UnimplementedError();
  }

  Future<void> setMinimumSize(Size? size) async {
    throw UnimplementedError();
  }

  Future<void> maximize() async {
    throw UnimplementedError();
  }

  Future<void> restore() async {
    throw UnimplementedError();
  }

  Future<void> minimize() async {
    throw UnimplementedError();
  }

  Future<void> activate() async {
    throw UnimplementedError();
  }

  Future<void> deactivate() async {
    throw UnimplementedError();
  }

  Future<void> close() async {
    throw UnimplementedError();
  }

  Future<void> destroy() async {
    throw UnimplementedError();
  }

  Future<void> move(int x, int y) async {
    throw UnimplementedError();
  }

  Future<void> resize(int width, int height) async {
    throw UnimplementedError();
  }

  Future<void> hide() async {
    throw UnimplementedError();
  }

  Future<void> show() async {
    throw UnimplementedError();
  }

  Future<List<Monitor>> get monitors async {
    throw UnimplementedError();
  }

  double get captionPadding {
    throw UnimplementedError();
  }

  double get captionHeight {
    throw UnimplementedError();
  }

  Size get captionButtonSize {
    throw UnimplementedError();
  }

  @protected
  Future<bool> Function()? windowCloseHandler;

  @protected
  void Function(List<String> arguments)? singleInstanceArgumentsHandler;

  @protected
  StreamController<bool> activatedStreamController = StreamController<bool>.broadcast();

  @protected
  StreamController<bool> minimizedStreamController = StreamController<bool>.broadcast();

  @protected
  StreamController<bool> maximizedStreamController = StreamController<bool>.broadcast();

  @protected
  StreamController<bool> fullscreenStreamController = StreamController<bool>.broadcast();

  @protected
  StreamController<Offset> positionStreamController = StreamController<Offset>.broadcast();

  @protected
  StreamController<Rect> sizeStreamController = StreamController<Rect>.broadcast();
}
