// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
//
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:win32/win32.dart';

const String kMethodChannelName = 'com.alexmercerind/window_plus';

const String kEnsureInitializedMethodName = 'ensureInitialized';
const String kSetStateMethodName = 'setState';
const String kWindowCloseReceivedMethodName = 'windowCloseReceived';

const String kCaptionHeightKey = 'captionHeight';
const String kHwndKey = 'hwnd';

const String kWin32FlutterViewWindowClass = 'FLUTTERVIEW';

// ignore: constant_identifier_names
const int WM_CAPTIONAREA = WM_USER + 0x0009;
