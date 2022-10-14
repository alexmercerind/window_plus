#include "include/window_plus/window_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <thread>

static constexpr auto kMethodChannelName = "com.alexmercerind/window_plus";
static constexpr auto kEnsureInitializedMethodName = "ensureInitialized";
static constexpr auto kGetStateMethodName = "getState";
static constexpr auto kCloseMethodName = "close";
static constexpr auto kDestroyMethodName = "destroy";
static constexpr auto kSetIsFullscreenMethodName = "setIsFullscreen";
static constexpr auto kWindowCloseReceivedMethodName = "windowCloseReceived";
static constexpr auto kMonitorSafeArea = 36;

#define WINDOW_PLUS_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), window_plus_plugin_get_type(), \
                              WindowPlusPlugin))

struct _WindowPlusPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
  GdkGeometry window_geometry;
};

G_DEFINE_TYPE(WindowPlusPlugin, window_plus_plugin, g_object_get_type())

static gboolean delete_event(GtkWidget* self, GdkEvent* event,
                             gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  fl_method_channel_invoke_method(plugin->channel,
                                  kWindowCloseReceivedMethodName,
                                  fl_value_new_null(), NULL, NULL, NULL);
  return TRUE;
}

// Called when a method call is received from Flutter.
static void window_plus_plugin_handle_method_call(WindowPlusPlugin* self,
                                                  FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, kEnsureInitializedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    g_signal_connect(window, "delete_event", G_CALLBACK(delete_event), self);
    // Configure minimum & initial |window| size.
    GdkRectangle workarea = {0};
    GdkDisplay* default_display = gdk_display_get_default();
    GdkMonitor* primary_monitor =
        gdk_display_get_primary_monitor(default_display);
    gdk_monitor_get_workarea(primary_monitor, &workarea);
    gboolean hd = workarea.width > 1366 && workarea.height > 768;
    gint base_width = hd ? 1280 : 1024, base_height = hd ? 720 : 640;
    gtk_window_set_default_size(window, base_width, base_height);
    GdkGeometry geometry;
    // TODO (@alexmercerind): Expose in public API.
    geometry.min_width = 1024;
    geometry.min_height = 640;
    geometry.base_width = base_width;
    geometry.base_height = base_height;
    gtk_window_set_geometry_hints(
        window, GTK_WIDGET(window), &geometry,
        static_cast<GdkWindowHints>(GDK_HINT_MIN_SIZE | GDK_HINT_BASE_SIZE));
    // Make |window| background black, to prevent a white splash on launch.
    g_autoptr(GtkCssProvider) style = gtk_css_provider_new();
    gtk_css_provider_load_from_data(GTK_CSS_PROVIDER(style),
                                    "window { background:none; }", -1, nullptr);
    GdkScreen* screen = gtk_window_get_screen(window);
    gtk_style_context_add_provider_for_screen(
        screen, GTK_STYLE_PROVIDER(style),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    try {
      FlValue* arguments = fl_method_call_get_args(method_call);
      FlValue* saved_window_state =
          fl_value_lookup_string(arguments, "savedWindowState");
      if (fl_value_get_type(saved_window_state) == FL_VALUE_TYPE_MAP) {
        gint x =
            fl_value_get_int(fl_value_lookup_string(saved_window_state, "x"));
        gint y =
            fl_value_get_int(fl_value_lookup_string(saved_window_state, "y"));
        gint width = fl_value_get_int(
            fl_value_lookup_string(saved_window_state, "width"));
        gint height = fl_value_get_int(
            fl_value_lookup_string(saved_window_state, "height"));
        gint maximized = fl_value_get_bool(
            fl_value_lookup_string(saved_window_state, "maximized"));
        workarea.x += kMonitorSafeArea;
        workarea.y += kMonitorSafeArea;
        workarea.width -= kMonitorSafeArea;
        workarea.height -= kMonitorSafeArea;
        // If |window| was |maximized|, then maximize it & set restore position
        // to center with default size.
        if (maximized) {
          gtk_window_maximize(window);
          gtk_window_set_position(window, GTK_WIN_POS_CENTER);
        } else {
          // If the window is within the |workarea| |GdkRectangle|, then restore
          // it to that position. Otherwise, restore it to the center of the
          // |workarea|.
          if (x >= workarea.x && x <= workarea.width && y >= workarea.y &&
              y <= workarea.height) {
            gtk_window_move(window, x, y);
            gtk_window_resize(window, width, height);
          } else {
            gtk_window_set_position(window, GTK_WIN_POS_CENTER);
          }
        }
      } else {
        // No saved state. Restore window to the center of the |workarea|.
        gtk_window_set_position(window, GTK_WIN_POS_CENTER);
      }
    } catch (...) {
      // No saved state. Restore window to the center of the |workarea|.
      gtk_window_set_position(window, GTK_WIN_POS_CENTER);
    }
    gtk_widget_show(GTK_WIDGET(view));
    gtk_widget_show(GTK_WIDGET(window));
    int64_t result = reinterpret_cast<int64_t>(window);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(result)));
  } else if (strcmp(method, kGetStateMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gint x = -1, y = -1, width = -1, height = -1;
    gtk_window_get_position(window, &x, &y);
    gtk_window_get_size(window, &width, &height);
    gboolean maximized = gtk_window_is_maximized(window);
    auto result = fl_value_new_map();
    fl_value_set_string_take(result, "x", fl_value_new_int(x));
    fl_value_set_string_take(result, "y", fl_value_new_int(y));
    fl_value_set_string_take(result, "width", fl_value_new_int(width));
    fl_value_set_string_take(result, "height", fl_value_new_int(height));
    fl_value_set_string_take(result, "maximized", fl_value_new_bool(maximized));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kCloseMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_close(window);
    response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kDestroyMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    std::thread([=]() {
      g_signal_emit_by_name(G_OBJECT(window), "destroy");
    }).detach();
    response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kSetIsFullscreenMethodName) == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    bool enabled =
        fl_value_get_bool(fl_value_lookup_string(arguments, "enabled"));
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    if (enabled) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
    response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void window_plus_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(window_plus_plugin_parent_class)->dispose(object);
}

static void window_plus_plugin_class_init(WindowPlusPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = window_plus_plugin_dispose;
}

static void window_plus_plugin_init(WindowPlusPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  window_plus_plugin_handle_method_call(plugin, method_call);
}

void window_plus_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  WindowPlusPlugin* plugin =
      WINDOW_PLUS_PLUGIN(g_object_new(window_plus_plugin_get_type(), nullptr));
  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kMethodChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
