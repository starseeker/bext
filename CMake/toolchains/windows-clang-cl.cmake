include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/WindowsCommon.cmake")
bext_windows_tool(CMAKE_C_COMPILER clang-cl)
bext_windows_tool(CMAKE_CXX_COMPILER clang-cl)
bext_windows_tool(CMAKE_LINKER lld-link)
bext_windows_tool(CMAKE_AR llvm-lib)
bext_windows_tool(CMAKE_RC_COMPILER llvm-rc)
bext_windows_tool(CMAKE_MT llvm-mt)
set(CMAKE_C_COMPILER_TARGET "${BEXT_WINDOWS_ARCH}-pc-windows-msvc")
set(CMAKE_CXX_COMPILER_TARGET "${BEXT_WINDOWS_ARCH}-pc-windows-msvc")

if (NOT IS_DIRECTORY "${BEXT_WINDOWS_SDK_ROOT}/Windows Kits/10" OR
    NOT IS_DIRECTORY "${BEXT_WINDOWS_SDK_ROOT}/VC/Tools/MSVC")
  message(FATAL_ERROR
    "Set BEXT_WINDOWS_SDK_ROOT to a /winsysroot tree containing "
    "Windows Kits/10 and VC/Tools/MSVC. Supply the SDK and VC runtime files "
    "locally; bext does not download them.")
endif ()
# Keep the SDK versions used by clang-cl, lld-link and resource compilation in
# agreement.  Developers can pin versions in a tree containing several SDKs.
foreach(_kind SDK VC)
  set(BEXT_WINDOWS_${_kind}_VERSION "" CACHE STRING "Windows ${_kind} version")
  list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES BEXT_WINDOWS_${_kind}_VERSION)
endforeach()
if (NOT BEXT_WINDOWS_SDK_VERSION)
  file(GLOB _versions RELATIVE "${BEXT_WINDOWS_SDK_ROOT}/Windows Kits/10/Include"
    "${BEXT_WINDOWS_SDK_ROOT}/Windows Kits/10/Include/10.*")
  list(SORT _versions COMPARE NATURAL ORDER DESCENDING)
  if (_versions)
    list(GET _versions 0 BEXT_WINDOWS_SDK_VERSION)
  endif ()
endif ()
if (NOT BEXT_WINDOWS_VC_VERSION)
  file(GLOB _versions RELATIVE "${BEXT_WINDOWS_SDK_ROOT}/VC/Tools/MSVC"
    "${BEXT_WINDOWS_SDK_ROOT}/VC/Tools/MSVC/14.*")
  list(SORT _versions COMPARE NATURAL ORDER DESCENDING)
  if (_versions)
    list(GET _versions 0 BEXT_WINDOWS_VC_VERSION)
  endif ()
endif ()
set(_sdk_include "${BEXT_WINDOWS_SDK_ROOT}/Windows Kits/10/Include/${BEXT_WINDOWS_SDK_VERSION}")
set(_vc_include "${BEXT_WINDOWS_SDK_ROOT}/VC/Tools/MSVC/${BEXT_WINDOWS_VC_VERSION}/include")
if (NOT BEXT_WINDOWS_SDK_VERSION OR NOT BEXT_WINDOWS_VC_VERSION OR
    NOT IS_DIRECTORY "${_sdk_include}/um" OR NOT IS_DIRECTORY "${_vc_include}")
  message(FATAL_ERROR "The clang-cl SDK tree must contain versioned SDK and VC include directories")
endif ()
set(_sdk_flags "\"/winsysroot:${BEXT_WINDOWS_SDK_ROOT}\" /winsdkversion:${BEXT_WINDOWS_SDK_VERSION} /vctoolsversion:${BEXT_WINDOWS_VC_VERSION}")
string(APPEND CMAKE_C_FLAGS_INIT " ${_sdk_flags}")
string(APPEND CMAKE_CXX_FLAGS_INIT " ${_sdk_flags}")
# CMake invokes lld-link directly, without the compiler driver.
foreach(_kind EXE SHARED MODULE)
  string(APPEND CMAKE_${_kind}_LINKER_FLAGS_INIT " ${_sdk_flags}")
endforeach()
# CMake preprocesses resources with clang-cl, but passes the same flags to
# llvm-rc.  Use include switches understood by both tools, not /winsysroot.
foreach(_include "${_sdk_include}/um" "${_sdk_include}/shared"
    "${_sdk_include}/ucrt" "${_vc_include}")
  string(APPEND CMAKE_RC_FLAGS_INIT " /I\"${_include}\"")
endforeach()
list(APPEND CMAKE_FIND_ROOT_PATH "${BEXT_WINDOWS_SDK_ROOT}")
if (BEXT_WINDOWS_SYSROOT)
  list(APPEND CMAKE_FIND_ROOT_PATH "${BEXT_WINDOWS_SYSROOT}")
endif ()
list(REMOVE_DUPLICATES CMAKE_FIND_ROOT_PATH)
