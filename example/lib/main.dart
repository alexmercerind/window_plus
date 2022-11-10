import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowPlus.ensureInitialized(
    application: 'com.alexmercerind.window_plus',
  );
  WindowPlus.instance.setWindowCloseHandler(() async {
    bool result = false;
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Exit'),
        content: const Text('Do you want to close the window?'),
        actions: [
          TextButton(
            onPressed: () {
              result = true;
              Navigator.of(context).maybePop();
            },
            child: const Text('YES'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Text('NO'),
          ),
        ],
      ),
    );
    return result;
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> singleInstanceArguments = <String>[];

  @override
  void initState() {
    super.initState();
    WindowPlus.instance.setSingleInstanceArgumentsHandler((arguments) {
      setState(() {
        singleInstanceArguments = arguments;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF6200EA),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF1DE9B6),
          onSecondary: Color(0xFF000000),
          error: Color(0xFFFF0000),
          onError: Color(0xFFFFFFFF),
          background: Color(0xFFFFFFFF),
          onBackground: Color(0xFF000000),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
        ),
      ),
      home: LayoutBuilder(
        builder: (context, _) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => launchUrl(
                Uri.https(
                  'github.com',
                  '/sponsors/alexmercerind',
                ),
              ),
              backgroundColor: Colors.pink.shade50,
              foregroundColor: Colors.pink.shade400,
              tooltip: 'Sponsor',
              child: const Icon(
                Icons.favorite,
              ),
            ),
            body: Stack(
              alignment: Alignment.topCenter,
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text('package:window_plus'),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 64.0),
                          height: 200.0,
                          width: MediaQuery.of(context).size.width,
                          child: Transform.translate(
                            offset: const Offset(-156.0, -96.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.window,
                                  size: 256.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 32.0),
                                Icon(
                                  Icons.desktop_windows,
                                  size: 256.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      elevation: 4.0,
                      collapsedHeight: 72.0,
                      expandedHeight: 200.0,
                      pinned: true,
                      floating: true,
                      snap: false,
                      forceElevated: true,
                      bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(kToolbarHeight),
                        child: SizedBox.shrink(),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate.fixed(
                        [
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: WindowPlus.instance.minimize,
                                child: const Text('MINIMIZE'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.maximize,
                                child: const Text('MAXIMIZE'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.restore,
                                child: const Text('RESTORE'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.close,
                                child: const Text('CLOSE'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.destroy,
                                child: const Text('DESTROY'),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'hwnd: ${WindowPlus.instance.hwnd}',
                                  ),
                                  Text(
                                    'captionHeight: ${WindowPlus.instance.captionHeight}',
                                  ),
                                  Text(
                                    'captionButtonSize: ${WindowPlus.instance.captionButtonSize}',
                                  ),
                                  Text(
                                    'captionPadding: ${WindowPlus.instance.captionPadding}',
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'minimizedStream: null',
                                              )
                                            : Text(
                                                'minimizedStream: ${snapshot.data.toString()}',
                                              ),
                                    stream: WindowPlus.instance.minimizedStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'maximizedStream: null',
                                              )
                                            : Text(
                                                'maximizedStream: ${snapshot.data.toString()}',
                                              ),
                                    stream: WindowPlus.instance.maximizedStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'fullscreenStream: null',
                                              )
                                            : Text(
                                                'fullscreenStream: ${snapshot.data.toString()}',
                                              ),
                                    stream:
                                        WindowPlus.instance.fullscreenStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) =>
                                        snapshot.hasData
                                            ? Text(
                                                'sizeStream: ${snapshot.data.toString()}',
                                              )
                                            : const Text(
                                                'sizeStream: null',
                                              ),
                                    stream: WindowPlus.instance.sizeStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'positionStream: null',
                                              )
                                            : Text(
                                                'positionStream: ${snapshot.data.toString()}',
                                              ),
                                    stream: WindowPlus.instance.positionStream,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'minimized: null',
                                              )
                                            : Text(
                                                'minimized: ${snapshot.data.toString()}',
                                              ),
                                    future: WindowPlus.instance.minimized,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'maximized: null',
                                              )
                                            : Text(
                                                'maximized: ${snapshot.data.toString()}',
                                              ),
                                    future: WindowPlus.instance.maximized,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'fullscreen: null',
                                              )
                                            : Text(
                                                'fullscreen: ${snapshot.data.toString()}',
                                              ),
                                    future: WindowPlus.instance.fullscreen,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'size: null',
                                              )
                                            : Text(
                                                'size: ${snapshot.data.toString()}',
                                              ),
                                    future: WindowPlus.instance.size,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'position: null',
                                              )
                                            : Text(
                                                'position: ${snapshot.data.toString()}',
                                              ),
                                    future: WindowPlus.instance.position,
                                  ),
                                  FutureBuilder(
                                    future:
                                        WindowPlus.instance.savedWindowState,
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'savedWindowState: null',
                                              )
                                            : Text(
                                                'savedWindowState: ${snapshot.data.toString()}',
                                              ),
                                  ),
                                  FutureBuilder(
                                    future: WindowPlus.instance.monitors,
                                    builder: (context, snapshot) =>
                                        !snapshot.hasData
                                            ? const Text(
                                                'monitors: null',
                                              )
                                            : Text(
                                                'monitors: ${snapshot.data.toString()}',
                                              ),
                                  ),
                                  Text(
                                    'singleInstanceArguments: $singleInstanceArguments',
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  WindowPlus.instance.hide();
                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );
                                  WindowPlus.instance.show();
                                },
                                child: const Text('HIDE'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.show,
                                child: const Text('SHOW'),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              const SizedBox(
                                width: 156.0,
                                child: Text('Window movement :'),
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final position =
                                      await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1 - 10,
                                    position.dy ~/ 1,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final position =
                                      await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1 + 10,
                                    position.dy ~/ 1,
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final position =
                                      await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1,
                                    position.dy ~/ 1 - 10,
                                  );
                                },
                                icon: const Icon(Icons.arrow_upward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final position =
                                      await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1,
                                    position.dy ~/ 1 + 10,
                                  );
                                },
                                icon: const Icon(Icons.arrow_downward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              const SizedBox(
                                width: 156.0,
                                child: Text('Window resize :'),
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1 - 10,
                                    size.height ~/ 1,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1 + 10,
                                    size.height ~/ 1,
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1,
                                    size.height ~/ 1 - 10,
                                  );
                                },
                                icon: const Icon(Icons.arrow_upward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1,
                                    size.height ~/ 1 + 10,
                                  );
                                },
                                icon: const Icon(Icons.arrow_downward),
                                splashRadius: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 200.0 - 28.0,
                  right: 32.0,
                  child: FutureBuilder<bool>(
                    future: WindowPlus.instance.fullscreen,
                    builder: (context, snapshot) => !snapshot.hasData
                        ? FloatingActionButton(
                            onPressed: () {},
                          )
                        : FloatingActionButton(
                            tooltip: snapshot.data!
                                ? 'Exit Fullscreen'
                                : 'Enter Fullscreen',
                            onPressed: () {
                              WindowPlus.instance
                                  .setIsFullscreen(!snapshot.data!);
                            },
                            child: Icon(
                              snapshot.data!
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                            ),
                          ),
                  ),
                ),
                WindowCaption(
                  brightness: Brightness.dark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
