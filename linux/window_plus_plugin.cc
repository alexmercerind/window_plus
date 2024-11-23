// This file is a part of window_plus (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that can be found in the LICENSE file.
#include "include/window_plus/window_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <iostream>
#include <thread>

// TODO(alexmercerind): Refactor to use GObject.

static constexpr auto kMethodChannelName = "com.alexmercerind/window_plus";

// Common:

static constexpr auto kEnsureInitializedMethodName = "ensureInitialized";
static constexpr auto kGetMinimumSizeMethodName = "getMinimumSize";
static constexpr auto kSetMinimumSizeMethodName = "setMinimumSize";
static constexpr auto kWindowCloseReceivedMethodName = "windowCloseReceived";
static constexpr auto kNotifyFirstFrameRasterizedMethodName = "notifyFirstFrameRasterized";
static constexpr auto kSingleInstanceDataReceivedMethodName = "singleInstanceDataReceived";
static constexpr auto kGetStateMethodName = "getState";
static constexpr auto kCloseMethodName = "close";
static constexpr auto kDestroyMethodName = "destroy";
static constexpr auto kGetIsMinimizedMethodName = "getMinimized";
static constexpr auto kGetIsMaximizedMethodName = "getMaximized";
static constexpr auto kGetIsFullscreenMethodName = "getIsFullscreen";
static constexpr auto kGetSizeMethodName = "getSize";
static constexpr auto kGetPositionMethodName = "getPosition";
static constexpr auto kGetMonitorsMethodName = "getMonitors";
static constexpr auto kSetIsFullscreenMethodName = "setIsFullscreen";
static constexpr auto kMaximizeMethodName = "maximize";
static constexpr auto kRestoreMethodName = "restore";
static constexpr auto kMinimizeMethodName = "minimize";
static constexpr auto kMoveMethodName = "move";
static constexpr auto kResizeMethodName = "resize";
static constexpr auto kHideMethodName = "hide";
static constexpr auto kShowMethodName = "show";

// GTK Exclusives:

static constexpr auto kWindowStateEventReceivedMethodName = "windowStateEventReceived";
static constexpr auto kConfigureEventReceivedMethodName = "configureEventReceived";

// TODO (alexmercerind): Expose in public API.

static constexpr auto kMonitorSafeArea = 8;
static constexpr auto kWindowDefaultWidth = 1280;
static constexpr auto kWindowDefaultHeight = 720;

#define WINDOW_PLUS_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), window_plus_plugin_get_type(), WindowPlusPlugin))

struct _WindowPlusPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(WindowPlusPlugin, window_plus_plugin, g_object_get_type())

WindowPlusPlugin* plugin = nullptr;

static GdkPoint get_cursor_position() {
  GdkDisplay* display = gdk_display_get_default();
  GdkSeat* seat = gdk_display_get_default_seat(display);
  GdkDevice* device = gdk_seat_get_pointer(seat);
  GdkPoint position = GdkPoint{0, 0};
  gdk_device_get_position(device, NULL, &position.x, &position.y);
  return position;
}

static gint get_default_window_width() {
  GdkPoint cursor = get_cursor_position();
  GdkDisplay* display = gdk_display_get_default();
  GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, cursor.x, cursor.y);
  GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
  gdk_monitor_get_workarea(monitor, &workarea);
  gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
  if (success) {
    gint monitor_width = workarea.width - 96;
    if (kWindowDefaultWidth > monitor_width) {
      return monitor_width;
    }
  }
  return kWindowDefaultWidth;
}

static gint get_default_window_height() {
  GdkPoint cursor = get_cursor_position();
  GdkDisplay* display = gdk_display_get_default();
  GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, cursor.x, cursor.y);
  GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
  gdk_monitor_get_workarea(monitor, &workarea);
  gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
  if (success) {
    gint monitor_height = workarea.height - 96;
    if (kWindowDefaultHeight > monitor_height) {
      return monitor_height;
    }
  }
  return kWindowDefaultHeight;
}

