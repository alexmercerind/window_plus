import 'package:win32/win32.dart';

// ignore_for_file: constant_identifier_names

const String kMethodChannelName = 'com.alexmercerind/window_plus';

// Common:

const String kEnsureInitializedMethodName = 'ensureInitialized';
const String kGetMinimumSizeMethodName = 'getMinimumSize';
const String kSetMinimumSizeMethodName = 'setMinimumSize';
const String kWindowCloseReceivedMethodName = 'windowCloseReceived';
const String kNotifyFirstFrameRasterizedMethodName = 'notifyFirstFrameRasterized';
const String kSingleInstanceDataReceivedMethodName = 'singleInstanceDataReceived';

// Win32 Exclusives:

const String kWindowMovedMethodName = 'windowMoved';
const String kWindowResizedMethodName = 'windowResized';
const String kWindowActivatedMethodName = 'windowActivated';
const String kWindowFullScreenMethodName = 'windowFullScreen';

// GTK Exclusives:

const String kGetStateMethodName = 'getState';
const String kCloseMethodName = 'close';
const String kDestroyMethodName = 'destroy';
const String kGetIsMinimizedMethodName = 'getMinimized';
const String kGetIsMaximizedMethodName = 'getMaximized';
const String kGetIsFullscreenMethodName = 'getFullscreen';
const String kGetSizeMethodName = 'getSize';
const String kGetPositionMethodName = 'getPosition';
const String kGetMonitorsMethodName = 'getMonitors';
const String kSetIsFullscreenMethodName = 'setIsFullscreen';
const String kMaximizeMethodName = 'maximize';
const String kRestoreMethodName = 'restore';
const String kMinimizeMethodName = 'minimize';
const String kMoveMethodName = 'move';
const String kResizeMethodName = 'resize';
const String kHideMethodName = 'hide';
const String kShowMethodName = 'show';
const String kWindowStateEventReceivedMethodName = 'windowStateEventReceived';
const String kConfigureEventReceivedMethodName = 'configureEventReceived';

// Win32 Constants:

const String kWin32FlutterViewWindowClass = 'FLUTTERVIEW';
const int kMaximumMonitorCount = 16;
const int WM_CAPTIONAREA = WM_USER + 0x0009;
const int WM_NOTIFYDESTROY = WM_USER + 0x000A;
