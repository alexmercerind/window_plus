// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:flutter/services.dart';

/// Holds the current window state attributes e.g. minimized, maximized, fullscreen, position, size, etc.
class PlatformWindowState {
  /// Whether the window is minimized.
  bool minimized;

  /// Whether the window is maximized.
  bool maximized;

  /// Whether the window is fullscreen.
  bool fullscreen;

  /// Position of the window on the screen.
  Offset position;

  /// Size of the window.
  Rect size;

  PlatformWindowState({
    this.minimized = false,
    this.maximized = false,
    this.fullscreen = false,
    this.position = Offset.zero,
    this.size = Rect.zero,
  });
}
