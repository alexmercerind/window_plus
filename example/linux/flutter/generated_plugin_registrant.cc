//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <window_plus/window_plus_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) window_plus_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowPlusPlugin");
  window_plus_plugin_register_with_registrar(window_plus_registrar);
}
