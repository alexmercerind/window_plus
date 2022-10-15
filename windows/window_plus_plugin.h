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

  HWND GetWindow();

  static RTL_OSVERSIONINFOW GetWindowsVersion();

  static bool IsWindows10RTMOrGreater();

  static bool IsWindows10RS1OrGreater();

  static int32_t GetSystemMetricsForWindow(int32_t index, HWND window);

  static POINT GetDefaultWindowPadding(HWND window);

  // Replaces the existing |MoveWindow| behavior in Windows runner template to
  // be more friendly to custom title-bar and frameless windows.
  static void AlignChildContent(HWND child, HWND window);

 private:
  static constexpr auto kMonitorSafeArea = 36;
  static constexpr auto kWindowDefaultWidth = 1024;
  static constexpr auto kWindowDefaultHeight = 640;
  // TODO (@alexmercerind): Expose in public API.
  // Currently handling |WM_GETMINMAXINFO| as per Harmonoid's requirements.
  // See: https://github.com/harmonoid/harmonoid.
  static constexpr auto kWindowDefaultMinimumWidth = 960;
  static constexpr auto kWindowDefaultMinimumHeight = 640;

  RECT GetMonitorRect();

  bool IsFullscreen();

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
  // TODO(@alexmercerind): Re-structure code.
  // Possibly convert |WindowPlusPlugin| into a singleton & get rid of all the
  // static methods & attributes. This will also get rid of any parameters in
  // |AlignChildContent|.
  // Ideally there is no need to even expose |AlignChildContent| to public API,
  // since we can register a window proc delegate within the plugin interface.
  static bool enable_custom_frame_;
};

}  // namespace window_plus

#endif
