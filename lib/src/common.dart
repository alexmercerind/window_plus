import 'package:win32/win32.dart';

const String kMethodChannelName = 'com.alexmercerind/window_plus';

const String kEnsureInitializedMethodName = 'ensureInitialized';
const String kSetStateMethodName = 'setState';

const String kCaptionHeightKey = 'captionHeight';
const String kHwndKey = 'hwnd';

// ignore: constant_identifier_names
const int WM_CAPTIONAREA = WM_USER + 0x0009;
