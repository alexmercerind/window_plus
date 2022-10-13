// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/widgets.dart';

class CloseIcon extends StatelessWidget {
  final Color color;
  const CloseIcon({
    Key? key,
    required this.color,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => _AlignedPaint(_ClosePainter(color));
}

class _ClosePainter extends _IconPainter {
  _ClosePainter(Color color) : super(color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color)..isAntiAlias = true;
    canvas.drawLine(
      const Offset(0.0, 0.0),
      Offset(
        size.width,
        size.height,
      ),
      p,
    );
    canvas.drawLine(
      Offset(
        0.0,
        size.height,
      ),
      Offset(
        size.width,
        0.0,
      ),
      p,
    );
  }
}

class MaximizeIcon extends StatelessWidget {
  final Color color;
  const MaximizeIcon({
    Key? key,
    required this.color,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MaximizePainter(color));
}

class _MaximizePainter extends _IconPainter {
  _MaximizePainter(Color color) : super(color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }
}

class RestoreIcon extends StatelessWidget {
  final Color color;
  const RestoreIcon({
    Key? key,
    required this.color,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => _AlignedPaint(_RestorePainter(color));
}

class _RestorePainter extends _IconPainter {
  _RestorePainter(Color color) : super(color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(
      Rect.fromLTRB(
        0.0,
        2.0,
        size.width - 2.0,
        size.height,
      ),
      p,
    );
    canvas.drawLine(
      const Offset(
        2.0,
        2.0,
      ),
      const Offset(
        2.0,
        0.0,
      ),
      p,
    );
    canvas.drawLine(
      const Offset(
        2.0,
        0.0,
      ),
      Offset(
        size.width,
        0,
      ),
      p,
    );
    canvas.drawLine(
      Offset(
        size.width,
        0,
      ),
      Offset(
        size.width,
        size.height - 2.0,
      ),
      p,
    );
    canvas.drawLine(
      Offset(
        size.width,
        size.height - 2.0,
      ),
      Offset(
        size.width - 2.0,
        size.height - 2.0,
      ),
      p,
    );
  }
}

class MinimizeIcon extends StatelessWidget {
  final Color color;
  const MinimizeIcon({
    Key? key,
    required this.color,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MinimizePainter(color));
}

class _MinimizePainter extends _IconPainter {
  _MinimizePainter(Color color) : super(color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawLine(
      Offset(
        0,
        size.height / 2,
      ),
      Offset(
        size.width,
        size.height / 2,
      ),
      p,
    );
  }
}

abstract class _IconPainter extends CustomPainter {
  _IconPainter(this.color);
  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  const _AlignedPaint(this.painter, {Key? key}) : super(key: key);
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(10.0, 10.0),
        painter: painter,
      ),
    );
  }
}

Paint getPaint(Color color, [bool isAntiAlias = false]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..isAntiAlias = isAntiAlias
  ..strokeWidth = 1.0 / window.devicePixelRatio;
