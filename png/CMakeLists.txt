# Decide if we're using png
cad_enable(PNG "libicv;libdm;libged;libgcv")

if (NOT ENABLE_PNG AND NOT DISABLE_PNG)

  # We generally don't want the Mac framework libpng...
  set(CMAKE_FIND_FRAMEWORK LAST)

  find_package(PNG)

  if (NOT PNG_FOUND AND NOT DEFINED ENABLE_PNG)
    set(ENABLE_PNG "ON" CACHE BOOL "Enable png build")
  endif (NOT PNG_FOUND AND NOT DEFINED ENABLE_PNG)

endif (NOT ENABLE_PNG AND NOT DISABLE_PNG)

set(ENABLE_PNG "${ENABLE_PNG}" CACHE BOOL "Enable png build")

# Decision made

if (ENABLE_PNG)

  git_submodule_init(libpng CMakeLists.txt)

  RegisterDeps(PNG)
  if (TARGET ZLIB_BLD)
    set(Z_PREFIX_STR "brl_")
  endif (TARGET ZLIB_BLD)

  ExternalProject_Add(PNG_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/libpng"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    PATCH_COMMAND ${PATCH_EXECUTABLE};-E;-p1;${PATCH_OPTIONS};-i;${CMAKE_CURRENT_SOURCE_DIR}/png.patch
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    $<$<BOOL:${ZLIB_TARGET}>:-DZ_PREFIX=ON>
    $<$<BOOL:${ZLIB_TARGET}>:-DZ_PREFIX_STR=${Z_PREFIX_STR}>
    -DZLIB_ROOT=$<$<BOOL:${ZLIB_TARGET}>:${CMAKE_BUNDLE_INSTALL_PREFIX}>
    $<$<BOOL:${ZLIB_TARGET}>:-DPNG_BUILD_ZLIB=OFF>
    -DPNG_LIB_NAME=${PNG_LIB_NAME}
    -DPNG_NO_DEBUG_POSTFIX=ON
    -DPNG_PREFIX=brl_
    -DPNG_STATIC=${BUILD_STATIC_LIBS}
    -DPNG_TESTS=OFF
    -DSKIP_INSTALL_EXECUTABLES=ON -DSKIP_INSTALL_FILES=ON
    -DSKIP_INSTALL_EXPORT=ON
    -DSKIP_INSTALL_EXPORT=ON
    -Dld-version-script=OFF
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BUNDLE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR:PATH=${LIB_DIR}
    -DCMAKE_INSTALL_RPATH=${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(PNG PNG_DEPENDS)

  # Copy the license into position in CMAKE_BUNDLE_INSTALL_PREFIX
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/libpng/LICENSE
    ${DOC_LICENSE_DIR}/png.txt
    COPYONLY
    )

endif (ENABLE_PNG)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8

