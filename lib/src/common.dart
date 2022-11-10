// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:win32/win32.dart';

const String kMethodChannelName = 'com.alexmercerind/window_plus';

const String kEnsureInitializedMethodName = 'ensureInitialized';
const String kSetStateMethodName = 'setState';
const String kGetStateMethodName = 'getState';
const String kCloseMethodName = 'close';
const String kDestroyMethodName = 'destroy';
const String kMoveMethodName = 'move';
const String kResizeMethodName = 'resize';
const String kSetIsFullscreenMethodName = 'setIsFullscreen';
const String kWindowMovedMethodName = 'windowMoved';
const String kWindowResizedMethodName = 'windowResized';
const String kWindowCloseReceivedMethodName = 'windowCloseReceived';
const String kSingleInstanceDataReceivedMethodName =
    'singleInstanceDataReceived';
const String kNotifyFirstFrameRasterizedMethodName =
    'notifyFirstFrameRasterized';
const String kWindowStateEventReceivedMethodName = 'windowStateEventReceived';
const String kConfigureEventReceivedMethodName = 'configureEventReceived';

const String kCaptionHeightKey = 'captionHeight';
const String kHwndKey = 'hwnd';

const String kWin32FlutterViewWindowClass = 'FLUTTERVIEW';

const int kMaximumMonitorCount = 16;

// ignore: constant_identifier_names
const int WM_CAPTIONAREA = WM_USER + 0x0009;
