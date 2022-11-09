// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';

/// A monitor is a physical display device.
class Monitor {
  /// The work area of the monitor i.e. resolution excluding the taskbar & other toolbars.
  final Rect workarea;

  /// The bounds of the monitor i.e. resolution including the taskbar & other toolbars.
  final Rect bounds;

  Monitor(
    this.workarea,
    this.bounds,
  );

  @override
  String toString() {
    return 'Monitor(workarea: $workarea, bounds: $bounds)';
  }
}
