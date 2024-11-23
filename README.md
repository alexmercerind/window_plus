# [window+](https://github.com/alexmercerind/window_plus)

> Work in progress. API may change.

As it should be. Extend view into title-bar.

## Setup

Following configuration is required.

### macOS

```diff
 import Cocoa
 import FlutterMacOS
+import window_plus
 
 class MainFlutterWindow: NSWindow {
     override func awakeFromNib() {
        WindowPlusPlugin.handleSingleInstance()
 
         let flutterViewController = FlutterViewController()
         let windowFrame = self.frame
         self.contentViewController = flutterViewController
         self.setFrame(windowFrame, display: true)
 
         RegisterGeneratedPlugins(registry: flutterViewController)
 
         super.awakeFromNib()
     }
 
+    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
+        super.order(place, relativeTo: otherWin)
+        WindowPlusPlugin.hideUntilReady()
+    }
 }
```

### Windows

Edit `windows/runner/win32_window.cpp` as:

```diff
   HWND window = CreateWindow(
-      window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
+      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
       Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
       Scale(size.width, scale_factor), Scale(size.height, scale_factor),
       nullptr, nullptr, GetModuleHandle(nullptr), this);
```

```diff
-    case WM_SIZE: {
-      RECT rect = GetClientArea();
-      if (child_content_ != nullptr) {
-        // Size and position the child window.
-        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
-                   rect.bottom - rect.top, TRUE);
-      }
-      return 0;
-    }

     case WM_ACTIVATE:
```

### Linux

Edit `linux/my_application.cc` as:

```diff
   FlView* view = fl_view_new(project);
   gtk_widget_show(GTK_WIDGET(view));
   gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
   fl_register_plugins(FL_PLUGIN_REGISTRY(view));
-  gtk_widget_grab_focus(GTK_WIDGET(view));
+  gtk_widget_hide(GTK_WIDGET(window));
```

## Single Instance

For enabling single instance support, follow the steps below.

### macOS

In `macos/Runner/MainFlutterWindow.swift`, add the following code:

```diff
 import Cocoa
 import FlutterMacOS
+import window_plus
 
 class MainFlutterWindow: NSWindow {
     override func awakeFromNib() {
+        WindowPlusPlugin.handleSingleInstance()
 
         let flutterViewController = FlutterViewController()
         let windowFrame = self.frame
         self.contentViewController = flutterViewController
         self.setFrame(windowFrame, display: true)
 
         RegisterGeneratedPlugins(registry: flutterViewController)
 
         super.awakeFromNib()
     }
 }
```

### Windows

In `windows/runner/main.cpp`, add the following code:

```diff
  #include <flutter/dart_project.h>
  #include <flutter/flutter_view_controller.h>
  #include <windows.h>

  #include "flutter_window.h"
  #include "utils.h"
+ #include "window_plus/window_plus_plugin_c_api.h"

  int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                        _In_ wchar_t* command_line, _In_ int show_command) {
+   ::WindowPlusPluginCApiHandleSingleInstance(NULL, NULL);

    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
      CreateAndAttachConsole();
    }
```

If you use custom window class name, then you can pass it as the first argument instead of `NULL`. Similarly, if you want to also account for your window's title, then you can pass it as the second argument instead of `NULL`.

### Linux

You need to edit your `linux/my_application.cc` file. See [this file for reference](https://github.com/alexmercerind/window_plus/blob/master/example/linux/my_application.cc).

Notice how `G_APPLICATION_HANDLES_OPEN` & `G_APPLICATION_HANDLES_COMMAND_LINE` [are implemented](https://github.com/alexmercerind/window_plus/blob/562407f7f316714024577ce5467a12ee8f99bc24/example/linux/my_application.cc#L135-L149).

Finally, forward the arguments to Dart / Flutter, with [`window_plus_plugin_handle_single_instance` call at the required location](https://github.com/alexmercerind/window_plus/blob/562407f7f316714024577ce5467a12ee8f99bc24/example/linux/my_application.cc#L24-L31).

## Platforms

- macOS
- Windows
- GNU/Linux

## License

MIT License

Copyright © 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.

_It's free real estate._
