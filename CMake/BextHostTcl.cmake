include_guard(GLOBAL)
set(_BEXT_HOST_TCL_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Tcl scripts executed by the build need a native interpreter, independently
# of the target Tcl libraries.  Keep both its package path and prefix separate.
function(bext_add_host_tcl source_dir)
  set(BEXT_HOST_TCLSH "" CACHE FILEPATH "Existing native Tcl 8.6 interpreter (empty builds one)")
  set(BEXT_HOST_TCL_JOBS "${pcnt}" CACHE STRING "Parallelism for the native Tcl bootstrap")
  set(_expected "${BEXT_HOST_INSTALL_PREFIX}/bin/tclsh8.6${BEXT_HOST_EXECUTABLE_SUFFIX}")
  set(BEXT_HOST_TCL_TARGET "" CACHE INTERNAL "Native Tcl installation prerequisite" FORCE)
  if (BEXT_HOST_TCLSH AND NOT BEXT_HOST_TCLSH STREQUAL _expected)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E env
      --unset=TCL_LIBRARY --unset=TCLLIBPATH --unset=TK_LIBRARY
      "${BEXT_HOST_TCLSH}" "${_BEXT_HOST_TCL_MODULE_DIR}/../tcl/host/check.tcl"
      RESULT_VARIABLE _result OUTPUT_VARIABLE _output ERROR_VARIABLE _error)
    if (NOT "${_result}" STREQUAL "0" OR NOT _output MATCHES "Native Tcl 8[.]6[.]")
      message(FATAL_ERROR "BEXT_HOST_TCLSH must run Tcl 8.6 on the build host:\n${_output}\n${_error}")
    endif ()
    return()
  endif ()
  if (CMAKE_HOST_WIN32)
    message(FATAL_ERROR "Set BEXT_HOST_TCLSH to a native Tcl 8.6 interpreter on Windows; the native bootstrap currently uses Unix configure")
  endif ()
  set(_always 1)
  if (DEFINED EXT_BUILD_ALWAYS)
    set(_always "${EXT_BUILD_ALWAYS}")
  endif ()
  ExternalProject_Add(TCL_HOST_BLD
    BEXT_BUILD_ROLE HOST
    SOURCE_DIR "${_BEXT_HOST_TCL_MODULE_DIR}/../tcl/host"
    BUILD_ALWAYS ${_always}
    CMAKE_ARGS
      "-DTCL_SOURCE_DIR=${source_dir}"
      "-DCMAKE_INSTALL_PREFIX=${BEXT_HOST_INSTALL_PREFIX}"
      "-DBEXT_HOST_TCL_JOBS=${BEXT_HOST_TCL_JOBS}"
    ${LOG_OPTS}
    STEP_TARGETS install)
  set(BEXT_HOST_TCLSH "${_expected}" CACHE FILEPATH "Native Tcl 8.6 interpreter" FORCE)
  set(BEXT_HOST_TCL_TARGET TCL_HOST_BLD-install CACHE INTERNAL "Native Tcl installation prerequisite" FORCE)
endfunction()
