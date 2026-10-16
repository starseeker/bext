cmake_minimum_required(VERSION 3.26)
project(BextNativeTcl LANGUAGES C)
include(ExternalProject)

if (CMAKE_CROSSCOMPILING OR WIN32)
  message(FATAL_ERROR "The Tcl bootstrap requires a native Unix compiler")
endif ()
if (NOT EXISTS "${TCL_SOURCE_DIR}/unix/configure")
  message(FATAL_ERROR "TCL_SOURCE_DIR must name the bundled Tcl source tree")
endif ()
foreach(path "${TCL_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" "${CMAKE_INSTALL_PREFIX}"
    "${CMAKE_C_COMPILER}" "${CMAKE_AR}" "${CMAKE_RANLIB}")
  if (path MATCHES " ")
    message(FATAL_ERROR "The Tcl Unix bootstrap does not support paths containing spaces: ${path}")
  endif ()
endforeach()
find_program(TCL_HOST_MAKE NAMES gmake make REQUIRED)
set(BEXT_HOST_TCL_JOBS 1 CACHE STRING "Parallelism for the native Tcl bootstrap")
if (NOT BEXT_HOST_TCL_JOBS MATCHES "^[1-9][0-9]*$")
  set(BEXT_HOST_TCL_JOBS 1)
endif ()

# Configure this script in the native CMake context, where flags and compiler
# tools come from the host toolchain, not the outer Windows configuration.
set(TCL_NATIVE_SOURCE "${CMAKE_BINARY_DIR}/tcl-core-prefix/src/tcl-core")
set(TCL_NATIVE_BINARY "${CMAKE_BINARY_DIR}/tcl-core-prefix/src/tcl-core-build")
string(TOUPPER "${CMAKE_BUILD_TYPE}" _config)
set(TCL_NATIVE_CFLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${_config}}")
set(TCL_NATIVE_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS_${_config}}")
foreach(_option TARGET EXTERNAL_TOOLCHAIN)
  if (CMAKE_C_COMPILER_${_option})
    string(APPEND TCL_NATIVE_CFLAGS
      " ${CMAKE_C_COMPILE_OPTIONS_${_option}}${CMAKE_C_COMPILER_${_option}}")
  endif ()
endforeach()
set(_compile_sysroot "${CMAKE_SYSROOT}")
set(_link_sysroot "${CMAKE_SYSROOT}")
if (DEFINED CMAKE_SYSROOT_COMPILE)
  set(_compile_sysroot "${CMAKE_SYSROOT_COMPILE}")
endif ()
if (DEFINED CMAKE_SYSROOT_LINK)
  set(_link_sysroot "${CMAKE_SYSROOT_LINK}")
endif ()
if (_compile_sysroot)
  string(APPEND TCL_NATIVE_CFLAGS " ${CMAKE_C_COMPILE_OPTIONS_SYSROOT}${_compile_sysroot}")
endif ()
if (_link_sysroot)
  string(APPEND TCL_NATIVE_LDFLAGS " ${CMAKE_C_COMPILE_OPTIONS_SYSROOT}${_link_sysroot}")
endif ()
configure_file(configure.cmake.in configure.cmake @ONLY)
set(_make "${CMAKE_COMMAND}" -E env --unset=MAKEFLAGS --unset=MFLAGS
  --unset=TCL_LIBRARY --unset=TCLLIBPATH --unset=TK_LIBRARY "${TCL_HOST_MAKE}")
ExternalProject_Add(tcl-core
  URL "${TCL_SOURCE_DIR}"
  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_BINARY_DIR}/configure.cmake"
  BUILD_COMMAND ${_make} -j${BEXT_HOST_TCL_JOBS} binaries
  INSTALL_COMMAND ${_make} -j1 install-binaries install-libraries install-headers
  LOG_CONFIGURE ON LOG_BUILD ON LOG_INSTALL ON LOG_OUTPUT_ON_FAILURE ON)
ExternalProject_Add_StepDependencies(tcl-core configure "${CMAKE_BINARY_DIR}/configure.cmake")
# Build only the core interpreter and script library.  In particular, target
# Itcl/Tk extension DLLs must never be loaded into this native interpreter.
install(CODE "
  execute_process(COMMAND \"${CMAKE_COMMAND}\" -E env
    --unset=TCL_LIBRARY --unset=TCLLIBPATH --unset=TK_LIBRARY
    \"${CMAKE_INSTALL_PREFIX}/bin/tclsh8.6\"
    \"${CMAKE_CURRENT_SOURCE_DIR}/check.tcl\"
    RESULT_VARIABLE result)
  if (NOT \"\${result}\" STREQUAL \"0\")
    message(FATAL_ERROR \"The installed native Tcl interpreter failed validation\")
  endif ()
")
