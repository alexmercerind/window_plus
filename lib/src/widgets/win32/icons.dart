import 'package:flutter/widgets.dart';

// --------------------------------------------------

class CloseIcon extends StatelessWidget {
  final Color color;

  const CloseIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_ClosePainter(color, context));
}

class _ClosePainter extends _IconPainter {
  _ClosePainter(super.color, super.context);

  @override
  void paint(Canvas canvas, Size size) {
    final p = getPaint(color, context)..isAntiAlias = true;
    canvas.drawLine(const Offset(0.0, 0.0), Offset(size.width, size.height), p);
    canvas.drawLine(Offset(0.0, size.height), Offset(size.width, 0.0), p);
  }
}

// --------------------------------------------------

class MaximizeIcon extends StatelessWidget {
  final Color color;

  const MaximizeIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_MaximizePainter(color, context));
}

class _MaximizePainter extends _IconPainter {
  _MaximizePainter(super.color, super.context);

  @override
  void paint(Canvas canvas, Size size) {
    final p = getPaint(color, context);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }
}

// --------------------------------------------------

class RestoreIcon extends StatelessWidget {
  final Color color;

  const RestoreIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_RestorePainter(color, context));
}

class _RestorePainter extends _IconPainter {
  _RestorePainter(super.color, super.context);

  @override
  void paint(Canvas canvas, Size size) {
    final p = getPaint(color, context);
    canvas.drawRect(Rect.fromLTRB(0.0, 2.0, size.width - 2.0, size.height), p);
    canvas.drawLine(const Offset(2.0, 2.0), const Offset(2.0, 0.0), p);
    canvas.drawLine(const Offset(2.0, 0.0), Offset(size.width, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height - 2.0), p);
    canvas.drawLine(Offset(size.width, size.height - 2.0), Offset(size.width - 2.0, size.height - 2.0), p);
  }
}

// --------------------------------------------------

class MinimizeIcon extends StatelessWidget {
  final Color color;

  const MinimizeIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_MinimizePainter(color, context));
}

class _MinimizePainter extends _IconPainter {
  _MinimizePainter(super.color, super.context);

  @override
  void paint(Canvas canvas, Size size) {
    final p = getPaint(color, context);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }
}

// --------------------------------------------------

abstract class _IconPainter extends CustomPainter {
  final Color color;
  final BuildContext context;

  _IconPainter(this.color, this.context);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  final CustomPainter painter;

  const _AlignedPaint(this.painter);

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

Paint getPaint(Color color, BuildContext context, [bool isAntiAlias = false]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..isAntiAlias = isAntiAlias
  ..strokeWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
