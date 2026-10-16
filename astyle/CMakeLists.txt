# Astyle is not bundled with BRL-CAD - it is a source code formatting tool,
# optionally used during compilation to validate our style guidelines.
bext_enable_all_default(ASTYLE astyle)

if (NOT ENABLE_ASTYLE)

  bext_find_host_program(ASTYLE_EXECUTABLE astyle HINTS "${BEXT_HOST_INSTALL_PREFIX}/${BIN_DIR}")
  mark_as_advanced(ASTYLE_EXECUTABLE)

  if (NOT ASTYLE_EXECUTABLE AND NOT DEFINED ENABLE_ASTYLE)
    set(ENABLE_ASTYLE "ON" CACHE BOOL "Enable astyle build")
  endif (NOT ASTYLE_EXECUTABLE AND NOT DEFINED ENABLE_ASTYLE)

endif (NOT ENABLE_ASTYLE)
set(ENABLE_ASTYLE "${ENABLE_ASTYLE}" CACHE BOOL "Enable astyle build")

if (ENABLE_ASTYLE)

  git_submodule_init(astyle AStyle/CMakeLists.txt)

  RegisterDeps(ASTYLE)

  ExternalProject_Add(ASTYLE_BLD
    BEXT_BUILD_ROLE HOST
    URL "${CMAKE_CURRENT_SOURCE_DIR}/astyle"
    SOURCE_SUBDIR AStyle
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    PATCH_COMMAND ${PATCH_EXECUTABLE};-E;-p1;${PATCH_OPTIONS};-i;${CMAKE_CURRENT_SOURCE_DIR}/astyle.patch
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    -DBIN_DIR=${BIN_DIR}
    -DLIB_DIR=${LIB_DIR}
    -DCMAKE_CXX_COMPILER=${BEXT_HOST_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${BEXT_HOST_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${BEXT_HOST_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR:PATH=${LIB_DIR}
    -DCMAKE_INSTALL_RPATH=${BEXT_HOST_INSTALL_PREFIX}/${LIB_DIR}
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=OFF
    -DBUILD_JAVA_LIBS=OFF
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(ASTYLE ASTYLE_DEPENDS)

endif (ENABLE_ASTYLE)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8
