# [window+](https://github.com/alexmercerind/window_plus)

As it should be.

## Features

- [x] Remembering window position & maximize state between application launches.
- [x] Frameless & customizable title-bar on Windows 10 or higher, with correct resize & movement hit-box.
- [x] Excellent backward compatibility, till Windows 7 SP1.
- [x] Fullscreen support.
- [ ] Overlay & always on-top support.
- [ ] Programmatic maximize, restore, size, move, close & destroy.
- [x] Customizable minimum window size.
- [x] Interception of window close event _e.g._ for code execution or clean-up before application quit.

## Docs

Initialize the plugin.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowPlus.ensureInitialized(
    // Pass a unique identifier for your application.
    application: 'com.alexmercerind.window_plus',
  );
}
```

Intercept window close event.

```dart
WindowPlus.instance.setWindowCloseHandler(() async {
  debugPrint('[WindowPlus.instance.setWindowCloseHandler] was called.');
  /// Show alert if some operation is pending.
  /// Perform clean-up.
  final bool shouldClose = await doSomethingBeforeClose();
  return shouldClose;
});
```

Enter or leave fullscreen.

```dart
WindowPlus.instance.setIsFullscreen(true);
```

Programmatic window control.

```dart
WindowPlus.instance.minimize();
WindowPlus.instance.maximize();
WindowPlus.instance.restore();
WindowPlus.instance.close();
/// Closes the window even if [WindowPlus.instance.setWindowCloseHandler] is set.
WindowPlus.instance.destroy();

/// Query.
final maximized = WindowPlus.instance.maximized;
final minimized = WindowPlus.instance.minimized;
final fullscreen = WindowPlus.instance.fullscreen;
```

Display custom title-bar (on Windows 10 or higher).


1. Default Windows look.

```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        /// Use a [Stack] to make your app's content to "bleed through the title-bar" & give a seamless look.
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            /// Actual application content.
            MyScreen(),
            /// Window title-bar that follows Windows' default design.
            /// It's height can be accessed using [WindowPlus.instance.captionHeight].
            /// Only shows on Windows 10 or higher. On lower Windows versions, the default window frame is kept. Thus, no need for rendering second one.
            WindowCaption(
              brightness: Brightness.dark,
              /// Optionally, [brightness] may be set to make window controls white or black (as default Windows 10+ design does).
            ),
          ],
        ),
      ),
    );
  }
```

2. Custom look.

See, `WindowCaptionArea`, `WindowMinimizeButton`, `WindowMaximizeButton`, `WindowRestoreButton`, `WindowCloseButton` or `WindowRestoreMaximizeButton`.
You can also make your own custom `Widget`s which follow your own design language.

## Setup

Following configuration is required.

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
-  gtk_widget_show(GTK_WIDGET(window));
+  gtk_widget_realize(GTK_WIDGET(window));
   g_autoptr(FlDartProject) project = fl_dart_project_new();
   fl_dart_project_set_dart_entrypoint_arguments(
       project, self->dart_entrypoint_arguments);
   FlView* view = fl_view_new(project);
-  gtk_widget_show(GTK_WIDGET(view));
+  gtk_widget_realize(GTK_WIDGET(view));
   gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
   fl_register_plugins(FL_PLUGIN_REGISTRY(view));
   gtk_widget_grab_focus(GTK_WIDGET(view));
```

## Platforms

- Windows
- Linux

## Why

Currently, `package:window_plus` is made to leverage requirements of [Harmonoid](https://github.com/harmonoid/harmonoid).

Initially, [Harmonoid](https://github.com/harmonoid/harmonoid) used [`package:bitsdojo_window`](https://github.com/bitsdojo/bitsdojo_window) for a _modern-looking window_ on Windows.
However, as time went by a number of issues were faced like:

- Resize borders lying inside the window (which made `Widget`s near window edges impossible to interract e.g. scrollbar)
- Windows 7 support.
- Other stability & crash issues.

I also didn't want a custom frame on GNU/Linux version of [Harmonoid](https://github.com/harmonoid/harmonoid), since it's "not the trend" (see: Discord, Visual Studio Code or Spotify). I believe for ensuring compatibility with _all_ Desktop Environments like KDE, XFCE, Gnome & other tiling ones, best is to customize the native window behavior as less as possible. On the other hand, most GNU/Linux Desktop Environments offer various customization options e.g. for changing window buttons, frames, borders & their style / position anyway, this will be unusable after implementing a custom frame.

This gave birth to [my fork](https://github.com/alexmercerind/bitsdojo_window), after mending things in a dirty manner (partially due to the fact that my style of writing code is different), the code became spaghetti & now it's something I can no longer trust.

Now `package:window_plus` is more cleaner (follows [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)) & has additional features like:
- Ability to intercept window close event.
- Remembering window position & state.

Stability & correct implementation is the primary concern here.
Now, this package _i.e._ `package:window_plus` can serve as a starting point for applications other than [Harmonoid](https://github.com/harmonoid/harmonoid).

## License

MIT License

Copyright © 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.

_It's free real estate._