static gboolean delete_event(GtkWidget* self, GdkEvent* event, gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  g_autoptr(FlValue) arguments = fl_value_new_null();
  fl_method_channel_invoke_method(plugin->channel, kWindowCloseReceivedMethodName, arguments, NULL, NULL, NULL);
  return TRUE;
}

static gboolean window_state_event(GtkWidget* self, GdkEventWindowState* event, gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  gboolean minimized = event->new_window_state & GDK_WINDOW_STATE_ICONIFIED, maximized = event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED,
           fullscreen = event->new_window_state & GDK_WINDOW_STATE_FULLSCREEN;
  g_autoptr(FlValue) arguments = fl_value_new_map();
  fl_value_set_string_take(arguments, "minimized", fl_value_new_bool(minimized));
  fl_value_set_string_take(arguments, "maximized", fl_value_new_bool(maximized));
  fl_value_set_string_take(arguments, "fullscreen", fl_value_new_bool(fullscreen));
  fl_method_channel_invoke_method(plugin->channel, kWindowStateEventReceivedMethodName, arguments, NULL, NULL, NULL);
  return FALSE;
}

gboolean configure_event(GtkWidget* self, GdkEventConfigure* event, gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(plugin->registrar));
  GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));

  gint width = 0, height = 0;
  gtk_window_get_size(window, &width, &height);

  g_autoptr(FlValue) arguments = fl_value_new_map();

  FlValue* position = fl_value_new_map();
  fl_value_set_string_take(position, "x", fl_value_new_int(-1));
  fl_value_set_string_take(position, "y", fl_value_new_int(-1));
  fl_value_set_string_take(arguments, "position", position);

  FlValue* size = fl_value_new_map();
  fl_value_set_string_take(size, "left", fl_value_new_int(0));
  fl_value_set_string_take(size, "top", fl_value_new_int(0));
  fl_value_set_string_take(size, "width", fl_value_new_int(width));
  fl_value_set_string_take(size, "height", fl_value_new_int(height));
  fl_value_set_string_take(arguments, "size", size);

  fl_method_channel_invoke_method(plugin->channel, kConfigureEventReceivedMethodName, arguments, NULL, NULL, NULL);
  return FALSE;
}

