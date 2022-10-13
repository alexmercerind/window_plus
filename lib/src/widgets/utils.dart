// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

typedef WindowButtonIconBuilder = Widget Function(
  WindowButtonContext context,
);
typedef WindowButtonBuilder = Widget Function(
  WindowButtonContext context,
  Widget icon,
);
typedef MouseStateBuilderCallback = Widget Function(
  BuildContext context,
  MouseState state,
);

class MouseState {
  bool isMouseOver = false;
  bool isMouseDown = false;

  MouseState();
}

class WindowButtonContext {
  final BuildContext context;
  final MouseState state;
  final Color? backgroundColor;
  final Color iconColor;
  const WindowButtonContext({
    required this.context,
    required this.state,
    required this.iconColor,
    this.backgroundColor,
  });
}

class WindowButtonColors {
  final Color normal;
  final Color mouseOver;
  final Color mouseDown;
  final Color iconNormal;
  final Color iconMouseOver;
  final Color iconMouseDown;
  const WindowButtonColors({
    required this.normal,
    required this.mouseOver,
    required this.mouseDown,
    required this.iconNormal,
    required this.iconMouseOver,
    required this.iconMouseDown,
  });
}
