import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowPlus.ensureInitialized(
    application: 'com.alexmercerind.window_plus',
  );
  await WindowPlus.instance.setMinimumSize(const Size(800, 600));
  WindowPlus.instance.setWindowCloseHandler(() async {
    bool result = false;
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('exit'),
        content: const Text(
          'do you want to close the window?',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = true;
              Navigator.of(context).maybePop();
            },
            child: const Text('yes'),
          ),
          TextButton(
            onPressed: Navigator.of(context).maybePop,
            child: const Text('no'),
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
      home: LayoutBuilder(
        builder: (context, _) {
          return Scaffold(
            floatingActionButton: FutureBuilder<bool>(
              future: WindowPlus.instance.fullscreen,
              builder: (context, snapshot) => !snapshot.hasData
                  ? FloatingActionButton(
                      onPressed: () {},
                    )
                  : FloatingActionButton(
                      tooltip: snapshot.data! ? 'exit fullscreen' : 'enter fullscreen',
                      onPressed: () {
                        WindowPlus.instance.setIsFullscreen(!snapshot.data!);
                      },
                      child: Icon(
                        snapshot.data! ? Icons.fullscreen_exit : Icons.fullscreen,
                      ),
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
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                Icon(
                                  Icons.window_outlined,
                                  size: 256.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 32.0),
                                Icon(
                                  Icons.desktop_windows_outlined,
                                  size: 256.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      elevation: 4.0,
                      expandedHeight: 200.0,
                      collapsedHeight: 200.0,
                      forceElevated: true,
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate.fixed(
                        [
                          const SizedBox(height: 16.0),
                          Wrap(
                            children: [
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: WindowPlus.instance.activate,
                                child: const Text('activate'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.deactivate,
                                child: const Text('deactivate'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.minimize,
                                child: const Text('minimize'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.maximize,
                                child: const Text('maximize'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.restore,
                                child: const Text('restore'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.close,
                                child: const Text('close'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.destroy,
                                child: const Text('destroy'),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Wrap(
                            children: [
                              const SizedBox(width: 32.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'handle: ${WindowPlus.instance.handle}',
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
                                    builder: (context, snapshot) => Text(
                                      'activatedStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.activatedStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) => Text(
                                      'minimizedStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.minimizedStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) => Text(
                                      'maximizedStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.maximizedStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) => Text(
                                      'fullscreenStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.fullscreenStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) => Text(
                                      'sizeStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.sizeStream,
                                  ),
                                  StreamBuilder(
                                    builder: (context, snapshot) => Text(
                                      'positionStream: ${snapshot.data}',
                                    ),
                                    stream: WindowPlus.instance.positionStream,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'activated: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.activated,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'minimized: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.minimized,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'maximized: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.maximized,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'fullscreen: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.fullscreen,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'size: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.size,
                                  ),
                                  FutureBuilder(
                                    builder: (context, snapshot) => Text(
                                      'position: ${snapshot.data}',
                                    ),
                                    future: WindowPlus.instance.position,
                                  ),
                                  FutureBuilder(
                                    future: WindowPlus.instance.savedWindowState,
                                    builder: (context, snapshot) => Text(
                                      'savedWindowState: ${snapshot.data}',
                                    ),
                                  ),
                                  FutureBuilder(
                                    future: WindowPlus.instance.monitors,
                                    builder: (context, snapshot) => Text(
                                      'monitors: ${snapshot.data}',
                                    ),
                                  ),
                                  Text(
                                    'singleInstanceArguments: $singleInstanceArguments',
                                  ),
                                ],
                              ),
                              const SizedBox(width: 32.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Wrap(
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
                                child: const Text('hide'),
                              ),
                              TextButton(
                                onPressed: WindowPlus.instance.show,
                                child: const Text('show'),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const SizedBox(width: 16.0),
                              const SizedBox(
                                width: 96.0,
                                child: Text('movement :'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final position = await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1 - 10,
                                    position.dy ~/ 1,
                                  );
                                },
                                child: const Text('left'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final position = await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1 + 10,
                                    position.dy ~/ 1,
                                  );
                                },
                                child: const Text('right'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final position = await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1,
                                    position.dy ~/ 1 - 10,
                                  );
                                },
                                child: const Text('up'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final position = await WindowPlus.instance.position;
                                  WindowPlus.instance.move(
                                    position.dx ~/ 1,
                                    position.dy ~/ 1 + 10,
                                  );
                                },
                                child: const Text('down'),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const SizedBox(width: 16.0),
                              const SizedBox(
                                width: 96.0,
                                child: Text('resize :'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1 - 10,
                                    size.height ~/ 1,
                                  );
                                },
                                child: const Text('left'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1 + 10,
                                    size.height ~/ 1,
                                  );
                                },
                                child: const Text('right'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1,
                                    size.height ~/ 1 - 10,
                                  );
                                },
                                child: const Text('up'),
                              ),
                              const SizedBox(width: 16.0),
                              TextButton(
                                onPressed: () async {
                                  final size = await WindowPlus.instance.size;
                                  WindowPlus.instance.resize(
                                    size.width ~/ 1,
                                    size.height ~/ 1 + 10,
                                  );
                                },
                                child: const Text('down'),
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
                WindowCaption(),
              ],
            ),
          );
        },
      ),
    );
  }
}