static void window_plus_plugin_handle_method_call(WindowPlusPlugin* self, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, kEnsureInitializedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));

    // Disconnect all delete-event handlers first in flutter 3.10.1, which causes delete_event not working.
    // Issues from flutter/engine: https://github.com/flutter/engine/pull/40033
    guint handler_id = g_signal_handler_find(window, G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, view);

    FlValue* arguments = fl_method_call_get_args(method_call);
    FlValue* enable_event_streams = fl_value_lookup_string(arguments, "enableEventStreams");
    if (fl_value_get_type(enable_event_streams) == FL_VALUE_TYPE_BOOL) {
      if (fl_value_get_bool(enable_event_streams)) {
        g_signal_connect(window, "window-state-event", G_CALLBACK(window_state_event), self);
        g_signal_connect(window, "configure-event", G_CALLBACK(configure_event), self);
      }
    }

    if (handler_id > 0) {
      g_signal_handler_disconnect(window, handler_id);
    }

    // Handle delete-event signal for window close button interception.
    g_signal_connect(window, "delete-event", G_CALLBACK(delete_event), self);

    gint default_width = get_default_window_width(), default_height = get_default_window_height();
    gtk_window_set_default_size(window, default_width, default_height);
    GdkGeometry geometry;
    geometry.base_width = default_width;
    geometry.base_height = default_height;
    gtk_window_set_geometry_hints(window, GTK_WIDGET(window), &geometry, static_cast<GdkWindowHints>(GDK_HINT_BASE_SIZE));
    // Make |window| background black, to prevent a white splash on launch.
    g_autoptr(GtkCssProvider) style = gtk_css_provider_new();
    gtk_css_provider_load_from_data(GTK_CSS_PROVIDER(style), "GtkLayout { background-color: transparent; } GtkViewport { background-color: transparent; }", -1, nullptr);
    GdkScreen* screen = gtk_window_get_screen(window);
    gtk_style_context_add_provider_for_screen(screen, GTK_STYLE_PROVIDER(style), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    try {
      FlValue* saved_window_state = fl_value_lookup_string(arguments, "savedWindowState");
      if (fl_value_get_type(saved_window_state) == FL_VALUE_TYPE_MAP) {
        gint x = fl_value_get_int(fl_value_lookup_string(saved_window_state, "x"));
        gint y = fl_value_get_int(fl_value_lookup_string(saved_window_state, "y"));
        gint width = fl_value_get_int(fl_value_lookup_string(saved_window_state, "width"));
        gint height = fl_value_get_int(fl_value_lookup_string(saved_window_state, "height"));
        gint maximized = fl_value_get_bool(fl_value_lookup_string(saved_window_state, "maximized"));
        // Make the sure that |window| is present within bounds of any of the monitors.
        // Otherwise, center the |window| to the closest monitor (to the mouse cursor).
        // If the saved window dimensions exceed the monitor's |workarea|, then clamp to default window dimensions.
        // If the |window| is present within bounds of any of the monitor(s), then restore the |window| to the saved position & size.
        gboolean is_within_monitor = FALSE;
        GdkDisplay* display = gdk_display_get_default();
        gint n_monitors = gdk_display_get_n_monitors(display);
        for (gint i = 0; i < n_monitors; i++) {
          GdkMonitor* monitor = gdk_display_get_monitor(display, i);
          GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
          gdk_monitor_get_workarea(monitor, &workarea);
          gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
          if (success) {
            g_print("GdkRectangle{ %d, %d, %d, %d }\n", workarea.x, workarea.y, workarea.width, workarea.height);
            if (!is_within_monitor) {
              gint monitor_left = workarea.x, monitor_top = workarea.y, monitor_right = workarea.x + workarea.width, monitor_bottom = workarea.y + workarea.height;
              monitor_left += kMonitorSafeArea;
              monitor_top += kMonitorSafeArea;
              monitor_right -= kMonitorSafeArea;
              monitor_bottom -= kMonitorSafeArea;
              if (x > monitor_left && x + width < monitor_right && y > monitor_top && y + height < monitor_bottom) {
                g_print("GtkWindow within bounds.\n");
                is_within_monitor = TRUE;
              }
            }
          }
        }
        if (is_within_monitor) {
          gtk_window_resize(window, width, height);
          gtk_window_move(window, x, y);
        } else {
          // Not present within bounds, center with the already saved & available |height| & |width| values.
          GdkPoint cursor = get_cursor_position();
          GdkDisplay* display = gdk_display_get_default();
          GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, cursor.x, cursor.y);
          GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
          gdk_monitor_get_workarea(monitor, &workarea);
          gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
          if (success) {
            gtk_window_resize(window, default_width, default_height);
            gtk_window_set_position(window, GTK_WIN_POS_CENTER);
          }
        }
        // Maximize the |window| if it was maximized when it was closed.
        if (maximized) {
          gtk_window_maximize(window);
        }
      } else {
        // No saved state. Restore window to the center of the workarea.
        // Not present within bounds, center with the already saved & available |height| & |width| values.
        GdkPoint cursor = get_cursor_position();
        GdkDisplay* display = gdk_display_get_default();
        GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, cursor.x, cursor.y);
        GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
        gdk_monitor_get_workarea(monitor, &workarea);
        gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
        if (success) {
          gtk_window_resize(window, default_width, default_height);
          gtk_window_set_position(window, GTK_WIN_POS_CENTER);
        }
      }
    } catch (...) {
      // No saved state. Restore window to the center of the workarea.
      // Not present within bounds, center with the already saved & available |height| & |width| values.
      GdkPoint cursor = get_cursor_position();
      GdkDisplay* display = gdk_display_get_default();
      GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, cursor.x, cursor.y);
      GdkRectangle workarea = GdkRectangle{0, 0, 0, 0};
      gdk_monitor_get_workarea(monitor, &workarea);
      gboolean success = !(workarea.x == 0 && workarea.y == 0 && workarea.width == 0 && workarea.height == 0);
      if (success) {
        // Make sure to clamp ignore |width| & |height| if they exceed the current workarea dimensions and use default dimensions instead.
        gtk_window_resize(window, default_width, default_height);
        gtk_window_set_position(window, GTK_WIN_POS_CENTER);
      }
    }
    int64_t result = reinterpret_cast<int64_t>(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(result)));
  } else if (strcmp(method, kSetMinimumSizeMethodName) == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    gint width = (gint)fl_value_get_float(fl_value_lookup_string(arguments, "width"));
    gint height = (gint)fl_value_get_float(fl_value_lookup_string(arguments, "height"));
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWidget* window = GTK_WIDGET(gtk_widget_get_toplevel(view));
    gtk_widget_set_size_request(window, width, height);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kGetMinimumSizeMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWidget* window = GTK_WIDGET(gtk_widget_get_toplevel(view));
    gint width = 0, height = 0;
    gtk_widget_get_size_request(window, &width, &height);
    FlValue* result = fl_value_new_map();
    fl_value_set_string_take(result, "width", fl_value_new_float((gdouble)width));
    fl_value_set_string_take(result, "height", fl_value_new_float((gdouble)height));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kNotifyFirstFrameRasterizedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    // Show the Flutter |view| & |window|.
    gtk_widget_show(GTK_WIDGET(view));
    gtk_widget_show(GTK_WIDGET(window));
    // Capture user focus & present the |window| on top of other windows.
    gtk_window_present(window);
    gtk_widget_grab_focus(view);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kGetStateMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    GdkWindowState state = gdk_window_get_state(gdk_window);
    gint x = -1, y = -1, width = -1, height = -1;
    gboolean maximized = state & GDK_WINDOW_STATE_MAXIMIZED;
    if (!maximized) {
      // Current |window| position & size.
      gtk_window_get_position(window, &x, &y);
      gtk_window_get_size(window, &width, &height);
    } else {
      // Already cached |window| position & size, sent from Dart side.
      FlValue* arguments = fl_method_call_get_args(method_call);
      FlValue* saved_window_state = fl_value_lookup_string(arguments, "savedWindowState");
      if (fl_value_get_type(saved_window_state) == FL_VALUE_TYPE_MAP) {
        x = fl_value_get_int(fl_value_lookup_string(saved_window_state, "x"));
        y = fl_value_get_int(fl_value_lookup_string(saved_window_state, "y"));
        width = fl_value_get_int(fl_value_lookup_string(saved_window_state, "width"));
        height = fl_value_get_int(fl_value_lookup_string(saved_window_state, "height"));
      }
    }
    auto result = fl_value_new_map();
    // NOTE: Use existing cached |x|, |y|, |width| & |height| values if |maximized| is TRUE i.e. sent from Dart side.
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
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kDestroyMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    std::thread([=]() { g_signal_emit_by_name(G_OBJECT(window), "destroy"); }).detach();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kGetIsMinimizedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GdkWindow* window = gtk_widget_get_window(gtk_widget_get_toplevel(view));
    GdkWindowState state = gdk_window_get_state(window);
    g_autoptr(FlValue) result = fl_value_new_bool(state & GDK_WINDOW_STATE_ICONIFIED);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kGetIsMaximizedMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GdkWindow* window = gtk_widget_get_window(gtk_widget_get_toplevel(view));
    GdkWindowState state = gdk_window_get_state(window);
    g_autoptr(FlValue) result = fl_value_new_bool(state & GDK_WINDOW_STATE_MAXIMIZED);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kGetIsFullscreenMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GdkWindow* window = gtk_widget_get_window(gtk_widget_get_toplevel(view));
    GdkWindowState state = gdk_window_get_state(window);
    g_autoptr(FlValue) result = fl_value_new_bool(state & GDK_WINDOW_STATE_FULLSCREEN);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kGetSizeMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gint width = 0, height = 0;
    gtk_window_get_size(window, &width, &height);
    auto result = fl_value_new_map();
    fl_value_set_string_take(result, "left", fl_value_new_int(0));
    fl_value_set_string_take(result, "top", fl_value_new_int(0));
    fl_value_set_string_take(result, "width", fl_value_new_int(width));
    fl_value_set_string_take(result, "height", fl_value_new_int(height));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kGetPositionMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gint dx = 0, dy = 0;
    gtk_window_get_position(window, &dx, &dy);
    auto result = fl_value_new_map();
    fl_value_set_string_take(result, "dx", fl_value_new_int(dx));
    fl_value_set_string_take(result, "dy", fl_value_new_int(dy));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kGetMonitorsMethodName) == 0) {
    g_autoptr(FlValue) result = fl_value_new_list();
    GdkDisplay* display = gdk_display_get_default();
    gint n_monitors = gdk_display_get_n_monitors(display);
    for (gint i = 0; i < n_monitors; i++) {
      GdkMonitor* monitor = gdk_display_get_monitor(display, i);
      GdkRectangle workarea, bounds;
      gdk_monitor_get_workarea(monitor, &workarea);
      gdk_monitor_get_geometry(monitor, &bounds);

      auto fl_monitor = fl_value_new_map();

      FlValue* fl_workarea = fl_value_new_map();
      fl_value_set_string_take(fl_workarea, "left", fl_value_new_int(workarea.x));
      fl_value_set_string_take(fl_workarea, "top", fl_value_new_int(workarea.y));
      fl_value_set_string_take(fl_workarea, "width", fl_value_new_int(workarea.width));
      fl_value_set_string_take(fl_workarea, "height", fl_value_new_int(workarea.height));

      FlValue* fl_bounds = fl_value_new_map();
      fl_value_set_string_take(fl_bounds, "left", fl_value_new_int(bounds.x));
      fl_value_set_string_take(fl_bounds, "top", fl_value_new_int(bounds.y));
      fl_value_set_string_take(fl_bounds, "width", fl_value_new_int(bounds.width));
      fl_value_set_string_take(fl_bounds, "height", fl_value_new_int(bounds.height));

      fl_value_set_string_take(fl_monitor, "workarea", fl_workarea);
      fl_value_set_string_take(fl_monitor, "bounds", fl_bounds);

      fl_value_append_take(result, fl_monitor);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, kSetIsFullscreenMethodName) == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    bool enabled = fl_value_get_bool(fl_value_lookup_string(arguments, "enabled"));
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    if (enabled) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, kMaximizeMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_maximize(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kRestoreMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_unmaximize(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kMinimizeMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_iconify(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kMoveMethodName) == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    gint x = fl_value_get_int(fl_value_lookup_string(arguments, "x"));
    gint y = fl_value_get_int(fl_value_lookup_string(arguments, "y"));
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_move(window, x, y);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kResizeMethodName) == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    gint width = fl_value_get_int(fl_value_lookup_string(arguments, "width"));
    gint height = fl_value_get_int(fl_value_lookup_string(arguments, "height"));
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    gtk_window_resize(window, width, height);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kHideMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWidget* window = gtk_widget_get_toplevel(view);
    gtk_widget_hide(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, kShowMethodName) == 0) {
    GtkWidget* view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
    GtkWidget* window = gtk_widget_get_toplevel(view);
    gtk_widget_show(window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void window_plus_plugin_dispose(GObject* object) { G_OBJECT_CLASS(window_plus_plugin_parent_class)->dispose(object); }

static void window_plus_plugin_class_init(WindowPlusPluginClass* klass) { G_OBJECT_CLASS(klass)->dispose = window_plus_plugin_dispose; }

static void window_plus_plugin_init(WindowPlusPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  WindowPlusPlugin* plugin = WINDOW_PLUS_PLUGIN(user_data);
  window_plus_plugin_handle_method_call(plugin, method_call);
}

void window_plus_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  plugin = WINDOW_PLUS_PLUGIN(g_object_new(window_plus_plugin_get_type(), nullptr));
  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), kMethodChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb, plugin, g_object_unref);
}

void window_plus_plugin_handle_single_instance(gchar** arguments) {
  if (plugin) {
    g_autoptr(FlValue) result = fl_value_new_list();
    for (gint i = 0; i < g_strv_length(arguments); i++) {
      fl_value_append_take(result, fl_value_new_string(arguments[i]));
    }
    fl_method_channel_invoke_method(plugin->channel, kSingleInstanceDataReceivedMethodName, result, nullptr, nullptr, nullptr);
  }
}
