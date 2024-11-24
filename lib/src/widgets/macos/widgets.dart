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
            : GestureDetector(
                onDoubleTap: () async {
                  if (await WindowPlus.instance.maximized) {
                    await WindowPlus.instance.restore();
                  } else {
                    await WindowPlus.instance.maximize();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: WindowPlus.instance.captionHeight,
                ),
              );
      },
    );
  }
}
