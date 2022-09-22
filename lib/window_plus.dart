
import 'window_plus_platform_interface.dart';

class WindowPlus {
  Future<String?> getPlatformVersion() {
    return WindowPlusPlatform.instance.getPlatformVersion();
  }
}
