// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'package:win32/win32.dart';

const String kMethodChannelName = 'com.alexmercerind/window_plus';

// Common:

const String kEnsureInitializedMethodName = 'ensureInitialized';
const String kCloseMethodName = 'close';
const String kDestroyMethodName = 'destroy';

const String kWindowCloseReceivedMethodName = 'windowCloseReceived';
const String kSingleInstanceDataReceivedMethodName =
    'singleInstanceDataReceived';
const String kNotifyFirstFrameRasterizedMethodName =
    'notifyFirstFrameRasterized';

// Win32 Exclusives:

const String kWindowMovedMethodName = 'windowMoved';
const String kWindowResizedMethodName = 'windowResized';
const String kWindowActivatedMethodName = 'windowActivated';

// GTK Exclusives:

const String kGetStateMethodName = 'getState';
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

// Win32 Specific Constants:

const String kWin32FlutterViewWindowClass = 'FLUTTERVIEW';
const int kMaximumMonitorCount = 16;
const int WM_CAPTIONAREA = WM_USER + 0x0009;
const int WM_NOTIFYDESTROY = WM_USER + 0x000A;
