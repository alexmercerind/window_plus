#ifndef WINDOW_PLUS_COMMON_H_
#define WINDOW_PLUS_COMMON_H_

static constexpr auto kMethodChannelName = "com.alexmercerind/window_plus";

static constexpr auto kEnsureInitializedMethodName = "ensureInitialized";
static constexpr auto kSetStateMethodName = "setState";

static constexpr auto kWindows10RTM = 10240;

typedef LONG NTSTATUS, *PNTSTATUS;
#define STATUS_SUCCESS (0x00000000)
typedef NTSTATUS(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);

#endif  // WINDOW_PLUS_COMMON_H_
