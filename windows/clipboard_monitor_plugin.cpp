#include "include/clipboard_monitor/clipboard_monitor_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

// Inspiration:
// https://stackoverflow.com/questions/65840288/monitor-clipboard-changes-c-for-all-applications-windows
// https://toscode.gitee.com/leanflutter/window_manager/blob/main/windows/window_manager_plugin.cpp

namespace
{

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>,
                  std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
      channel = nullptr;

  class ClipboardMonitorPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    ClipboardMonitorPlugin(flutter::PluginRegistrarWindows *registrar);

    virtual ~ClipboardMonitorPlugin();

  private:
    flutter::PluginRegistrarWindows *registrar;
    HWND hWndNextViewer;

    // The ID of the WindowProc delegate registration.
    int window_proc_id = -1;

    // Called for top-level WindowProc delegation.
    std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    
    void monitorClipboard();
    void stopMonitoringClipboard();

    char* encode(const wchar_t* wstr, unsigned int codePage);
    wchar_t* decode(const char* encodedStr, unsigned int codePage);
    char* LPWSTRToString(LPWSTR lstr);
  };

  // static
  void ClipboardMonitorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "clipboard_monitor",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<ClipboardMonitorPlugin>(registrar);

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  ClipboardMonitorPlugin::ClipboardMonitorPlugin(flutter::PluginRegistrarWindows *registrar) : registrar(registrar)
  {
    window_proc_id =
        registrar->RegisterTopLevelWindowProcDelegate([this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
                                                      { return HandleWindowProc(hwnd, message, wparam, lparam); });
  }

  ClipboardMonitorPlugin::~ClipboardMonitorPlugin()
  {
    registrar->UnregisterTopLevelWindowProcDelegate(window_proc_id);
  }

  char* ClipboardMonitorPlugin::encode(const wchar_t* wstr, unsigned int codePage)
  {
      int sizeNeeded = WideCharToMultiByte(codePage, 0, wstr, -1, NULL, 0, NULL, NULL);
      char* encodedStr = new char[sizeNeeded];
      WideCharToMultiByte(codePage, 0, wstr, -1, encodedStr, sizeNeeded, NULL, NULL);
      return encodedStr;
  }

  wchar_t* ClipboardMonitorPlugin::decode(const char* encodedStr, unsigned int codePage)
  {
    int sizeNeeded = MultiByteToWideChar(codePage, 0, encodedStr, -1, NULL, 0);
    wchar_t* decodedStr = new wchar_t[sizeNeeded];
    MultiByteToWideChar(codePage, 0, encodedStr, -1, decodedStr, sizeNeeded );
    return decodedStr;
  }

  std::optional<LRESULT> ClipboardMonitorPlugin::HandleWindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
  {
    std::optional<LRESULT> result;

    LPWSTR  lstr; 
    HGLOBAL hglb; 

    switch (message)
    {
    case WM_CHANGECBCHAIN:
      // If the next window is closing, repair the chain.
      if ((HWND)wParam == hWndNextViewer)
        hWndNextViewer = (HWND)lParam;
      // Otherwise, pass the message to the next link.
      else if (hWndNextViewer != NULL)
        SendMessage(hWndNextViewer, message, wParam, lParam);
      break;
    case WM_DRAWCLIPBOARD:
      if (IsClipboardFormatAvailable(CF_UNICODETEXT) && OpenClipboard(nullptr)) {
        hglb = GetClipboardData(CF_UNICODETEXT);
        if (hglb != NULL) {
          lstr = (LPWSTR)GlobalLock(hglb);
          if (lstr != NULL) {
            char* str = encode(lstr, CP_UTF8);
//            printf("%s\n",str);
            channel->InvokeMethod("cliptext", std::make_unique<flutter::EncodableValue>(std::string(str)));
            delete[]str;
            GlobalUnlock(hglb);
          }
        }
        CloseClipboard();
      }
      SendMessage(hWndNextViewer, message, wParam, lParam);
      break;
    case WM_CLIPBOARDUPDATE:
      break;
    case WM_DESTROYCLIPBOARD:
      break;
    case WM_DESTROY:
      stopMonitoringClipboard();
      break;
    }
    return result;
  }

  constexpr unsigned int hash(const char *s, int off = 0)
  {
    return !s[off] ? 5381 : (hash(s, off + 1) * 33) ^ s[off];
  }

  void ClipboardMonitorPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    std::ostringstream version_stream;
    switch (hash(method_call.method_name().c_str()))
    {
    case hash("monitorClipboard"):
      monitorClipboard();
      break;
    case hash("stopMonitoringClipboard"):
      stopMonitoringClipboard();
      break;
    default:
      result->NotImplemented();
    }
  }

  void ClipboardMonitorPlugin::monitorClipboard()
  {
    HWND hWndRoot = GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
    hWndNextViewer = SetClipboardViewer(hWndRoot);
    // AddClipboardFormatListener(hWndRoot);
  }

  void ClipboardMonitorPlugin::stopMonitoringClipboard()
  {
    HWND hWndRoot = GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
    ChangeClipboardChain(hWndRoot, hWndNextViewer);
    // RemoveClipboardFormatListener(hWndRoot);
  }

} // namespace

void ClipboardMonitorPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
  ClipboardMonitorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
