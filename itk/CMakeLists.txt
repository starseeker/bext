# Itk uses private Tcl and Itcl interfaces plus Tk stubs.  Build it only as
# part of bext's internally consistent Tcl/Tk stack; system Tcl/Tk must supply
# Itk.

if (USE_BRLCAD)

  cad_enable(ITK "${BEXT_TK_COMPONENTS}")

else (USE_BRLCAD)

  bext_enable_all_default(ITK itk)

endif (USE_BRLCAD)

if (TARGET TK_BLD AND NOT DEFINED ENABLE_ITK AND NOT DISABLE_ITK)
  set(ENABLE_ITK ON)
endif ()
set(ENABLE_ITK "${ENABLE_ITK}" CACHE BOOL "Enable itk build")

if (ENABLE_ITK)

  if (NOT TARGET TCL_BLD OR NOT TARGET TK_BLD)
    message(FATAL_ERROR
      "A local Itk build requires bext's bundled Tcl and Tk because Itk uses "
      "private Tcl and Itcl interfaces.  A system Tcl/Tk stack must provide "
      "Itk ${BEXT_ITK_MIN_VERSION} or newer; otherwise configure with "
      "-DENABLE_TCL=ON."
      )
  endif ()

  git_submodule_init(itk configure)

  RegisterDeps(ITK)

  set(BEXT_ITK_VERSION "${BEXT_ITK_BUNDLED_VERSION}" CACHE INTERNAL "Bundled Itk version" FORCE)
  set(RPATH_SUFFIX "itk${BEXT_ITK_BUNDLED_VERSION}")
  set(ITK_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/ITK_BLD-prefix/src/ITK_BLD")
  set(ITK_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/ITK_BLD-prefix/src/ITK_BLD-build")

  set(WITH_TCL_DIR "${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}")
  set(WITH_TCL_INCLUDE_DIR "${CMAKE_BUNDLE_INSTALL_PREFIX}/${INCLUDE_DIR}")
  set(TCL_SRC_DIR "${CMAKE_BINARY_DIR}/tcl/TCL_BLD-prefix/src/TCL_BLD")
  set(WITH_TK_DIR "${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}")
  set(WITH_TK_INCLUDE_DIR "${CMAKE_BUNDLE_INSTALL_PREFIX}/${INCLUDE_DIR}")
  set(TK_SRC_DIR "${CMAKE_BINARY_DIR}/tk/TK_BLD-prefix/src/TK_BLD")
  set(WITH_ITCL_DIR "${BEXT_ITCL_CONFIG_DIR}")
  set(ITCL_SRC_DIR "${BEXT_ITCL_SOURCE_DIR}")

  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itk_configure.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/itk_configure.cmake @ONLY)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itk_build.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/itk_build.cmake @ONLY)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itk_install.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/itk_install.cmake @ONLY)

  set(ITK_PATCH_COMMAND
    ${CMAKE_COMMAND}
    "-DITK_SOURCE_DIR=<SOURCE_DIR>"
    "-DITK_PATCH_EXECUTABLE=${PATCH_NATIVE_EXECUTABLE}"
    "-DITK_PATCH_CHECK_OPTION=${PATCH_CHECK_OPTION}"
    "-DITK_PATCH_REJECT_DIR=${PATCH_REJECT_DIR}"
    "-DITK_PATCH_FILE=${CMAKE_CURRENT_SOURCE_DIR}/itk.patch"
    "-DITK_INSTALL_PATCH_FILE=${CMAKE_CURRENT_SOURCE_DIR}/itk_install.patch"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/itk_apply_patch.cmake"
    COMMAND ${PATCH_EXECUTABLE} -E -p1 ${PATCH_OPTIONS}
      -i "${CMAKE_CURRENT_SOURCE_DIR}/itk_stubs.patch"
    )

  if (NOT MSVC)
    set(ITK_CONFIGURE_COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/itk_configure.cmake)
    set(ITK_BUILD_COMMAND ${BEXT_MAKE_COMMAND} -j${pcnt})
    set(ITK_INSTALL_COMMAND ${BEXT_MAKE_COMMAND} -j1 INSTALL_OPTIONS=-C install)
    if (CMAKE_CROSSCOMPILING AND WIN32 AND NOT CMAKE_HOST_WIN32)
      include("${CMAKE_SOURCE_DIR}/CMake/BextMingw.cmake")
      bext_mingw_context()
      list(APPEND ITK_PATCH_COMMAND COMMAND ${PATCH_EXECUTABLE} -E -p1 ${PATCH_OPTIONS}
        -i ${CMAKE_CURRENT_SOURCE_DIR}/itk_mingw.patch)
      configure_file(itk_mingw.cmake.in itk_mingw.cmake @ONLY)
      set(ITK_CONFIGURE_COMMAND ${CMAKE_COMMAND} -DBEXT_ACTION=configure -P ${CMAKE_CURRENT_BINARY_DIR}/itk_mingw.cmake)
      set(ITK_BUILD_COMMAND ${CMAKE_COMMAND} -DBEXT_ACTION=build -P ${CMAKE_CURRENT_BINARY_DIR}/itk_mingw.cmake)
      set(ITK_INSTALL_COMMAND ${CMAKE_COMMAND} -DBEXT_ACTION=install -P ${CMAKE_CURRENT_BINARY_DIR}/itk_mingw.cmake)
    endif ()
    ExternalProject_Add(ITK_BLD
      URL "${CMAKE_CURRENT_SOURCE_DIR}/itk"
      BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
      PATCH_COMMAND ${ITK_PATCH_COMMAND}
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/manifest.uuid <SOURCE_DIR>/manifest.uuid
      COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/tclconfig
      COMMAND ${CMAKE_COMMAND} -E copy ${BEXT_ITCL_BUNDLED_SOURCE_DIR}/tclconfig/install-sh <SOURCE_DIR>/tclconfig/install-sh
      CONFIGURE_COMMAND ${ITK_CONFIGURE_COMMAND}
      BUILD_COMMAND ${ITK_BUILD_COMMAND}
      INSTALL_COMMAND ${ITK_INSTALL_COMMAND}
      LOG_CONFIGURE ${EXT_BUILD_QUIET}
      LOG_BUILD ${EXT_BUILD_QUIET}
      LOG_INSTALL ${EXT_BUILD_QUIET}
      LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
      STEP_TARGETS install
      )
    if (CMAKE_CROSSCOMPILING AND WIN32 AND NOT CMAKE_HOST_WIN32)
      ExternalProject_Add_StepDependencies(ITK_BLD configure ${BEXT_MINGW_INPUTS}
        "${CMAKE_CURRENT_BINARY_DIR}/itk_mingw.cmake")
      if (BEXT_HOST_TCL_TARGET)
        ExternalProject_Add_StepDependencies(ITK_BLD configure ${BEXT_HOST_TCL_TARGET})
      endif ()
    endif ()
  else (NOT MSVC)
    # Itk's rules.vc is newer than Tcl 8.6's, so rules-ext.vc selects the
    # local nmake support files.  Upstream omits the matching targets.vc;
    # supply the complete file rather than patching one into existence.
    ExternalProject_Add(ITK_BLD
      URL "${CMAKE_CURRENT_SOURCE_DIR}/itk"
      BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
      PATCH_COMMAND ${ITK_PATCH_COMMAND}
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/manifest.uuid <SOURCE_DIR>/manifest.uuid
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/targets.vc <SOURCE_DIR>/win/targets.vc
      COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/tclconfig
      COMMAND ${CMAKE_COMMAND} -E copy ${BEXT_ITCL_BUNDLED_SOURCE_DIR}/tclconfig/install-sh <SOURCE_DIR>/tclconfig/install-sh
      CONFIGURE_COMMAND ""
      BINARY_DIR ${ITK_SRC_DIR}/win
      BUILD_COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/itk_build.cmake
      INSTALL_COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/itk_install.cmake
      LOG_BUILD ${EXT_BUILD_QUIET}
      LOG_INSTALL ${EXT_BUILD_QUIET}
      LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
      STEP_TARGETS install
      )
  endif (NOT MSVC)

  # itk.h includes this declarations header, but upstream's Unix and Windows
  # install lists omit it.  Complete the installed public interface before
  # releasing the install prerequisite to consumers.
  ExternalProject_Add_Step(ITK_BLD install-stub-header
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BUNDLE_INSTALL_PREFIX}/${INCLUDE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${ITK_SRC_DIR}/generic/itkDecls.h" "${CMAKE_BUNDLE_INSTALL_PREFIX}/${INCLUDE_DIR}/itkDecls.h"
    DEPENDEES build DEPENDERS install)

  TargetInstallDeps(ITK ITK_DEPENDS)

  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/itk/license.terms
    ${DOC_LICENSE_DIR}/itk.txt
    COPYONLY
    )

endif (ENABLE_ITK)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8
