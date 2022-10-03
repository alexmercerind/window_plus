// This file is a part of window_plus
// (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that
// can be found in the LICENSE file.
#ifndef WINDOW_PLUS_COMMON_H_
#define WINDOW_PLUS_COMMON_H_

static constexpr auto kMethodChannelName = "com.alexmercerind/window_plus";

static constexpr auto kEnsureInitializedMethodName = "ensureInitialized";
static constexpr auto kSetStateMethodName = "setState";

static constexpr auto kWindows10RTM = 10240;
static constexpr auto kWindows10RS1 = 14393;

#define WM_CAPTIONAREA (WM_USER + 0x0009)

typedef LONG NTSTATUS, *PNTSTATUS;
#define STATUS_SUCCESS (0x00000000)
typedef NTSTATUS(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
typedef int(WINAPI* GetSystemMetricsForDpiPtr)(int, UINT);
typedef UINT(WINAPI* GetDpiForWindowPtr)(HWND);

#endif  // WINDOW_PLUS_COMMON_H_
