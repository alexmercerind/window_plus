#include "window_plus_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

namespace window_plus {

WindowPlusPlugin::WindowPlusPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

WindowPlusPlugin::~WindowPlusPlugin() {}

HWND WindowPlusPlugin::GetWindow() {
  return ::GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT);
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
      break;
    }
    case WM_NCCALCSIZE: {
      if (!wparam) {
        return 0;
      }
      auto params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
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
        // The thing to note here is that the top margins are not changed (see
        // behavior of file explorer for example) & |HTTOP| is handled on the
        // parent HWND.
        params->rgrc[0].bottom -= border.y;
        params->rgrc[0].left += border.x;
        params->rgrc[0].right -= border.x;
      }
      return 0;
    }
  }
  return std::nullopt;
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
      ::ShowWindow(GetWindow(), SW_NORMAL);
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
