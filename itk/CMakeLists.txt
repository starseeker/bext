# Unfortunately, there does not appear to be a reliable way to test for the
# presence of the Itk package on a system Tcl/Tk.  We key off of the presence
# of the TK_BLD and ITCL_BLD targets, but that may produce a false negative if
# those builds are both off but we still need Itk.  As far as I can tell the
# "package require Itk" test (which is what is required to properly test for an
# available Itk package) can ONLY be performed successfully on a system that
# supports creation of a graphics window. Window creation isn't typically
# available on continuous integration runners, which means the test will always
# fail there even when it shouldn't.

# We try to find the itk library, since that's the only test we can do without
# needing the graphical invocation.  Unfortunately, even a find_library search
# looking for libitk isn't completely reliable, since the presence of a shared
# library is not a guarantee it is correctly hooked into the "package require"
# mechanism of the system Tcl/Tk we want to use.  (It is possible to have more
# than one Tcl/Tk on a system - this situation is known to have occurred on the
# Mac when 3rd party package managers are used, for example.)

# Hopefully situations where a user has a complex Itcl/Itk setup are rare
# enough that it won't be a significant issue, since there appears to be
# only so much we can do to sort it out...

if (USE_BRLCAD)

  # Decide if we're using Itk
  cad_enable(ITK "archer;mged;bwish;rtwizard;brlman")

else (USE_BRLCAD)

  if (ENABLE_ITCL AND NOT DEFINED ENABLE_ITK AND NOT DISABLE_TCL)
    set(ENABLE_ITK ON)
  endif (ENABLE_ITCL AND NOT DEFINED ENABLE_ITK AND NOT DISABLE_TCL)

endif (USE_BRLCAD)

if (NOT ENABLE_ITK AND NOT DISABLE_ITCL AND NOT DISABLE_TCL)
  find_library(ITK_SYS_LIBRARY NAMES itk3)

  if (NOT ITK_SYS_LIBRARY AND NOT DEFINED ENABLE_ITK)
    set(ENABLE_ITK "ON" CACHE BOOL "Enable itk build")
  endif (NOT ITK_SYS_LIBRARY AND NOT DEFINED ENABLE_ITK)

endif (NOT ENABLE_ITK AND NOT DISABLE_ITCL AND NOT DISABLE_TCL)
set(ENABLE_ITK "${ENABLE_ITK}" CACHE BOOL "Enable itk build")

if (ENABLE_ITK)

  git_submodule_init(itk configure.in)

  RegisterDeps(ITK)

  # If we're building ITK, it's path setup must take into account the
  # subdirectory in which we are storing the library.
  set(RPATH_SUFFIX itk3.4)

  set(ITK_SRC_CPY_TGT "${CMAKE_CURRENT_BINARY_DIR}/ITK_BLD-prefix/src/ITK_BLD")

  ExternalProject_Add(ITK_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/itk"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    PATCH_COMMAND ${PATCH_EXECUTABLE};-E;-p1;${PATCH_OPTIONS};-i;${CMAKE_CURRENT_SOURCE_DIR}/itk.patch
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ITK_SRC_CPY_TGT}/CMake
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/CMakeLists.txt ${ITK_SRC_CPY_TGT}
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/FindTCL.cmake ${ITK_SRC_CPY_TGT}/CMake
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/FindITCL.cmake ${ITK_SRC_CPY_TGT}/CMake
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ITK_SRC_CPY_TGT}/CMake/generic/itcl3
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/itclDecls.h ${ITK_SRC_CPY_TGT}/generic/itcl3
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/itcl.h ${ITK_SRC_CPY_TGT}/generic/itcl3
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/itclIntDecls.h ${ITK_SRC_CPY_TGT}/generic/itcl3
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/addfiles/itclInt.h ${ITK_SRC_CPY_TGT}/generic/itcl3
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    -DBIN_DIR=$<IF:$<BOOL:${WIN32}>,${LIB_DIR},${BIN_DIR}>
    -DLIB_DIR=${LIB_DIR}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BUNDLE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_RPATH=${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}/${RPATH_SUFFIX}
    -DINCLUDE_DIR=${INCLUDE_DIR}
    -DITCL_ROOT=$<$<BOOL:${ITCL_TARGET}>:${CMAKE_BUNDLE_INSTALL_PREFIX}>
    -DSHARED_DIR=${LIB_DIR}
    -DTCL_ENABLE_TK=ON
    -DTCL_ROOT=$<$<BOOL:${TCL_TARGET}>:${CMAKE_BUNDLE_INSTALL_PREFIX}>
    -DTCL_SOURCE_DIR=${CMAKE_SOURCE_DIR}/tcl/tcl
    -DTK_SOURCE_DIR=${CMAKE_SOURCE_DIR}/tk/tk
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(ITK ITK_DEPENDS)

  # Copy the license into position in CMAKE_BUNDLE_INSTALL_PREFIX
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/itk/license.terms
    ${DOC_LICENSE_DIR}/itk3.txt
    COPYONLY
    )

endif (ENABLE_ITK)

mark_as_advanced(ITK_LIBRARY)
mark_as_advanced(ITK_LIBRARIES)
mark_as_advanced(ITK_VERSION)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8

