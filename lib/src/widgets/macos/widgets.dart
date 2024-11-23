// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:window_plus/src/window_plus.dart';

class WindowCaption extends StatelessWidget {
  final Widget? child;
  final Brightness? brightness;
  WindowCaption({super.key, this.child, this.brightness});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: WindowPlus.instance.fullscreen,
      builder: (context, snapshot) {
        return snapshot.data == true
            ? SizedBox(
                width: double.infinity,
                height: WindowPlus.instance.captionHeight,
              )
            : SizedBox(
                width: double.infinity,
                height: WindowPlus.instance.captionHeight,
                child: Theme(
                  data: Theme.of(context).copyWith(brightness: brightness),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: child ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              );
      },
    );
  }
}
