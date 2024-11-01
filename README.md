# [window+](https://github.com/alexmercerind/window_plus)

> Work in progress. API may change.

As it should be. Extend view into title-bar.

![0](https://user-images.githubusercontent.com/28951144/201383429-f1dd42bc-e53e-493b-b777-95024788212a.png)
![1](https://user-images.githubusercontent.com/28951144/201383435-34fedc2e-7cd9-46f9-86f7-b3f5a2a6f985.png)

<details>

<summary> Windows 7 </summary>

![3](https://user-images.githubusercontent.com/28951144/201383993-55c9c937-5e08-4627-843e-7ae63d382dfe.png)

</details>

## Features

- [x] Remembering window position & state at application launch & quit.
- [x] Frameless & customizable title-bar on Windows 10 RS1 or higher with correct resize & move hit-box.
- [x] Excellent backward compatibility, till Windows 7 SP1.
- [x] Fullscreen support.
- [ ] Overlay & always on-top support.
- [x] Programmatic maximize, restore, size, move, close & destroy.
- [x] Subscription to window resize, move, minimize, maximize & fullscreen events.
- [ ] Customizable minimum window size.
- [x] Multiple monitor(s) compatibility.
- [x] Single instance support & argument vector (`List<String> args`) forwarding.
- [ ] Windows 11 snap layouts.
- [x] Interception of window close event _e.g._ for code execution or clean-up before application quit.
- [x] Well tested & stable as fuck.

## Reference

#### Initializing the plugin

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /// Ideally, should be present right after [WidgetsFlutterBinding.ensureInitialized] & anywhere before [runApp].
  await WindowPlus.ensureInitialized(
    /// Pass a unique identifier for your application.
    application: 'com.alexmercerind.window_plus',
    /// Optional: 
    enableCustomFrame: true,     // true by default on Windows 10 RS1 or higher.
    enableEventStreams: false,    // true by default.
  );
}
```

#### Intercepting window close event

```dart
WindowPlus.instance.setWindowCloseHandler(() async {
  /// Show alert to the user. Likely if some operation is pending.
  /// Perform clean-up.
  final bool canWindowClose = await doSomethingBeforeClose();
  return canWindowClose;
});
```

#### Receiving single instance arguments

```dart
WindowPlus.instance.setSingleInstanceArgumentsHandler((List<String> args) {
  print(args.toString());
});
```

#### Entering or leaving fullscreen

```dart
WindowPlus.instance.setIsFullscreen(true);
```

#### Programmatically controlling window

```dart

/// Control window state.

WindowPlus.instance.minimize();
WindowPlus.instance.maximize();
WindowPlus.instance.restore();

WindowPlus.instance.move(40, 40);
WindowPlus.instance.resize(640, 480);

WindowPlus.instance.show();
WindowPlus.instance.hide();

/// Close the window.
/// [WindowPlus.instance.setWindowCloseHandler] may be used to intercept the action.

WindowPlus.instance.close();

/// Closes the window without respecting the [WindowPlus.instance.setWindowCloseHandler] handler.

WindowPlus.instance.destroy();

/// Query.
final bool maximized = await WindowPlus.instance.maximized;
final bool minimized = await WindowPlus.instance.minimized;
final bool fullscreen = await WindowPlus.instance.fullscreen;
final Rect size = await WindowPlus.instance.size;
final Offset position = await WindowPlus.instance.position;
```

#### Fetching available monitors

```dart
/// Get all the available monitors.

final List<Monitor> monitors = await WindowPlus.instance.monitors;
```

#### Subscribing to window events

```dart

WindowPlus.instance.maximizedStream.listen((bool value) {
  print(value.toString());
});

WindowPlus.instance.minimizedStream.listen((bool value) {
  print(value.toString());
});

WindowPlus.instance.fullscreenStream.listen((bool value) {
  print(value.toString());
});

WindowPlus.instance.sizeStream.listen((Rect size) {
  print(size.toString());
});

WindowPlus.instance.positionStream.listen((Offset position) {
  print(position.toString());
});

```

#### Displaying custom title-bar

*1. Default Windows look.*

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
              /// Optionally, [brightness] may be set to make window controls white or black (as default Windows 10+ design does).
              /// By default, this is decided by [MediaQuery].
              brightness: Brightness.dark,
              /// A [child] may be passed to render custom content in the title-bar.
            ),
          ],
        ),
      ),
    );
  }
```

*2. Custom look.*

You may compose your own window title-bar & controls. See following widgets for reference:
- `WindowCaptionArea`
- `WindowMinimizeButton`
- `WindowMaximizeButton`
- `WindowRestoreButton`
- `WindowCloseButton`
- `WindowRestoreMaximizeButton`

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
   FlView* view = fl_view_new(project);
   gtk_widget_show(GTK_WIDGET(view));
   gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
   fl_register_plugins(FL_PLUGIN_REGISTRY(view));
-  gtk_widget_grab_focus(GTK_WIDGET(view));
+  gtk_widget_hide(GTK_WIDGET(window));
```

## Single Instance

For enabling single instance support, follow the steps below.

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

- Windows
- GNU/Linux

## Why

[`package:window_plus`](https://github.com/alexmercerind/window_plus) is made to leverage requirements of [Harmonoid](https://github.com/harmonoid/harmonoid).

Initially, [Harmonoid](https://github.com/harmonoid/harmonoid) used [`package:bitsdojo_window`](https://github.com/bitsdojo/bitsdojo_window) for a _modern-looking window_ on Windows. However, as time went by a number of issues surfaced like:

- Resize border inside client area (which made `Widget`s near window borders hard to interract e.g. scrollbar).
- Windows 7 support.
- Other stability & crash issues.

This gave birth to [my fork of `package:bitsdojo_window`](https://github.com/alexmercerind/bitsdojo_window), where I fixed various issues I discovered. However, after mending things in a dirty manner (partially due to the fact that my style of writing code is different), the code became really spaghetti & now it's something I can no longer trust. Thus, I decided to create [`package:window_plus`](https://github.com/alexmercerind/window_plus) which is far more cleaner (follows [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)), correctly implemented & offers additional features like:

- Ability to intercept window close event.
- Remembering window position & state.
- Fullscreen support.

I also didn't want a custom frame on GNU/Linux version of [Harmonoid](https://github.com/harmonoid/harmonoid), since it's _"not the trend"_. See: Discord, Visual Studio Code or Spotify. I believe ensuring compatibility with _all_ desktop environments like KDE, XFCE, GNOME & other tiling ones is far more important. So, best is to customize the native window behavior as less as possible on GNU/Linux. On the other hand, most GNU/Linux desktop environments offer various customization options for changing window controls' style/position, window's frame/border etc. anyway. This functionality of host OS would be unusable after implementing a custom frame & rendering custom title bar with Flutter.

Stability & correct implementation is the primary concern here.

Now, [`package:window_plus`](https://github.com/alexmercerind/window_plus) can serve as a starting point for applications other than [Harmonoid](https://github.com/harmonoid/harmonoid).

## License

MIT License

Copyright © 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.

_It's free real estate._
