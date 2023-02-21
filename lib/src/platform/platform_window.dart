// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:ui';
import 'dart:async';
import 'package:meta/meta.dart';

import 'package:window_plus/src/window_state.dart';
import 'package:window_plus/src/models/monitor.dart';

/// An interface to handle the public methods of [WindowPlus].
class PlatformWindow extends WindowState {
  PlatformWindow({
    required super.application,
    required super.enableCustomFrame,
    required super.enableEventStreams,
  });

  /// Whether the window is activated.
  @alwaysThrows
  Future<bool> get activated async {
    throw UnimplementedError();
  }

  /// Whether the window is minimized.
  @alwaysThrows
  Future<bool> get minimized async {
    throw UnimplementedError();
  }

  /// Whether the window is maximized.
  @alwaysThrows
  Future<bool> get maximized async {
    throw UnimplementedError();
  }

  /// Whether the window is fullscreen.
  @alwaysThrows
  Future<bool> get fullscreen async {
    throw UnimplementedError();
  }

  /// Gets the position of the window on the screen.
  @alwaysThrows
  Future<Offset> get position async {
    throw UnimplementedError();
  }

  /// Gets the size of the window on the screen.
  @alwaysThrows
  Future<Rect> get size async {
    throw UnimplementedError();
  }

  /// Gets the minimum size of the window on the screen.
  @alwaysThrows
  Future<Size> get minimumSize async {
    throw UnimplementedError();
  }

  /// Stream to listen to the window's [activated] state.
  Stream<bool> get activatedStream => activatedStreamController.stream;

  StreamController<bool> activatedStreamController =
      StreamController<bool>.broadcast();

  /// Stream to listen to the window's [minimized] state.
  Stream<bool> get minimizedStream => minimizedStreamController.stream;

  StreamController<bool> minimizedStreamController =
      StreamController<bool>.broadcast();

  /// Stream to listen to the window's [maximized] state.
  Stream<bool> get maximizedStream => maximizedStreamController.stream;

  StreamController<bool> maximizedStreamController =
      StreamController<bool>.broadcast();

  /// Stream to listen to the window's [fullscreen] state.
  Stream<bool> get fullscreenStream => fullscreenStreamController.stream;

  StreamController<bool> fullscreenStreamController =
      StreamController<bool>.broadcast();

  /// Stream to listen to the window's [position].
  Stream<Offset> get positionStream => positionStreamController.stream;

  StreamController<Offset> positionStreamController =
      StreamController<Offset>.broadcast();

  /// Stream to listen to the window's [size].
  Stream<Rect> get sizeStream => sizeStreamController.stream;

  StreamController<Rect> sizeStreamController =
      StreamController<Rect>.broadcast();

  /// Sets the window's fullscreen state.
  @alwaysThrows
  Future<void> setFullscreen(bool fullscreen) async {
    throw UnimplementedError();
  }

  /// Sets a function to handle window close events.
  /// This may be used to intercept the close event and perform some actions before closing the window
  /// or prevent window from being closed completely.
  ///
  /// e.g.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await WindowPlus.ensureInitialized(
  ///     application: 'com.alexmercerind.window_plus',
  ///   );
  ///   WindowPlus.instance.setWindowShouldCloseHandler(
  ///     () async {
  ///       if (isSomeOperationInProgress) {
  ///         return false;
  ///       }
  ///       return true;
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// When a user click on the close button on a window, the plug-in redirects
  /// the event to your function. The function should return a future that
  /// returns a boolean to tell the plug-in whether the user really wants to
  /// close the window or not. True will let the window to be closed, while
  /// false let the window to remain open.
  ///
  /// By default there is no handler, and the window will be directly closed
  /// when a window close event happens. You can also reset the handler by
  /// passing null to the method.
  ///
  void setWindowCloseHandler(Future<bool> Function()? value) {
    windowCloseHandler = value;
  }

