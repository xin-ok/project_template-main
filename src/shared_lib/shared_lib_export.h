#pragma once

// clang-format off
#ifdef _WIN32
#  ifdef SHAREDLIB_EXPORT
#    define SHAREDLIB_DECL __declspec(dllexport)
#  else
#    define SHAREDLIB_DECL __declspec(dllimport)
#  endif  
#else
#  define SHAREDLIB_DECL
#endif
// clang-format on