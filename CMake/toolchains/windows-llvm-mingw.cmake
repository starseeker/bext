include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/WindowsCommon.cmake")
set(_bext_triple "${BEXT_WINDOWS_ARCH}-w64-mingw32")
# Use llvm-mingw's wrappers so the compiler, CRT, C++ library, linker, and
# resource compiler all come from the same developer-selected installation.
bext_windows_tool(CMAKE_C_COMPILER "${_bext_triple}-clang")
bext_windows_tool(CMAKE_CXX_COMPILER "${_bext_triple}-clang++")
set(CMAKE_C_COMPILER_TARGET "${_bext_triple}")
set(CMAKE_CXX_COMPILER_TARGET "${_bext_triple}")
bext_windows_tool(CMAKE_RC_COMPILER "${_bext_triple}-windres")
bext_windows_tool(CMAKE_AR "${_bext_triple}-ar")
bext_windows_tool(CMAKE_RANLIB "${_bext_triple}-ranlib")
bext_windows_tool(CMAKE_STRIP "${_bext_triple}-strip")
bext_windows_mingw_root()
