import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'window_plus_method_channel.dart';

abstract class WindowPlusPlatform extends PlatformInterface {
  /// Constructs a WindowPlusPlatform.
  WindowPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowPlusPlatform _instance = MethodChannelWindowPlus();

  /// The default instance of [WindowPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelWindowPlus].
  static WindowPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WindowPlusPlatform] when
  /// they register themselves.
  static set instance(WindowPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
