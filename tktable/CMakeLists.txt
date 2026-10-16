if (USE_BRLCAD)

  # Decide if we're using Tktable
  cad_enable(TKTABLE "archer")

endif (USE_BRLCAD)


# Unfortunately, there does not appear to be a reliable way to test for the
# presence of the Tktable package on a system Tcl/Tk.  We key off of the
# presence of the TK_BLD target, but that may produce a false negative if the
# Tk build is off but we still need Tktable.  As far as I can tell the "package
# require Tktable" test (which is what is required to properly test for an
# available Tktable package) can ONLY be performed successfully on a system that
# supports creation of a graphics window. Window creation isn't typically
# available on continuous integration runners, which means the test will always
# fail there even when it shouldn't.

# We try to find the Tktable library, since that's the only test we can do without
# needing the graphical invocation.  Unfortunately, even a find_library search
# looking for libTktable isn't completely reliable, since the presence of a shared
# library is not a guarantee it is correctly hooked into the "package require"
# mechanism of the system Tcl/Tk we want to use.  (It is possible to have more
# than one Tcl/Tk on a system - this situation is known to have occurred on the
# Mac when 3rd party package managers are used, for example.)

if (ENABLE_TK AND NOT DEFINED ENABLE_TKTABLE AND NOT DISABLE_TKTABLE)
  set(ENABLE_TKTABLE ON)
endif (ENABLE_TK AND NOT DEFINED ENABLE_TKTABLE AND NOT DISABLE_TKTABLE)

if (NOT ENABLE_TKTABLE)
  find_library(TKTABLE_SYS_LIBRARY NAMES tktable Tktable Tktable2)

  if (NOT TKTABLE_SYS_LIBRARY AND NOT DEFINED ENABLE_TKTABLE)
    set(ENABLE_TKTABLE "ON" CACHE BOOL "Enable Tktable build")
  endif (NOT TKTABLE_SYS_LIBRARY AND NOT DEFINED ENABLE_TKTABLE)

endif (NOT ENABLE_TKTABLE)
set(ENABLE_TKTABLE "${ENABLE_TKTABLE}" CACHE BOOL "Enable Tktable build")

if (ENABLE_TKTABLE)

  git_submodule_init(tktable CMakeLists.txt)

  RegisterDeps(TKTABLE)

  set(TKTABLE_HOST_ARGS)
  if (CMAKE_CROSSCOMPILING)
    ExternalProject_Add(TKTABLE_HOST_BLD
      BEXT_BUILD_ROLE HOST
      SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/host"
      BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
      CMAKE_ARGS
        "-DTKTABLE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/tktable"
        "-DCMAKE_INSTALL_PREFIX=${BEXT_HOST_INSTALL_PREFIX}"
      STEP_TARGETS install)
    list(APPEND TKTABLE_HOST_ARGS
      "-DTKTABLE_HDR_EXECUTABLE=${BEXT_HOST_INSTALL_PREFIX}/bin/tktable_hdr${BEXT_HOST_EXECUTABLE_SUFFIX}"
      "-DTCL_TCLSH=${BEXT_HOST_TCLSH}" "-DTCLSH_VERSION_STRING=8.6")
  endif ()

  ExternalProject_Add(TKTABLE_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/tktable"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    PATCH_COMMAND ${PATCH_EXECUTABLE} -E -p1 ${PATCH_OPTIONS}
      -i "${CMAKE_CURRENT_SOURCE_DIR}/tktable_cross.patch"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CMAKE_SOURCE_DIR}/CMake/FindTCL.cmake" "<SOURCE_DIR>/CMake/FindTCL.cmake"
    CMAKE_ARGS
    ${TKTABLE_HOST_ARGS}
    ${BUILD_TYPE_SPECIFIER}
    -DBIN_DIR=$<IF:$<BOOL:${WIN32}>,${LIB_DIR},${BIN_DIR}>
    -DLIB_DIR=${LIB_DIR}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BUNDLE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_RPATH=${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}/${RPATH_SUFFIX}
    -DINCLUDE_DIR=${INCLUDE_DIR}
    -DSHARED_DIR=${LIB_DIR}
    -DTCL_ENABLE_TK=ON
    -DTCL_ROOT=$<$<BOOL:${TCL_TARGET}>:${CMAKE_BUNDLE_INSTALL_PREFIX}>
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(TKTABLE TKTABLE_DEPENDS)
  ExternalProject_Add_StepDependencies(TKTABLE_BLD patch "${CMAKE_SOURCE_DIR}/CMake/FindTCL.cmake")
  if (CMAKE_CROSSCOMPILING)
    ExternalProject_Add_StepDependencies(TKTABLE_BLD configure TKTABLE_HOST_BLD-install)
    if (BEXT_HOST_TCL_TARGET)
      ExternalProject_Add_StepDependencies(TKTABLE_BLD configure ${BEXT_HOST_TCL_TARGET})
    endif ()
  endif ()

  # Copy the license into position in CMAKE_BUNDLE_INSTALL_PREFIX
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/tktable/license.txt
    ${DOC_LICENSE_DIR}/tktable.txt
    COPYONLY
    )

endif (ENABLE_TKTABLE)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8

