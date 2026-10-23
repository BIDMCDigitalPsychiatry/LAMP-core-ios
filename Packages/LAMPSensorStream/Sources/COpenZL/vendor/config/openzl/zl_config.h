// Hand-written replacement for the zl_config.h that OpenZL's CMake generates
// from build-scripts/cmake/zl_config.h.cmake. Values match the upstream
// defaults except x86-64 assembly, which is disabled for portability.

#ifndef OPENZL_ZS2_CONFIG_H
#define OPENZL_ZS2_CONFIG_H

#ifndef OPENZL_HAVE_X86_64_ASM
#define OPENZL_HAVE_X86_64_ASM ZL_HAVE_X86_64_ASM
#endif

#define ZL_ALLOW_INTROSPECTION 1

#define ZL_HAVE_X86_64_ASM 0

#endif
