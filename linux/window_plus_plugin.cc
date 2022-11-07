#include "include/window_plus/window_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <iostream>
#include <thread>

static constexpr auto kMethodChannelName = "com.alexmercerind/window_plus";
static constexpr auto kEnsureInitializedMethodName = "ensureInitialized";
static constexpr auto kGetStateMethodName = "getState";
static constexpr auto kCloseMethodName = "close";
static constexpr auto kDestroyMethodName = "destroy";
static constexpr auto kSetIsFullscreenMethodName = "setIsFullscreen";
static constexpr auto kWindowCloseReceivedMethodName = "windowCloseReceived";

// TODO (@alexmercerind): Expose in public API.
static constexpr auto kMonitorSafeArea = 8;
static constexpr auto kWindowDefaultWidth = 1024;
static constexpr auto kWindowDefaultHeight = 640;
static constexpr auto kWindowDefaultMinimumWidth = 960;
static constexpr auto kWindowDefaultMinimumHeight = 640;

#define WINDOW_PLUS_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), window_plus_plugin_get_type(), \
                              WindowPlusPlugin))

struct _WindowPlusPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
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

static void window_plus_plugin_handle_method_call(WindowPlusPlugin* self,
                                                  FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, kEnsureInitializedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    g_signal_connect(window, "delete_event", G_CALLBACK(delete_event), self);
    // Configure minimum size.
    gtk_window_set_default_size(window, kWindowDefaultWidth,
                                kWindowDefaultHeight);
    GdkGeometry geometry;
    geometry.min_width = kWindowDefaultMinimumWidth;
    geometry.min_height = kWindowDefaultMinimumHeight;
    geometry.base_width = kWindowDefaultWidth;
    geometry.base_height = kWindowDefaultHeight;
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
        // If |window| was |maximized|, then maximize it & set restore window
        // position to the center of the workspace with default size.
        if (maximized) {
          gtk_window_resize(window, width, height);
          gtk_window_set_position(window, GTK_WIN_POS_CENTER);
          gtk_window_maximize(window);
        } else {
          // If the |window| is present within bounds of any of the monitor(s),
          // then restore the |window| to the saved position & size.
          gboolean is_within_monitor = FALSE;
          GdkDisplay* display = gdk_display_get_default();
          gint n_monitors = gdk_display_get_n_monitors(display);
          for (gint i = 0; i < n_monitors; i++) {
            GdkMonitor* monitor = gdk_display_get_monitor(display, i);
            GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
            gdk_monitor_get_workarea(monitor, &workarea);
            gboolean success = !(workarea.x == 0 && workarea.y == 0 &&
                                 workarea.width == 0 && workarea.height == 0);
            if (success) {
              std::cout << "GdkRectangle{ " << workarea.x << ", " << workarea.y
                        << ", " << workarea.width << ", " << workarea.height
                        << " }" << std::endl;
              if (!is_within_monitor) {
                std::cout << "GtkWindow within bounds." << std::endl;
                gint monitor_left = workarea.x, monitor_top = workarea.y,
                     monitor_right = workarea.x + workarea.width,
                     monitor_bottom = workarea.y + workarea.height;
                monitor_left += kMonitorSafeArea;
                monitor_top += kMonitorSafeArea;
                monitor_right -= kMonitorSafeArea;
                monitor_bottom -= kMonitorSafeArea;
                if (x > monitor_left && x + width < monitor_right &&
                    y > monitor_top && y + height < monitor_bottom) {
                  is_within_monitor = TRUE;
                }
              }
            }
          }
          if (is_within_monitor) {
            gtk_window_resize(window, width, height);
            gtk_window_move(window, x, y);
          } else {
            // Not present within bounds, center with the already saved &
            // available |height| & |width| values.
            gtk_window_resize(window, width, height);
            gtk_window_set_position(window, GTK_WIN_POS_CENTER);
          }
        }
      } else {
        // No saved state. Restore window to the center of the workarea.
        gtk_window_set_position(window, GTK_WIN_POS_CENTER);
      }
    } catch (...) {
      // No saved state. Restore window to the center of the workarea.
      gtk_window_set_position(window, GTK_WIN_POS_CENTER);
    }
    // Show the Flutter |view| & |window|.
    gtk_widget_show(GTK_WIDGET(view));
    gtk_widget_show(GTK_WIDGET(window));
    int64_t result = reinterpret_cast<int64_t>(window);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(result)));
  } else if (strcmp(method, kGetStateMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gint x = -1, y = -1, width = -1, height = -1;
    gboolean maximized = gtk_window_is_maximized(window);
    if (!maximized) {
      // Current |window| position & size.
      gtk_window_get_position(window, &x, &y);
      gtk_window_get_size(window, &width, &height);
    } else {
      // Already cached |window| position & size, sent from Dart side.
      FlValue* arguments = fl_method_call_get_args(method_call);
      FlValue* saved_window_state =
          fl_value_lookup_string(arguments, "savedWindowState");
      if (fl_value_get_type(saved_window_state) == FL_VALUE_TYPE_MAP) {
        x = fl_value_get_int(fl_value_lookup_string(saved_window_state, "x"));
        y = fl_value_get_int(fl_value_lookup_string(saved_window_state, "y"));
        width = fl_value_get_int(
            fl_value_lookup_string(saved_window_state, "width"));
        height = fl_value_get_int(
            fl_value_lookup_string(saved_window_state, "height"));
      }
    }
    auto result = fl_value_new_map();
    // NOTE: Use existing cached |x|, |y|, |width| & |height| values if
    // |maximized| is `TRUE` i.e. sent from Dart side.
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
