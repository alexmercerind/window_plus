#include "window_plus_plugin.h"

#include <Commctrl.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#pragma comment(lib, "dwmapi")
#pragma comment(lib, "comctl32.lib")

namespace window_plus {

WindowPlusPlugin::WindowPlusPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

WindowPlusPlugin::~WindowPlusPlugin() {}

HWND WindowPlusPlugin::GetWindow() {
  return ::GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT);
}

RECT WindowPlusPlugin::GetMonitorRect() {
  auto info = MONITORINFO{};
  info.cbSize = DWORD(sizeof(MONITORINFO));
  auto monitor = MonitorFromWindow(GetWindow(), MONITOR_DEFAULTTONEAREST);
  GetMonitorInfoW(monitor, static_cast<LPMONITORINFO>(&info));
  return info.rcWork;
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

bool WindowPlusPlugin::IsWindows10OrGreater() {
  auto version = GetWindowsVersion();
  return version.dwBuildNumber >= kWindows10RTM;
}

std::optional<HRESULT> WindowPlusPlugin::WindowProcDelegate(HWND hwnd,
                                                            UINT message,
                                                            WPARAM wparam,
                                                            LPARAM lparam) {
  switch (message) {
    case WM_ERASEBKGND: {
      return 1;
    }
    case WM_NCHITTEST: {
      POINT cursor{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      const POINT border{::GetSystemMetrics(SM_CXFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER),
                         ::GetSystemMetrics(SM_CYFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER)};
      RECT rect;
      ::GetWindowRect(GetWindow(), &rect);
      // Bit values to handle multiple regions at once at corners.
      // Determined values are kept, while others are multiplied by |FALSE|.
      enum {
        client = 0b0000,
        left = 0b0001,
        right = 0b0010,
        top = 0b0100,
        bottom = 0b1000,
      };
      // Here border values are added/subtracted from the window hitbox to make
      // resize border lie outside of the actual client area.
      // The top-border is handled in child Flutter view's proc.
      const auto result = left * (cursor.x < (rect.left + border.x)) |
                          right * (cursor.x >= (rect.right - border.x)) |
                          top * (cursor.y < (rect.top + border.y)) |
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
      // The window region itself.
      return HTCLIENT;
    }
    case WM_NCCALCSIZE: {
      if (!wparam) {
        return 0;
      }
      auto params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      // Adjust the window client area, so that content doesn't appear cropped
      // out of the screen, when it is maximized.
      auto monitor_rect = GetMonitorRect();
      if (params->lppos) {
        if ((params->lppos->x < monitor_rect.left) &&
            (params->lppos->y < monitor_rect.top) &&
            (params->lppos->cx > (monitor_rect.right - monitor_rect.left)) &&
            (params->lppos->cy > (monitor_rect.bottom - monitor_rect.top))) {
          params->lppos->x = monitor_rect.left;
          params->lppos->y = monitor_rect.top;
          params->lppos->cx = monitor_rect.right - monitor_rect.left;
          params->lppos->cy = monitor_rect.bottom - monitor_rect.top;
        }
      }
      // I have no idea why this |for| loop exists but whatever.
      for (int i = 0; i < 3; i++) {
        if ((params->rgrc[i].left < monitor_rect.left) &&
            (params->rgrc[i].top < monitor_rect.top) &&
            (params->rgrc[i].right > monitor_rect.right) &&
            (params->rgrc[i].bottom > monitor_rect.bottom)) {
          params->rgrc[i].left = monitor_rect.left;
          params->rgrc[i].top = monitor_rect.top;
          params->rgrc[i].right = monitor_rect.right;
          params->rgrc[i].bottom = monitor_rect.bottom;
        }
      }
      // Handle the window in restored state.
      const POINT border{::GetSystemMetrics(SM_CXFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER),
                         ::GetSystemMetrics(SM_CYFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER)};
      if (::IsZoomed(GetWindow())) {
        params->rgrc[0].top -= 1;
      } else {
        // In Windows, when window frame (i.e. controls & border) is drawn, the
        // space of the client is actually reduced to make space for the resize
        // border (because WM_NCHHITTEST is only received inside client area).
        // In modern Windows (i.e. 10 or 11), this space actually looks
        // transparent, thus it feels like the resize border is outside client
        // area but it is actually not, instead the actual client area size is
        // reduced.
        // The thing to note here is that the top border is not reduced.
        // This is because we want to keep the top resize border.
        params->rgrc[0].bottom -= border.y;
        params->rgrc[0].left += border.x;
        params->rgrc[0].right -= border.x;
      }
      return 0;
    }
  }
  return std::nullopt;
}

LRESULT WindowPlusPlugin::ChildWindowProc(HWND window, UINT message,
                                          WPARAM wparam, LPARAM lparam,
                                          UINT_PTR id, DWORD_PTR data) {
  switch (message) {
    case WM_NCHITTEST: {
      // This subclass proc is only used to handle the top resize border.
      // This means sending |HTTRANSPARENT| from the child window for the top
      // region of the window. It will cause the actual parent window to receive
      // the |WM_NCHITTEST| message and handle |HTTOP|.
      RECT rect;
      ::GetWindowRect(window, &rect);
      if (rect.top <= 0) {
        return HTCLIENT;
      }
      POINT cursor{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      const POINT border{::GetSystemMetrics(SM_CXFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER),
                         ::GetSystemMetrics(SM_CYFRAME) +
                             ::GetSystemMetrics(SM_CXPADDEDBORDER)};
      // To allow interraction with parent HWND for |HTTOP|.
      if (cursor.y < rect.top + border.y) {
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
    if (IsWindows10OrGreater() && window_proc_delegate_id_ == 0) {
      window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
          std::bind(&WindowPlusPlugin::WindowProcDelegate, this,
                    std::placeholders::_1, std::placeholders::_2,
                    std::placeholders::_3, std::placeholders::_4));
      ::SetWindowSubclass(registrar_->GetView()->GetNativeWindow(),
                          ChildWindowProc, 1, 0);
      auto margins = MARGINS{0, 0, 0, 1};
      ::DwmExtendFrameIntoClientArea(GetWindow(), &margins);
      auto refresh = SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE |
                     SWP_NOSIZE | SWP_FRAMECHANGED;
      ::SetWindowPos(GetWindow(), nullptr, 0, 0, 0, 0, refresh);
      ::ShowWindow(GetWindow(), SW_SHOWMAXIMIZED);
    }
    result->Success(flutter::EncodableValue(nullptr));
  } else {
    result->NotImplemented();
  }
}

void WindowPlusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowPlusPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}

}  // namespace window_plus
