import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'window_plus_platform_interface.dart';

/// An implementation of [WindowPlusPlatform] that uses method channels.
class MethodChannelWindowPlus extends WindowPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('window_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
