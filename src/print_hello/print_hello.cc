#include <iostream>

#ifdef __has_include
#if __has_include(<print>)
#include <print>
#define HAS_PRINT 1
#endif
#endif

int main() {
  // 包含一个 UTF-8 编码的中文字符（"中" 的 UTF-8 编码是 E4 B8 AD）
#ifdef HAS_PRINT
  std::println("{}", "你好");
#else
  std::cout << "你好" << std::endl;
#endif
  return 0;
}
