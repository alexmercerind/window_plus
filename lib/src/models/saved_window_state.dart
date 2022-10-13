// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

class SavedWindowState {
  final int x;
  final int y;
  final int width;
  final int height;
  final bool maximized;

  const SavedWindowState(
    this.x,
    this.y,
    this.width,
    this.height,
    this.maximized,
  );

  factory SavedWindowState.fromJson(dynamic json) {
    return SavedWindowState(
      json['x'],
      json['y'],
      json['width'],
      json['height'],
      json['maximized'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'maximized': maximized,
    };
  }

  @override
  String toString() {
    return 'SavedWindowState(x: $x, y: $y, width: $width, height: $height, maximized: $maximized)';
  }

  SavedWindowState copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    bool? maximized,
  }) {
    return SavedWindowState(
      x ?? this.x,
      y ?? this.y,
      width ?? this.width,
      height ?? this.height,
      maximized ?? this.maximized,
    );
  }
}