  /// Sets a function to receive the arguments passed to the application when
  /// single instance is enabled.
  ///
  /// This method gets called when the application is opened with single instance
  /// mode enabled. This may be used to handle the event & receieve the arguments.
  ///
  /// **NOTE:**
  /// Currently only single argument is sent/received.
  /// However, `List<String>` is used to prevent breaking changes in the future.
  ///
  /// e.g.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await WindowPlus.ensureInitialized(
  ///     application: 'com.alexmercerind.window_plus',
  ///   );
  ///   WindowPlus.instance.setSingleInstanceArgumentsHandler(
  ///     (List<String> args) async {
  ///       print(args);
  ///     },
  ///   );
  /// }
  /// ```
  ///
  void setSingleInstanceArgumentsHandler(void Function(List<String>)? value) {
    singleInstanceArgumentsHandler = value;
  }

  /// Enables or disables the fullscreen mode.
  ///
  /// If [enabled] is `true`, the window will be made fullscreen.
  /// Once [enabled] is passed as `false` in future, window will be restored back to it's prior state i.e. maximized or restored at same position & size.
  ///
  @alwaysThrows
  Future<void> setIsFullscreen(bool enabled) async {
    throw UnimplementedError();
  }

  /// Sets the minimum size of the window holding Flutter view.
  @alwaysThrows
  Future<void> setMinimumSize(Size? size) async {
    throw UnimplementedError();
  }

  /// Maximizes the window holding Flutter view.
  @alwaysThrows
  Future<void> maximize() async {
    throw UnimplementedError();
  }

  /// Restores the window holding Flutter view.
  @alwaysThrows
  Future<void> restore() async {
    throw UnimplementedError();
  }

  /// Minimizes the window holding Flutter view.
  @alwaysThrows
  Future<void> minimize() async {
    throw UnimplementedError();
  }

  /// Activates the window holding Flutter view.
  @alwaysThrows
  Future<void> activate() async {
    throw UnimplementedError();
  }

  /// Deactivates the window holding Flutter view.
  @alwaysThrows
  Future<void> deactivate() async {
    throw UnimplementedError();
  }

  /// Closes the window holding Flutter view.
  ///
  /// This method respects the callback set by [setWindowCloseHandler] & saves window state before exit.
  ///
  /// If the set callback returns `false`, the window will not be closed.
  ///
  @alwaysThrows
  Future<void> close() async {
    throw UnimplementedError();
  }

  /// Destroys the window holding Flutter view.
  ///
  /// This method does not respect the callback set by [setWindowCloseHandler] & does not save window state before exit.
  ///
  @alwaysThrows
  Future<void> destroy() async {
    throw UnimplementedError();
  }

  /// Moves (or sets position of the window) holding Flutter view on the screen.
  @alwaysThrows
  Future<void> move(int x, int y) async {
    throw UnimplementedError();
  }

  /// Resizes (or sets size of the window) holding Flutter view on the screen.
  @alwaysThrows
  Future<void> resize(int width, int height) async {
    throw UnimplementedError();
  }

  /// Hides the window holding Flutter view.
  @alwaysThrows
  Future<void> hide() async {
    throw UnimplementedError();
  }

  /// Shows the window holding Flutter view.
  @alwaysThrows
  Future<void> show() async {
    throw UnimplementedError();
  }

  @alwaysThrows
  Future<List<Monitor>> get monitors async {
    throw UnimplementedError();
  }

  @alwaysThrows
  double get captionPadding {
    throw UnimplementedError();
  }

  @alwaysThrows
  double get captionHeight {
    throw UnimplementedError();
  }

  @alwaysThrows
  Size get captionButtonSize {
    throw UnimplementedError();
  }

  /// The method gets called when the window close event happens.
  /// This may be used to intercept the event and prevent the window from closing.
  ///
  Future<bool> Function()? windowCloseHandler;

  /// This method gets called when the application is opened with single instance mode enabled.
  /// This may be used to handle the event and receieve the arguments.
  ///
  /// **NOTE:**
  /// Currently only single argument is sent/received.
  /// However, `List<String>` is used to prevent breaking changes in the future.
  void Function(List<String> arguments)? singleInstanceArgumentsHandler;
}
