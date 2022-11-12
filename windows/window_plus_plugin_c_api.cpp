// This file is a part of window_plus
// (https://github.com/alexmercerind/window_plus).
//
// Copyright (c) 2022 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved. Use of this source code is governed by MIT license that
// can be found in the LICENSE file.
#include "include/window_plus/window_plus_plugin_c_api.h"

#include <thread>

#include "common.h"
#include "window_plus_plugin.h"

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  int target_length =
      ::WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, -1,
                            nullptr, 0, nullptr, nullptr);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, -1, utf8_string.data(),
      target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

std::vector<std::string> GetCommandLineArguments() {
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }
  std::vector<std::string> command_line_arguments;
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }
  ::LocalFree(argv);
  return command_line_arguments;
}

void WindowPlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_plus::WindowPlusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void WindowPlusPluginCApiHandleSingleInstance(const wchar_t class_name[],
                                              const wchar_t window_name[]) {
  auto window = ::FindWindow(
      class_name == NULL ? kDefaultWindowClassName : class_name, window_name);
  if (window != NULL) {
    // Show existing |window| and capture the focus.
    ::ShowWindow(window, SW_SHOW);
    ::SetForegroundWindow(window);
    // Send first argument vector element to existing |window| with the help of
    // `WM_COPYDATA` Win32 window proc message.
    auto command_line_arguments = GetCommandLineArguments();
    auto cds = COPYDATASTRUCT{};
    cds.dwData = 1;
    if (!command_line_arguments.empty()) {
      cds.cbData =
          static_cast<DWORD>(command_line_arguments.front().size() + 1);
      cds.lpData = reinterpret_cast<void*>(
          const_cast<char*>(command_line_arguments.front().c_str()));
      ::SendMessage(window, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
    } else {
      cds.cbData = 1;
      cds.lpData = nullptr;
      ::SendMessage(window, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
    }
    // Keep current (new) process alive for a brief amount of time.
    std::this_thread::sleep_for(std::chrono::seconds(10));
    return ExitProcess(0);
  }
}
