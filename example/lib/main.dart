import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowPlus.instance.ensureInitialized();
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('window_plus'),
        ),
        body: const Center(
          child: Card(
            elevation: 4.0,
            child: WindowCaptionArea(
              width: 400.0,
              height: 200.0,
            ),
          ),
        ),
      ),
    );
  }
}
