// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:io';

import 'package:flutter/material.dart';

import 'macos/widgets.dart' as macos;
import 'win32/widgets.dart' as win32;

class WindowCaption extends StatelessWidget {
  final Widget? child;
  final Brightness? brightness;

  WindowCaption({super.key, this.child, this.brightness});

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return macos.WindowCaption(brightness: brightness, child: child);
    }
    if (Platform.isWindows) {
      return win32.WindowCaption(brightness: brightness, child: child);
    }
    return const SizedBox.shrink();
  }
}
