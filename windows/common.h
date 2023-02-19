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
static constexpr auto kWindowCloseReceivedMethodName = "windowCloseReceived";
static constexpr auto kNotifyFirstFrameRasterizedMethodName =
    "notifyFirstFrameRasterized";
static constexpr auto kWindowMovedMethodName = "windowMoved";
static constexpr auto kWindowResizedMethodName = "windowResized";
static constexpr auto kWindowActivatedMethodName = "windowActivated";
static constexpr auto kWindowMinimizedMethodName = "windowMinimized";
static constexpr auto kWindowMaximizedMethodName = "windowMaximized";
static constexpr auto kSingleInstanceDataReceivedMethodName =
    "singleInstanceDataReceived";
static constexpr auto kWindows10RTM = 10240;
static constexpr auto kWindows10RS1 = 14393;
static constexpr auto kWindows10RS5 = 17763;

// The default window class as present in un-changed Flutter runner template.
static constexpr auto kDefaultWindowClassName = L"FLUTTER_RUNNER_WIN32_WINDOW";

#define WM_CAPTIONAREA (WM_USER + 0x0009)
#define WM_NOTIFYDESTROY (WM_USER + 0x000A)

typedef LONG NTSTATUS, *PNTSTATUS;
#define STATUS_SUCCESS (0x00000000)
typedef NTSTATUS(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
typedef int(WINAPI* GetSystemMetricsForDpiPtr)(int, UINT);
typedef UINT(WINAPI* GetDpiForWindowPtr)(HWND);

#endif  // WINDOW_PLUS_COMMON_H_
