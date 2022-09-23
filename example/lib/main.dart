import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowPlus.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayoutBuilder(
        builder: (context, _) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: WindowPlus.instance.captionHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: WindowCaptionArea(),
                      ),
                      const WindowMinimizeButton(),
                      WindowRestoreMaximizeButton(),
                      const WindowCloseButton(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
