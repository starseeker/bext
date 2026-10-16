# Decide if we're using stepcode
cad_enable(STEPCODE "conv")

bext_enable(STEPCODE)

# Decision made

if (ENABLE_STEPCODE)

  git_submodule_init(stepcode CMakeLists.txt)

  RegisterDeps(STEPCODE)

  # For OSX, we need CMAKE_INSTALL_NAME_DIR
  set(CMAKE_INSTALL_NAME_DIR "@rpath")

  set(STEPCODE_PATCH_COMMAND
    PATCH_COMMAND ${CMAKE_COMMAND};-DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/stepcode;-DDEST_DIR=<SOURCE_DIR>;-P;${CMAKE_CURRENT_SOURCE_DIR}/RefreshSource.cmake
    COMMAND ${PATCH_EXECUTABLE};-E;-p1;${PATCH_OPTIONS};-i;${CMAKE_CURRENT_SOURCE_DIR}/stepcode_complex_string_pool.patch
    COMMAND ${PATCH_EXECUTABLE} -E -p1 ${PATCH_OPTIONS} -i ${CMAKE_CURRENT_SOURCE_DIR}/stepcode_mingw_exports.patch
    )

  if (CMAKE_CROSSCOMPILING)
    if (isMultiConfig)
      set(stepcode_host_bin "<BINARY_DIR>/$<CONFIG>/${BIN_DIR}")
    else ()
      set(stepcode_host_bin "<BINARY_DIR>/${BIN_DIR}")
    endif ()
    ExternalProject_Add(STEPCODE_HOST_BLD
      BEXT_BUILD_ROLE HOST
      URL "${CMAKE_CURRENT_SOURCE_DIR}/stepcode"
      BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
      ${STEPCODE_PATCH_COMMAND}
      CMAKE_ARGS
      ${BUILD_TYPE_SPECIFIER}
      -DBIN_DIR=${BIN_DIR}
      -DLIB_DIR=${LIB_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_STATIC_LIBS=ON
      -DCMAKE_INSTALL_PREFIX=${BEXT_HOST_INSTALL_PREFIX}
      -DLEMON_ROOT=${BEXT_HOST_INSTALL_PREFIX}
      -DPERPLEX_ROOT=${BEXT_HOST_INSTALL_PREFIX}
      -DPERPLEX_TEMPLATE=${BEXT_HOST_INSTALL_PREFIX}/${DATA_DIR}/perplex/perplex_template.c
      -DRE2C_ROOT=${BEXT_HOST_INSTALL_PREFIX}
      -DSC_BUILD_SCHEMAS=
      -DSC_ENABLE_COVERAGE=OFF
      -DSC_ENABLE_TESTING=OFF
      -DSC_IS_SUBBUILD=ON
      -DSC_PYTHON_GENERATOR=OFF
      BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config $<CONFIG> --target exp2cxx exppp
      INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${BEXT_HOST_INSTALL_PREFIX}/${BIN_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${stepcode_host_bin}/exp2cxx${BEXT_HOST_EXECUTABLE_SUFFIX}
        ${stepcode_host_bin}/exppp${BEXT_HOST_EXECUTABLE_SUFFIX}
        ${BEXT_HOST_INSTALL_PREFIX}/${BIN_DIR}/
      LOG_CONFIGURE ${EXT_BUILD_QUIET}
      LOG_BUILD ${EXT_BUILD_QUIET}
      LOG_INSTALL ${EXT_BUILD_QUIET}
      LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
      STEP_TARGETS install
      )
    TargetInstallDeps(STEPCODE_HOST STEPCODE_DEPENDS)
    ExternalProject_Add_StepDependencies(STEPCODE_HOST_BLD patch
      "${CMAKE_CURRENT_SOURCE_DIR}/RefreshSource.cmake"
      "${CMAKE_CURRENT_SOURCE_DIR}/stepcode_complex_string_pool.patch"
      "${CMAKE_CURRENT_SOURCE_DIR}/stepcode_mingw_exports.patch")
  endif ()

  ExternalProject_Add(STEPCODE_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/stepcode"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    ${STEPCODE_PATCH_COMMAND}
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    -DBIN_DIR=${BIN_DIR}
    -DLIB_DIR=${LIB_DIR}
    -DBUILD_STATIC_LIBS=OFF
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BUNDLE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR:PATH=${LIB_DIR}
    -DCMAKE_INSTALL_RPATH=${CMAKE_BUNDLE_INSTALL_PREFIX}/${LIB_DIR}
    -DCMAKE_INSTALL_NAME_DIR=${CMAKE_INSTALL_NAME_DIR}
    $<$<BOOL:${PERPLEX_TARGET}>:-DLEMON_ROOT=${BEXT_HOST_INSTALL_PREFIX}>
    $<$<BOOL:${PERPLEX_TARGET}>:-DPERPLEX_ROOT=${BEXT_HOST_INSTALL_PREFIX}>
    $<$<BOOL:${PERPLEX_TARGET}>:-DPERPLEX_TEMPLATE=${BEXT_HOST_INSTALL_PREFIX}/${DATA_DIR}/perplex/perplex_template.c>
    $<$<BOOL:${PERPLEX_TARGET}>:-DRE2C_ROOT=${BEXT_HOST_INSTALL_PREFIX}>
    -DSC_BUILD_SCHEMAS=
    -DSC_EXP2CXX_CHUNK_SIZE=64:8
    -DSC_ENABLE_COVERAGE=OFF
    -DSC_ENABLE_TESTING=OFF
    -DSC_IS_SUBBUILD=ON
    -DSC_PYTHON_GENERATOR=OFF
    LOG_CONFIGURE ${EXT_BUILD_QUIET}
    LOG_BUILD ${EXT_BUILD_QUIET}
    LOG_INSTALL ${EXT_BUILD_QUIET}
    LOG_OUTPUT_ON_FAILURE ${EXT_BUILD_QUIET}
    STEP_TARGETS install
    )

  TargetInstallDeps(STEPCODE STEPCODE_DEPENDS)
  ExternalProject_Add_StepDependencies(STEPCODE_BLD patch
    "${CMAKE_CURRENT_SOURCE_DIR}/RefreshSource.cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/stepcode_complex_string_pool.patch"
    "${CMAKE_CURRENT_SOURCE_DIR}/stepcode_mingw_exports.patch")

  # Copy the license into position in CMAKE_BUNDLE_INSTALL_PREFIX
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/stepcode/COPYING
    ${DOC_LICENSE_DIR}/stepcode.txt
    COPYONLY
    )

endif(ENABLE_STEPCODE)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8
