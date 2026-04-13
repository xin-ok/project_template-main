#include "shared_lib/shared_lib.h"
#include "static_lib/static_lib.h"

int main() {
  static_lib();
  shared_lib();
  return 0;
}