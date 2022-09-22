#include "include/window_plus/window_plus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "window_plus_plugin.h"

void WindowPlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_plus::WindowPlusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
