include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Windows)
set(BEXT_WINDOWS_ARCH x86_64 CACHE STRING "Windows target architecture")
set_property(CACHE BEXT_WINDOWS_ARCH PROPERTY STRINGS x86_64 i686 aarch64)
if (NOT BEXT_WINDOWS_ARCH MATCHES "^(x86_64|i686|aarch64)$")
  message(FATAL_ERROR "Unsupported BEXT_WINDOWS_ARCH: ${BEXT_WINDOWS_ARCH}")
endif ()
set(CMAKE_SYSTEM_PROCESSOR "${BEXT_WINDOWS_ARCH}")
set(BEXT_TOOLCHAIN_ROOT "" CACHE PATH "Directory containing the cross toolchain's bin directory")
set(BEXT_WINDOWS_SYSROOT "" CACHE PATH "Windows dependency search root")
set(BEXT_WINDOWS_SDK_ROOT "" CACHE PATH "Windows SDK and VC tools tree for clang-cl /winsysroot")
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  BEXT_WINDOWS_ARCH BEXT_TOOLCHAIN_ROOT BEXT_WINDOWS_SYSROOT BEXT_WINDOWS_SDK_ROOT)
list(REMOVE_DUPLICATES CMAKE_TRY_COMPILE_PLATFORM_VARIABLES)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_USE_PACKAGE_REGISTRY OFF)
set(CMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY OFF)

function(bext_windows_tool variable)
  # An explicit toolchain root must not silently fall back to tools from a
  # different installation.  Explicit CMAKE_* tool overrides remain supported.
  if (BEXT_TOOLCHAIN_ROOT)
    find_program(${variable} NAMES ${ARGN}
      PATHS "${BEXT_TOOLCHAIN_ROOT}/bin" NO_DEFAULT_PATH
      NO_CMAKE_FIND_ROOT_PATH REQUIRED)
  else ()
    find_program(${variable} NAMES ${ARGN} NO_CMAKE_FIND_ROOT_PATH REQUIRED)
  endif ()
  set(${variable} "${${variable}}" PARENT_SCOPE)
endfunction()

macro(bext_windows_mingw_root)
  if (NOT BEXT_WINDOWS_SYSROOT)
    get_filename_component(_bext_compiler_bin "${CMAKE_C_COMPILER}" DIRECTORY)
    get_filename_component(_bext_compiler_prefix "${_bext_compiler_bin}/.." ABSOLUTE)
    set(_bext_candidate "${_bext_compiler_prefix}/${BEXT_WINDOWS_ARCH}-w64-mingw32")
    if (IS_DIRECTORY "${_bext_candidate}")
      set(BEXT_WINDOWS_SYSROOT "${_bext_candidate}" CACHE PATH "Windows dependency search root" FORCE)
    else ()
      message(FATAL_ERROR "Set BEXT_WINDOWS_SYSROOT to the installed MinGW target root")
    endif ()
  endif ()
  if (NOT IS_DIRECTORY "${BEXT_WINDOWS_SYSROOT}")
    message(FATAL_ERROR "Windows dependency root does not exist: ${BEXT_WINDOWS_SYSROOT}")
  endif ()
  # GCC distributions and llvm-mingw wrappers already know where their runtime
  # headers/libraries live.  Do not impose a different compiler --sysroot.
  list(APPEND CMAKE_FIND_ROOT_PATH "${BEXT_WINDOWS_SYSROOT}")
  list(REMOVE_DUPLICATES CMAKE_FIND_ROOT_PATH)
endmacro()
