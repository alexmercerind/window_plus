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

I also didn't want a custom frame on GNU/Linux version of [Harmonoid](https://github.com/harmonoid/harmonoid), since it's "not the trend" (see: Discord, Visual Studio Code or Spotify). I believe for ensuring compatibility with _all_ Desktop Environments like KDE, XFCE, Gnome & other tiling ones, best is to customize native behavior as less as possible. On the other hand, most GNU/Linux Desktop Environments offer various customization options e.g. changing window buttons, frames, borders & their style / position anyway, this will be unusable after implementing a custom frame.

This gave birth to [my fork](https://github.com/alexmercerind/bitsdojo_window), after mending things in a dirty manner (partially due to the fact that my style of writing code being different), the code became spaghetti & now it's something I can no longer trust.

Now `package:window_plus` is more cleaner (follows [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)) & has additional features like:
- Ability to intercept window close event.
- Remembering window position & state.

Stability & correct implementation is the primary concern here. Now, this package can serve as a starting point for applications other than [Harmonoid](https://github.com/harmonoid/harmonoid).

## License

MIT License

Copyright © 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.

_It's free real estate._
