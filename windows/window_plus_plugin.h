// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.
#ifndef FLUTTER_PLUGIN_WINDOW_PLUS_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_PLUS_PLUGIN_H_

#include <Windows.h>
#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
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
  static constexpr auto kDefaultDPI = 96.0f;
  static constexpr auto kMonitorSafeArea = 8;
  static constexpr auto kWindowDefaultWidth = 1280;
  static constexpr auto kWindowDefaultHeight = 720;

  HWND GetWindow();

  RECT GetMonitorRect(RECT* rect = nullptr);

  std::vector<HMONITOR> GetMonitors();

  RTL_OSVERSIONINFOW GetWindowsVersion();

  bool IsWindows10RTMOrGreater();

  bool IsWindows10RS1OrGreater();

  bool IsWindows10RS5OrGreater();

  bool IsFullscreen();

  float GetScaleFactorForWindow();

  int32_t GetSystemMetricsForWindow(int32_t index);

  POINT GetDefaultWindowPadding();

  int32_t GetDefaultWindowWidth();

  int32_t GetDefaultWindowHeight();

  void AlignChildContent();

  // Sets minimum size of the window.
  void SetMinimumSize(flutter::EncodableMap& args);

  std::optional<HRESULT> WindowProcDelegate(HWND window, UINT message, WPARAM wparam, LPARAM lparam) noexcept;

  // For Windows lower than 10 RS1, where custom frame isn't used.
  // Does not handle |WM_NCHITTEST| & |WM_NCCALCSIZE| messages.
  std::optional<HRESULT> FallbackWindowProcDelegate(HWND window, UINT message, WPARAM wparam, LPARAM lparam) noexcept;

  static LRESULT ChildWindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam, UINT_PTR id, DWORD_PTR data) noexcept;

  void SendSingleInstanceData(LPARAM lparam);

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // On Windows 7, the process is not terminated when the window is closed and
  // the app is not visible. This is a workaround to terminate the process when
  // the window is closed.
  void KillProcess();

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_ = nullptr;
  bool intercept_close_ = true;
  int64_t window_proc_delegate_id_ = -1;

  // Do not restrict the window size by default.
  int32_t minimum_width_ = -1;
  int32_t minimum_height_ = -1;

  // Default non-DPI aware values.
  int32_t default_width_ = 1280;
  int32_t default_height_ = 720;

  bool enable_custom_frame_ = false;
  bool enable_event_streams_ = false;
  bool first_frame_rasterized_ = false;
  // DO NOT ACCESS THIS MEMBER DIRECTLY. Use |GetMonitors| instead.
  std::vector<HMONITOR> monitors_ = {};
};

}  // namespace window_plus

#endif
