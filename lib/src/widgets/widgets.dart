// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:win32/win32.dart';
import 'package:flutter/material.dart';

import 'package:window_plus/src/common.dart';
import 'package:window_plus/src/window_plus.dart';
import 'package:window_plus/src/widgets/utils.dart';
import 'package:window_plus/src/widgets/icons.dart';
import 'package:window_plus/src/utils/windows_info.dart';

/// A widget that is used to draw the draggable area of the window i.e. title bar.
/// Any click event on this widget will result in window being dragged by the user.
///
/// [WindowPlus.captionHeight] may be used to retrieve the height of the caption area.
///
class WindowCaptionArea extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;

  // Force re-rendering when the window DPI is changed.
  // ignore: prefer_const_constructors_in_immutables
  WindowCaptionArea({
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
        assert(WindowPlus.instance.hwnd > 0);
        PostMessage(
          WindowPlus.instance.hwnd,
          WM_CAPTIONAREA,
          0,
          0,
        );
      },
      onDoubleTap: () {
        assert(WindowPlus.instance.hwnd > 0);
        if (IsZoomed(WindowPlus.instance.hwnd) != 0) {
          WindowPlus.instance.restore();
        } else {
          WindowPlus.instance.maximize();
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

  // Force re-rendering when the window DPI is changed.
  // ignore: prefer_const_constructors_in_immutables
  WindowButton({
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
            getBackgroundColor(MouseState()..isMouseOver = true)
                .withOpacity(0.0);
        final padding = this.padding ?? EdgeInsets.all(defaultPadding);
        final child = Padding(
          padding: padding,
          child: icon,
        );
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

  // Force re-rendering when the window DPI is changed.
  // ignore: prefer_const_constructors_in_immutables
  WindowMinimizeButton({
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
      onPressed: onPressed ?? WindowPlus.instance.minimize,
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
      onPressed: onPressed ?? WindowPlus.instance.maximize,
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
      onPressed: onPressed ?? WindowPlus.instance.restore,
    );
  }
}

class WindowCloseButton extends StatelessWidget {
  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  // Force re-rendering when the window DPI is changed.
  // ignore: prefer_const_constructors_in_immutables
  WindowCloseButton({
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
      onPressed: onPressed ?? WindowPlus.instance.close,
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
    return IsZoomed(WindowPlus.instance.hwnd) != 0
        ? WindowRestoreButton(
            colors: colors,
            onPressed: onPressed,
            animate: animate,
          )
        : WindowMaximizeButton(
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

class WindowCaption extends StatefulWidget {
  final Widget? child;
  final Brightness? brightness;
  // Force re-rendering when the window is maximized or restored.
  // ignore: prefer_const_constructors_in_immutables
  WindowCaption({
    Key? key,
    this.child,
    this.brightness,
  }) : super(key: key);

  @override
  State<WindowCaption> createState() => _WindowCaptionState();
}

class _WindowCaptionState extends State<WindowCaption> {
  @override
  Widget build(BuildContext context) {
    final style = GetWindowLongPtr(WindowPlus.instance.hwnd, GWL_STYLE);
    final fullscreen = !(style & WS_OVERLAPPEDWINDOW > 0);
    return fullscreen
        ? SizedBox(
            width: double.infinity,
            height: WindowPlus.instance.captionHeight,
          )
        : SizedBox(
            width: double.infinity,
            height: WindowPlus.instance.captionHeight,
            child: Theme(
              data: Theme.of(context).copyWith(brightness: widget.brightness),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: WindowCaptionArea(
                      height: WindowPlus.instance.captionHeight,
                      child: widget.child,
                    ),
                  ),
                  WindowMinimizeButton(),
                  WindowRestoreMaximizeButton(),
                  WindowCloseButton(),
                ],
              ),
            ),
          );
  }
}
