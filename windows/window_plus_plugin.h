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
  static constexpr auto kMonitorSafeArea = 36;
  static constexpr auto kWindowDefaultWidth = 1024;
  static constexpr auto kWindowDefaultHeight = 640;

  HWND GetWindow();

  RECT GetMonitorRect();

  RTL_OSVERSIONINFOW GetWindowsVersion();

  bool IsWindows10OrGreater();

  std::optional<HRESULT> WindowPlusPlugin::WindowProcDelegate(HWND window,
                                                              UINT message,
                                                              WPARAM wparam,
                                                              LPARAM lparam);

  static LRESULT ChildWindowProc(HWND window, UINT message, WPARAM wparam,
                                 LPARAM lparam, UINT_PTR id, DWORD_PTR data);

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  int32_t caption_height_ = 0;
  int64_t window_proc_delegate_id_ = -1;
};

}  // namespace window_plus

#endif
