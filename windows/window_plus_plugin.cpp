// This file is a part of window_plus
// (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that
// can be found in the LICENSE file.
#include "window_plus_plugin.h"

#include <Commctrl.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "include/window_plus/window_plus_plugin_c_api.h"

namespace window_plus {

WindowPlusPlugin::WindowPlusPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      channel_(
          std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
              registrar->messenger(), kMethodChannelName,
              &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler([&](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
}

WindowPlusPlugin::~WindowPlusPlugin() {
  if (window_proc_delegate_id_ != -1) {
    registrar_->UnregisterTopLevelWindowProcDelegate(
        static_cast<int32_t>(window_proc_delegate_id_));
  }
}

HWND WindowPlusPlugin::GetWindow() {
  return ::GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT);
}

RECT WindowPlusPlugin::GetMonitorRect(bool use_cursor) {
  auto info = MONITORINFO{};
  info.cbSize = DWORD(sizeof(MONITORINFO));
  HMONITOR monitor = nullptr;
  if (use_cursor) {
    POINT cursor;
    ::GetCursorPos(&cursor);
    monitor = ::MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  } else {
    monitor = ::MonitorFromWindow(GetWindow(), MONITOR_DEFAULTTONEAREST);
  }
  ::GetMonitorInfo(monitor, static_cast<LPMONITORINFO>(&info));
  return info.rcWork;
}

std::vector<HMONITOR> WindowPlusPlugin::GetMonitors() {
  monitors_.clear();
  auto callback = [](HMONITOR monitor, auto, auto, LPARAM data) {
    auto monitors = reinterpret_cast<std::vector<HMONITOR>*>(data);
    monitors->emplace_back(monitor);
    return 1;
  };
  ::EnumDisplayMonitors(nullptr, nullptr, callback,
                        reinterpret_cast<LPARAM>(&monitors_));
  return monitors_;
}

RTL_OSVERSIONINFOW WindowPlusPlugin::GetWindowsVersion() {
  auto module = ::GetModuleHandleW(L"ntdll.dll");
  if (module) {
    auto fn = reinterpret_cast<RtlGetVersionPtr>(
        ::GetProcAddress(module, "RtlGetVersion"));
    if (fn != nullptr) {
      auto rovi = RTL_OSVERSIONINFOW{0};
      rovi.dwOSVersionInfoSize = sizeof(rovi);
      if (STATUS_SUCCESS == fn(&rovi)) {
        return rovi;
      }
    }
  }
  return RTL_OSVERSIONINFOW{0};
}

bool WindowPlusPlugin::IsWindows10RTMOrGreater() {
  auto version = GetWindowsVersion();
  return version.dwBuildNumber >= kWindows10RTM;
}

bool WindowPlusPlugin::IsWindows10RS1OrGreater() {
  auto version = GetWindowsVersion();
  return version.dwBuildNumber >= kWindows10RS1;
}

bool WindowPlusPlugin::IsFullscreen() {
  // The fullscreen mode is implemented by removing |WS_OVERLAPPEDWINDOW|
  // style. So, if the window has |WS_OVERLAPPEDWINDOW| style, it is not in
  // fullscreen.
  return !(::GetWindowLongPtr(GetWindow(), GWL_STYLE) & WS_OVERLAPPEDWINDOW);
}

int32_t WindowPlusPlugin::GetSystemMetricsForWindow(int32_t index) {
  if (IsWindows10RS1OrGreater()) {
    auto module = ::GetModuleHandleW(L"User32.dll");
    if (module) {
      // Only available for Windows 10 RS1 i.e. Anniversary Update.
      auto GetSystemMetricsForDpi = reinterpret_cast<GetSystemMetricsForDpiPtr>(
          ::GetProcAddress(module, "GetSystemMetricsForDpi"));
      auto GetDpiForWindow = reinterpret_cast<GetDpiForWindowPtr>(
          ::GetProcAddress(module, "GetDpiForWindow"));
      if (GetSystemMetricsForDpi != nullptr && GetDpiForWindow != nullptr) {
        // DPI aware metrics.
        return GetSystemMetricsForDpi(index, GetDpiForWindow(GetWindow()));
      }
    }
  }
  // System metrics without any DPI awareness.
  return ::GetSystemMetrics(index);
}

POINT WindowPlusPlugin::GetDefaultWindowPadding() {
  auto x = GetSystemMetricsForWindow(SM_CXFRAME) +
           GetSystemMetricsForWindow(SM_CXPADDEDBORDER);
  auto y = GetSystemMetricsForWindow(SM_CYFRAME) +
           GetSystemMetricsForWindow(SM_CXPADDEDBORDER);
  return POINT{x, y};
}

void WindowPlusPlugin::AlignChildContent() {
  if (enable_custom_frame_) {
    auto padding = GetDefaultWindowPadding();
    auto frame = RECT{};
    ::GetClientRect(GetWindow(), &frame);
    // Make some room at the top, to prevent the shift of the content upon
    // fresh launch in maximized state.
    ::MoveWindow(registrar_->GetView()->GetNativeWindow(), frame.left,
                 frame.top + padding.y, frame.right - frame.left,
                 frame.bottom - frame.top - padding.y, TRUE);
  } else {
    // No need to do this, if the custom frame is disabled.
    auto frame = RECT{};
    ::GetClientRect(GetWindow(), &frame);
    ::MoveWindow(registrar_->GetView()->GetNativeWindow(), frame.left,
                 frame.top, frame.right - frame.left, frame.bottom - frame.top,
                 TRUE);
  }
}

std::optional<HRESULT> WindowPlusPlugin::WindowProcDelegate(HWND window,
                                                            UINT message,
                                                            WPARAM wparam,
                                                            LPARAM lparam) {
  switch (message) {
    case WM_GETMINMAXINFO: {
      auto info = (LPMINMAXINFO)lparam;
      if (minimum_width_ != -1 && minimum_height_ != -1) {
        info->ptMinTrackSize.x = minimum_width_;
        info->ptMinTrackSize.y = minimum_height_;
      }
    }
    case WM_ERASEBKGND: {
      return 1;
    }
    // Separately handle window caption area dragging.
    // |WM_CAPTIONAREA| is custom window message, see: WM_USER.
    case WM_CAPTIONAREA: {
      ::ReleaseCapture();
      ::SendMessage(GetWindow(), WM_SYSCOMMAND, SC_MOVE | HTCAPTION, 0);
    }
    case WM_NCHITTEST: {
      // Window only has client area in fullscreen.
      // No need for resize or caption area hit-testing.
      if (IsFullscreen()) {
        return HTCLIENT;
      }
      POINT cursor{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      const POINT border = GetDefaultWindowPadding();
      RECT rect;
      ::GetWindowRect(GetWindow(), &rect);
      // Bit values to handle multiple regions at once at corners.
      // Determined values are kept, while others are multiplied by |FALSE|.
      enum {
        client = 0b00000,
        left = 0b00010,
        right = 0b00100,
        top = 0b01000,
        bottom = 0b10000,
      };
      // Here border values are added/subtracted from the window hitbox to
      // make resize border lie outside of the actual client area. The
      // top-border is handled in child Flutter view's proc.
      const auto result =
          left * (cursor.x < (rect.left + border.x)) |
          right * (cursor.x >= (rect.right - border.x)) |
          top * (cursor.y < (rect.top + border.y) &&
                 /* Do not show top resize border in maximized state. */
                 rect.top > 0) |
          bottom * (cursor.y >= (rect.bottom - border.y));
      switch (result) {
        case left:
          return HTLEFT;
        case right:
          return HTRIGHT;
        case top:
          return HTTOP;
        case bottom:
          return HTBOTTOM;
        case top | left:
          return HTTOPLEFT;
        case top | right:
          return HTTOPRIGHT;
        case bottom | left:
          return HTBOTTOMLEFT;
        case bottom | right:
          return HTBOTTOMRIGHT;
      }
      // The client area itself i.e. Flutter.
      return HTCLIENT;
    }
    case WM_NCCALCSIZE: {
      if (!wparam) {
        return 0;
      }
      auto params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      // Adjust the window client area, so that content doesn't appear cropped
      // out of the screen, when it is maximized.
      auto monitor_rect = GetMonitorRect(false);
      if (params->lppos) {
        if ((params->lppos->x < monitor_rect.left) &&
            (params->lppos->y < monitor_rect.top) &&
            (params->lppos->cx > (monitor_rect.right - monitor_rect.left)) &&
            (params->lppos->cy > (monitor_rect.bottom - monitor_rect.top))) {
          params->lppos->x = monitor_rect.left;
          params->lppos->cx = monitor_rect.right - monitor_rect.left;
          // No need to modify the vertical alignment of the child |HWND|
          // after |AlignChildContent| implementation has landed.
          // params->lppos->y = monitor_rect.top;
          // params->lppos->cy = monitor_rect.bottom - monitor_rect.top;
        }
      }
      // I have no idea why this |for| loop exists but whatever.
      for (int i = 0; i < 3; i++) {
        if ((params->rgrc[i].left < monitor_rect.left) &&
            (params->rgrc[i].top < monitor_rect.top) &&
            (params->rgrc[i].right > monitor_rect.right) &&
            (params->rgrc[i].bottom > monitor_rect.bottom)) {
          params->rgrc[i].left = monitor_rect.left;
          params->rgrc[i].right = monitor_rect.right;
          // No need to modify the vertical alignment of the child |HWND|
          // after |AlignChildContent| implementation has landed.
          // params->rgrc[i].top = monitor_rect.top;
          // params->rgrc[i].bottom = monitor_rect.bottom;
        }
      }
      // Handle the window in restored state.
      const POINT border = GetDefaultWindowPadding();
      if (::IsZoomed(GetWindow())) {
        params->rgrc[0].top -= 1;
        // Post |AlignChildContent| implementation.
        if (IsFullscreen()) {
          params->rgrc[0].top -= border.y;
        }
      } else {
        // In Windows, when window frame (i.e. controls & border) is drawn,
        // the space of the client is actually reduced to make space for the
        // resize border (because WM_NCHHITTEST is only received inside client
        // area). In modern Windows (i.e. 10 or 11), this space actually looks
        // transparent, thus it feels like the resize border is outside client
        // area but it is actually not, instead the actual client area size is
        // reduced.
        // The thing to note here is that the top border is not reduced.
        // This is because we want to keep the top resize border.
        //
        // Only reduce the client area for |WM_NCHHITTEST| handling if the
        // window is not fullscreen.

        // Post |AlignChildContent| implementation.
        params->rgrc[0].top -= border.y;
        if (!IsFullscreen()) {
          params->rgrc[0].bottom -= border.y;
          params->rgrc[0].left += border.x;
          params->rgrc[0].right -= border.x;
        }
      }
      return 0;
    }
    case WM_CLOSE: {
      try {
        // Notify Flutter.
        channel_->InvokeMethod(kWindowCloseReceivedMethodName, nullptr,
                               nullptr);
        // Returning 0 means that we're handling the message & window won't be
        // closed, until |WM_DESTROY| is sent.
      } catch (...) {
        // Enclosing in try-catch clause to prevent any unhandled exceptions.
      }
      return 0;
    }
    case WM_SIZE: {
      AlignChildContent();
      return 0;
    }
  }
  return std::nullopt;
}

std::optional<HRESULT> WindowPlusPlugin::FallbackWindowProcDelegate(
    HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_GETMINMAXINFO: {
      auto info = (LPMINMAXINFO)lparam;
      if (minimum_width_ != -1 && minimum_height_ != -1) {
        info->ptMinTrackSize.x = minimum_width_;
        info->ptMinTrackSize.y = minimum_height_;
      }
    }
    case WM_ERASEBKGND: {
      return 1;
    }
    // Separately handle window caption area dragging.
    // |WM_CAPTIONAREA| is custom window message, see: WM_USER.
    case WM_CAPTIONAREA: {
      ::ReleaseCapture();
      ::SendMessage(GetWindow(), WM_SYSCOMMAND, SC_MOVE | HTCAPTION, 0);
    }
    case WM_CLOSE: {
      try {
        // Notify Flutter.
        channel_->InvokeMethod(kWindowCloseReceivedMethodName, nullptr,
                               nullptr);
        // Returning 0 means that we're handling the message & window won't be
        // closed, until |WM_DESTROY| is sent.
      } catch (...) {
        // Enclosing in try-catch clause to prevent any unhandled exceptions.
      }
      return 0;
    }
    case WM_SIZE: {
      AlignChildContent();
      return 0;
    }
  }
  return std::nullopt;
}

LRESULT WindowPlusPlugin::ChildWindowProc(HWND window, UINT message,
                                          WPARAM wparam, LPARAM lparam,
                                          UINT_PTR id, DWORD_PTR data) {
  auto plugin = reinterpret_cast<WindowPlusPlugin*>(data);
  switch (message) {
    case WM_NCHITTEST: {
      // This subclass proc is only used to handle the top resize border.
      // This means sending |HTTRANSPARENT| from the child window for the top
      // region of the window. It will cause the actual parent window to
      // receive the |WM_NCHITTEST| message and handle |HTTOP|.
      RECT rect;
      ::GetWindowRect(window, &rect);
      POINT cursor{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      const POINT border = plugin->GetDefaultWindowPadding();
      if (
          // No need to make room for resize border in maximized state or
          // fullscreen state.
          !::IsZoomed(plugin->GetWindow()) && !plugin->IsFullscreen() &&
          cursor.y < rect.top + border.y) {
        return HTTRANSPARENT;
      }
      // Actual Flutter content, keep it interactive.
      return HTCLIENT;
    }
  }
  return DefSubclassProc(window, message, wparam, lparam);
}

void WindowPlusPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare(kEnsureInitializedMethodName) == 0) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    enable_custom_frame_ =
        std::get<bool>(arguments[flutter::EncodableValue("enableCustomFrame")]);
    if (enable_custom_frame_ && window_proc_delegate_id_ == -1) {
      window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
          std::bind(&WindowPlusPlugin::WindowProcDelegate, this,
                    std::placeholders::_1, std::placeholders::_2,
                    std::placeholders::_3, std::placeholders::_4));
      ::SetWindowSubclass(registrar_->GetView()->GetNativeWindow(),
                          ChildWindowProc, 1,
                          reinterpret_cast<DWORD_PTR>(this));
      // |DwmExtendFrameIntoClientArea| is working fine with 0 |MARGINS|
      // because the window has |WS_OVERLAPPEDWINDOW| style. Calling this
      // causes window to have black border which makes it feel like a
      // frameless window.
      auto margins = MARGINS{0, 0, 0, 0};
      ::DwmExtendFrameIntoClientArea(GetWindow(), &margins);
    } else if (!enable_custom_frame_ && window_proc_delegate_id_ == -1) {
      window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
          std::bind(&WindowPlusPlugin::FallbackWindowProcDelegate, this,
                    std::placeholders::_1, std::placeholders::_2,
                    std::placeholders::_3, std::placeholders::_4));
    }
    AlignChildContent();
    // Send a |WM_NCCALCSIZE|.
    auto refresh = SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE |
                   SWP_FRAMECHANGED;
    ::SetWindowPos(GetWindow(), nullptr, 0, 0, 0, 0, refresh);
    try {
      auto saved_window_state =
          arguments[flutter::EncodableValue("savedWindowState")];
      if (auto value =
              std::get_if<flutter::EncodableMap>(&saved_window_state)) {
        auto data = *value;
        auto x = std::get<int32_t>(data[flutter::EncodableValue("x")]);
        auto y = std::get<int32_t>(data[flutter::EncodableValue("y")]);
        auto width = std::get<int32_t>(data[flutter::EncodableValue("width")]);
        auto height =
            std::get<int32_t>(data[flutter::EncodableValue("height")]);
        auto maximized =
            std::get<bool>(data[flutter::EncodableValue("maximized")]);
        // If the window is within any of the available monitor rects, then
        // alright otherwise, restore it to that position. Otherwise, restore it
        // to the center of the |monitor|.
        auto is_within_monitor = false;
        auto monitors = GetMonitors();
        for (auto monitor : monitors) {
          MONITORINFO info;
          info.cbSize = sizeof(MONITORINFO);
          ::GetMonitorInfo(monitor, &info);
          std::cout << "RECT{ " << info.rcWork.left << ", " << info.rcWork.top
                    << ", " << info.rcWork.right << ", " << info.rcWork.bottom
                    << " }" << std::endl;
          auto dpi = FlutterDesktopGetDpiForMonitor(monitor);
          auto scale_factor = dpi / 96.0;
          auto safe_area = static_cast<LONG>(kMonitorSafeArea * scale_factor);
          info.rcWork.left += safe_area;
          info.rcWork.top += safe_area;
          info.rcWork.right -= safe_area;
          info.rcWork.bottom -= safe_area;
          if (!is_within_monitor) {
            if (x > info.rcWork.left && x + width < info.rcWork.right &&
                y > info.rcWork.top && y + height < info.rcWork.bottom) {
              std::cout << "HWND within bounds." << std::endl;
              is_within_monitor = true;
            }
          }
        }
        if (is_within_monitor) {
          ::SetWindowPos(GetWindow(), nullptr, x, y, width, height, 0);
        } else {
          auto monitor = GetMonitorRect(true);
          ::SetWindowPos(
              GetWindow(), nullptr,
              monitor.left + (monitor.right - monitor.left) / 2 - width / 2,
              monitor.top + (monitor.bottom - monitor.top) / 2 - height / 2,
              width, height, 0);
        }
        ::ShowWindow(GetWindow(), maximized ? SW_SHOWMAXIMIZED : SW_SHOWNORMAL);
      } else {
        // No saved window state, so restore the window to the center of the
        // |monitor| where the cursor is present.
        auto monitor = GetMonitorRect(true);
        ::SetWindowPos(GetWindow(), nullptr,
                       monitor.left + (monitor.right - monitor.left) / 2 -
                           kWindowDefaultWidth / 2,
                       monitor.top + (monitor.bottom - monitor.top) / 2 -
                           kWindowDefaultHeight / 2,
                       kWindowDefaultWidth, kWindowDefaultHeight, 0);
        ::ShowWindow(GetWindow(), SW_NORMAL);
      }
    } catch (...) {
      // Typically, an instance of |std::bad_variant_access| will be received.
      // No saved window state, so restore the window to the center of the
      // |monitor| where the cursor is present.
      auto monitor = GetMonitorRect(true);
      ::SetWindowPos(GetWindow(), nullptr,
                     monitor.left + (monitor.right - monitor.left) / 2 -
                         kWindowDefaultWidth / 2,
                     monitor.top + (monitor.bottom - monitor.top) / 2 -
                         kWindowDefaultHeight / 2,
                     kWindowDefaultWidth, kWindowDefaultHeight, 0);
      ::ShowWindow(GetWindow(), SW_NORMAL);
    }
    result->Success(
        flutter::EncodableValue(reinterpret_cast<int64_t>(GetWindow())));
  } else {
    result->NotImplemented();
  }
}

void WindowPlusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<WindowPlusPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

}  // namespace window_plus
