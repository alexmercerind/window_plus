import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/material.dart';

import 'package:window_plus/src/utils.dart';
import 'package:window_plus/src/icons.dart';
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
      behavior: HitTestBehavior.translucent,
      onPanStart: (e) {
        assert(WindowPlus.instance.hwnd != 0);
        SendMessage(
          WindowPlus.instance.hwnd,
          WM_CAPTIONAREA,
          0,
          0,
        );
      },
      onDoubleTap: () {
        assert(WindowPlus.instance.hwnd != 0);
        if (IsZoomed(WindowPlus.instance.hwnd) == 0) {
          SendMessage(
            WindowPlus.instance.hwnd,
            WM_SYSCOMMAND,
            SC_MAXIMIZE,
            0,
          );
        } else {
          SendMessage(
            WindowPlus.instance.hwnd,
            WM_SYSCOMMAND,
            SC_RESTORE,
            0,
          );
        }
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

class WindowButton extends StatelessWidget {
  final WindowButtonBuilder? builder;
  final WindowButtonIconBuilder? iconBuilder;
  final WindowButtonColors colors;
  final bool animate;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;

  const WindowButton({
    Key? key,
    required this.colors,
    this.builder,
    this.iconBuilder,
    this.padding,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  Color getBackgroundColor(MouseState state) {
    if (state.isMouseDown) return colors.mouseDown;
    if (state.isMouseOver) return colors.mouseOver;
    return colors.normal;
  }

  Color getIconColor(MouseState state) {
    if (state.isMouseDown) return colors.iconMouseDown;
    if (state.isMouseOver) return colors.iconMouseOver;
    return colors.iconNormal;
  }

  @override
  Widget build(BuildContext context) {
    return MouseStateBuilder(
      builder: (context, state) {
        final button = WindowButtonContext(
          state: state,
          context: context,
          backgroundColor: getBackgroundColor(state),
          iconColor: getIconColor(state),
        );
        final icon = iconBuilder?.call(button) ?? Container();
        final borderSize = WindowPlus.instance.captionPadding;
        double defaultPadding =
            (WindowPlus.instance.captionHeight - borderSize) / 3 -
                (borderSize / 2);
        final fadeOutColor =
            getBackgroundColor(MouseState()..isMouseOver = true).withOpacity(0);
        final padding = this.padding ?? EdgeInsets.all(defaultPadding);
        final child = Padding(padding: padding, child: icon);
        return AnimatedContainer(
          curve: Curves.easeOut,
          duration: Duration(
            milliseconds:
                state.isMouseOver ? (animate ? 100 : 0) : (animate ? 200 : 0),
          ),
          color: button.backgroundColor ?? fadeOutColor,
          width: WindowPlus.instance.captionButtonSize.width,
          height: WindowPlus.instance.captionButtonSize.height,
          child: child,
        );
      },
      onPressed: onPressed,
    );
  }
}

class WindowMinimizeButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  const WindowMinimizeButton({
    Key? key,
    this.colors,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = this.colors ??
        WindowButtonColors(
          iconNormal: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          normal: Colors.transparent,
          mouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.04)
              : const Color(0xFF000000).withOpacity(0.04),
          mouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.08)
              : const Color(0xFF000000).withOpacity(0.08),
        );
    return WindowButton(
      key: key,
      colors: colors,
      animate: animate,
      iconBuilder: (buttonContext) => MinimizeIcon(
        color: buttonContext.iconColor,
      ),
      onPressed: onPressed ??
          () {
            PostMessage(
              WindowPlus.instance.hwnd,
              WM_SYSCOMMAND,
              SC_MINIMIZE,
              0,
            );
          },
    );
  }
}

class WindowMaximizeButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  const WindowMaximizeButton({
    Key? key,
    this.colors,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = this.colors ??
        WindowButtonColors(
          iconNormal: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          normal: Colors.transparent,
          mouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.04)
              : const Color(0xFF000000).withOpacity(0.04),
          mouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.08)
              : const Color(0xFF000000).withOpacity(0.08),
        );
    return WindowButton(
      key: key,
      colors: colors,
      animate: animate,
      iconBuilder: (buttonContext) => MaximizeIcon(
        color: buttonContext.iconColor,
      ),
      onPressed: onPressed ??
          () {
            PostMessage(
              WindowPlus.instance.hwnd,
              WM_SYSCOMMAND,
              SC_MAXIMIZE,
              0,
            );
          },
    );
  }
}

class WindowRestoreButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  const WindowRestoreButton({
    Key? key,
    this.colors,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = this.colors ??
        WindowButtonColors(
          iconNormal: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          normal: Colors.transparent,
          mouseOver: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.04)
              : const Color(0xFF000000).withOpacity(0.04),
          mouseDown: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF).withOpacity(0.08)
              : const Color(0xFF000000).withOpacity(0.08),
        );
    return WindowButton(
      key: key,
      colors: colors,
      animate: animate,
      iconBuilder: (buttonContext) => RestoreIcon(
        color: buttonContext.iconColor,
      ),
      onPressed: onPressed ??
          () {
            PostMessage(
              WindowPlus.instance.hwnd,
              WM_SYSCOMMAND,
              SC_RESTORE,
              0,
            );
          },
    );
  }
}

class WindowCloseButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  const WindowCloseButton({
    Key? key,
    this.colors,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = this.colors ??
        WindowButtonColors(
          iconNormal: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
          iconMouseDown: const Color(0xFFFFFFFF),
          iconMouseOver: const Color(0xFFFFFFFF),
          normal: const Color(0x00000000),
          mouseOver: const Color(0xFFC42B1C),
          mouseDown: const Color(0xFFC83F31),
        );
    return WindowButton(
      key: key,
      colors: colors,
      animate: animate,
      iconBuilder: (buttonContext) => CloseIcon(
        color: buttonContext.iconColor,
      ),
      onPressed: onPressed ??
          () {
            PostMessage(
              WindowPlus.instance.hwnd,
              WM_SYSCOMMAND,
              SC_CLOSE,
              0,
            );
          },
    );
  }
}

class WindowRestoreMaximizeButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  // Force re-rendering when the window is maximized or restored.
  // ignore: prefer_const_constructors_in_immutables
  WindowRestoreMaximizeButton({
    Key? key,
    this.colors,
    this.onPressed,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IsZoomed(WindowPlus.instance.hwnd) == 0
        ? WindowMaximizeButton(
            colors: colors,
            onPressed: onPressed,
            animate: animate,
          )
        : WindowRestoreButton(
            colors: colors,
            onPressed: onPressed,
            animate: animate,
          );
  }
}

class MouseStateBuilder extends StatefulWidget {
  final MouseStateBuilderCallback builder;
  final VoidCallback? onPressed;
  const MouseStateBuilder({
    Key? key,
    required this.builder,
    required this.onPressed,
  }) : super(key: key);
  @override
  MouseStateBuilderState createState() => MouseStateBuilderState();
}

class MouseStateBuilderState extends State<MouseStateBuilder> {
  final MouseState state = MouseState();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          state.isMouseOver = true;
        });
      },
      onExit: (e) {
        setState(() {
          state.isMouseOver = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            state.isMouseDown = true;
          });
        },
        onTapCancel: () {
          setState(() {
            state.isMouseDown = false;
          });
        },
        onTap: () {
          setState(() {
            state.isMouseDown = false;
            state.isMouseOver = false;
          });
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              widget.onPressed?.call();
            },
          );
        },
        onTapUp: (_) {},
        child: widget.builder(
          context,
          state,
        ),
      ),
    );
  }
}
