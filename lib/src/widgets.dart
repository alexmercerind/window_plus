import 'package:win32/win32.dart';
import 'package:flutter/material.dart';

import 'package:window_plus/src/native.dart';
import 'package:window_plus/src/common.dart';

/// A widget that is used to draw the draggable area of the window i.e. title bar.
/// Any click event on this widget will result in window being dragged by the user.
///
/// [WindowPlus.captionHeight] may be used to retrieve the height of the caption area.
///
class WindowCaptionArea extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;

  const WindowCaptionArea({
    Key? key,
    this.child,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (e) {
        assert(WindowPlus.instance.hwnd != 0);
        SendMessage(
          WindowPlus.instance.hwnd,
          WM_CAPTIONAREA,
          0,
          0,
        );
      },
      child: Container(
        color: Colors.transparent,
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}
