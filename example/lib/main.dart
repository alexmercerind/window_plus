import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WindowPlus.setWindowCloseHandler(() async {
    debugPrint('[WindowPlus.setWindowCloseHandler]');
    return true;
  });
  await WindowPlus.ensureInitialized(
    application: 'com.alexmercerind.window_plus',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode theme = ThemeMode.light;
  bool fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: theme,
      home: LayoutBuilder(
        builder: (context, _) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WindowCaption(),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          theme == ThemeMode.dark
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                        ),
                        onPressed: () {
                          setState(() {
                            theme = theme == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                          });
                        },
                      ),
                      const SizedBox(width: 16.0),
                      IconButton(
                        icon: Icon(
                          fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        ),
                        onPressed: () {
                          setState(() {
                            fullscreen = !fullscreen;
                          });
                          WindowPlus.instance.setIsFullscreen(fullscreen);
                        },
                      ),
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
