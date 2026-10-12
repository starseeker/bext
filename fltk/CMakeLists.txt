cad_enable(FLTK "libfltkcad")
bext_local_source(FLTK fltk https://github.com/fltk/fltk 7721054c33258c8eb453234e3a2db47b62d6fd12)

if (ENABLE_FLTK)
  RegisterDeps(FLTK)

  set(fltk_patch_command)
  set(fltk_xmin_args)
  if (BEXT_XMIN_ROOT)
    set(fltk_patch_command PATCH_COMMAND
      ${PATCH_EXECUTABLE} -E -p1 ${PATCH_OPTIONS} -i ${CMAKE_CURRENT_SOURCE_DIR}/fltk_xmin.patch)
    set(fltk_xmin_args
      -DFLTK_USE_XMIN=ON
      -DFLTK_BACKEND_X11=ON
      -DXmin_ROOT:PATH=${BEXT_XMIN_ROOT})
  endif ()

  ExternalProject_Add(FLTK_BLD
    URL "${CMAKE_CURRENT_SOURCE_DIR}/fltk"
    BUILD_ALWAYS ${EXT_BUILD_ALWAYS} ${LOG_OPTS}
    ${fltk_patch_command}
    CMAKE_ARGS
    ${BUILD_TYPE_SPECIFIER}
    ${fltk_xmin_args}
    # These archives are linked into shared CAD libraries.
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DFLTK_BUILD_SHARED_LIBS=OFF
    -DFLTK_BUILD_GL=ON
    -DFLTK_OPTION_SVG=ON
    -DFLTK_BACKEND_WAYLAND=OFF
    -DFLTK_BUILD_FLUID=OFF
    -DFLTK_BUILD_FLTK_OPTIONS=OFF
    -DFLTK_BUILD_TEST=OFF
    -DFLTK_BUILD_EXAMPLES=OFF
    -DFLTK_BUILD_HTML_DOCS=OFF
    -DFLTK_BUILD_PDF_DOCS=OFF
    -DFLTK_USE_SYSTEM_LIBJPEG=OFF
    -DFLTK_USE_SYSTEM_LIBPNG=OFF
    -DFLTK_USE_SYSTEM_ZLIB=OFF
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
  TargetInstallDeps(FLTK FLTK_DEPENDS)

  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fltk/COPYING
    ${DOC_LICENSE_DIR}/fltk.txt COPYONLY)
endif ()

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8
