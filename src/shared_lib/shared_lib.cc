// #include "pch.h" // 通过cmake管理，可以不用手动包含预编译头

#include "shared_lib/shared_lib.h"

#ifdef _WIN32

BOOL APIENTRY DllMain(HMODULE hModule,
                      DWORD ul_reason_for_call,
                      LPVOID lpReserved) {
  // 避免未使用参数的编译警告
  (void)hModule;
  (void)ul_reason_for_call;
  (void)lpReserved;

  switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH:
      // DLL 被加载到进程时调用
      // 适合做：初始化资源、创建全局对象等
      // 注意：不要在这里调用 LoadLibrary！
      std::cout << "DLL_PROCESS_ATTACH" << std::endl;
      break;

    case DLL_THREAD_ATTACH:
      // 新线程被创建时调用（主线程除外）
      // 可选，如果不需要可以带 DLL_THREAD_DETACH 一起禁用
      std::cout << "DLL_THREAD_ATTACH" << std::endl;
      break;

    case DLL_THREAD_DETACH:
      // 线程退出时调用
      std::cout << "DLL_THREAD_DETACH" << std::endl;
      break;

    case DLL_PROCESS_DETACH:
      // DLL 从进程中卸载时调用
      // 适合做：释放资源、清理全局对象等
      std::cout << "DLL_PROCESS_DETACH" << std::endl;
      break;
  }
  return TRUE;  // 返回 TRUE 表示初始化成功
}
#endif

void SHAREDLIB_DECL shared_lib() { std::cout << "shared_lib" << std::endl; }