// This file is a part of window_plus
// (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that
// can be found in the LICENSE file.
#ifndef FLUTTER_PLUGIN_WINDOW_PLUS_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_PLUS_PLUGIN_H_

#include <Windows.h>
#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windowsx.h>

#include <functional>
#include <memory>

#include "common.h"

namespace window_plus {

class WindowPlusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  WindowPlusPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~WindowPlusPlugin();

  WindowPlusPlugin(const WindowPlusPlugin&) = delete;
  WindowPlusPlugin& operator=(const WindowPlusPlugin&) = delete;

 private:
  // TODO (@alexmercerind): Expose in public API.
  static constexpr auto kMonitorSafeArea = 8;
  static constexpr auto kWindowDefaultWidth = 1024;
  static constexpr auto kWindowDefaultHeight = 640;
  static constexpr auto kWindowDefaultMinimumWidth = 960;
  static constexpr auto kWindowDefaultMinimumHeight = 640;

  HWND GetWindow();

  RECT GetMonitorRect(bool use_cursor);

  std::vector<HMONITOR> GetMonitors();

  RTL_OSVERSIONINFOW GetWindowsVersion();

  bool IsWindows10RTMOrGreater();

  bool IsWindows10RS1OrGreater();

  bool IsFullscreen();

  int32_t GetSystemMetricsForWindow(int32_t index);

  POINT GetDefaultWindowPadding();

  // Replaces the existing |MoveWindow| behavior in Windows runner template to
  // be more friendly to custom title-bar and frameless windows.
  void AlignChildContent();

  std::optional<HRESULT> WindowProcDelegate(HWND window, UINT message,
                                            WPARAM wparam, LPARAM lparam);

  // For Windows lower than 10 RS1, where custom frame isn't used.
  // Does not handle |WM_NCHITTEST| & |WM_NCCALCSIZE| messages.
  std::optional<HRESULT> FallbackWindowProcDelegate(HWND window, UINT message,
                                                    WPARAM wparam,
                                                    LPARAM lparam);

  static LRESULT ChildWindowProc(HWND window, UINT message, WPARAM wparam,
                                 LPARAM lparam, UINT_PTR id, DWORD_PTR data);

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_ =
      nullptr;
  int64_t window_proc_delegate_id_ = -1;
  int32_t minimum_width_ = kWindowDefaultMinimumWidth;
  int32_t minimum_height_ = kWindowDefaultMinimumHeight;
  bool enable_custom_frame_ = false;
  bool first_frame_rasterized_ = false;
  // DO NOT ACCESS THIS MEMBER DIRECTLY. Use |GetMonitors| instead.
  std::vector<HMONITOR> monitors_ = {};
};

}  // namespace window_plus

#endif
