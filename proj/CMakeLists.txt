# Decide if we're using PROJ (needed by GDAL, which is used by gcv)
cad_enable(PROJ "libgcv")

bext_enable(PROJ)

# Decision made

if (ENABLE_PROJ)

  git_submodule_init(PROJ CMakeLists.txt)

  RegisterDeps(PROJ)

  set(PROJ_HOST_ARGS)
  if (CMAKE_CROSSCOMPILING)
    if (NOT TARGET SQLITE3_HOST_BLD)
      bext_find_host_program(BEXT_HOST_SQLITE3 NAMES sqlite3 REQUIRED)
      execute_process(COMMAND "${BEXT_HOST_SQLITE3}" :memory: "SELECT sqlite_version();"
        RESULT_VARIABLE sqlite_host_result OUTPUT_VARIABLE sqlite_host_version
        ERROR_VARIABLE sqlite_host_error OUTPUT_STRIP_TRAILING_WHITESPACE)
      if (NOT sqlite_host_result EQUAL 0 OR NOT sqlite_host_version MATCHES "^3[.][0-9]+[.][0-9]+$")
        message(FATAL_ERROR "BEXT_HOST_SQLITE3 must be a runnable native SQLite 3 shell: ${sqlite_host_error}")
      endif ()
    endif ()
    list(APPEND PROJ_HOST_ARGS "-DEXE_SQLITE3=${BEXT_HOST_SQLITE3}"
      "-DSQLite3_EXECNAME=${BEXT_HOST_SQLITE3}")
  endif ()

  ExternalProject_Add(PROJ_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/PROJ"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    PATCH_COMMAND ${PATCH_EXECUTABLE};-E;-p1;${PATCH_OPTIONS};-i;${CMAKE_CURRENT_SOURCE_DIR}/proj.patch
    COMMAND ${CMAKE_COMMAND};-E;copy;${CMAKE_CURRENT_SOURCE_DIR}/../CMake/FindSQLite3.cmake;<SOURCE_DIR>/cmake/FindSQLite3.cmake
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    -DBIN_DIR=${BIN_DIR}
    -DLIB_DIR=${LIB_DIR}
    -DBUILD_STATIC_LIBS=${BUILD_STATIC_LIBS}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BUNDLE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR:PATH=${LIB_DIR}
    -DCMAKE_INSTALL_RPATH=${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}
    -DPROJ_LIB_DIR=${CMAKE_BUNDLE_INSTALL_PREFIX}/${DATA_DIR}/proj
    -DSQLite3_ROOT=$<$<BOOL:${SQLITE3_TARGET}>:${CMAKE_BUNDLE_INSTALL_PREFIX}>
    ${PROJ_HOST_ARGS}
    -DBUILD_TESTING=OFF
    -DENABLE_TIFF=OFF
    -DENABLE_CURL=OFF
    -DBUILD_PROJSYNC=OFF
    DEPENDS ${PROJ_DEPS}
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(PROJ PROJ_DEPENDS)
  if (TARGET SQLITE3_HOST_BLD)
    ExternalProject_Add_StepDependencies(PROJ_BLD configure SQLITE3_HOST_BLD-install)
  endif ()

  # Copy the license into position in CMAKE_BUNDLE_INSTALL_PREFIX
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/PROJ/COPYING
    ${DOC_LICENSE_DIR}/proj.txt
    COPYONLY
    )

endif (ENABLE_PROJ)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8

