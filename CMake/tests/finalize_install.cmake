cmake_minimum_required(VERSION 3.26)
if(NOT BEXT_TEST_ROOT OR NOT EXISTS "${BEXT_STRCLEAR}")
  message(FATAL_ERROR "Set BEXT_TEST_ROOT and BEXT_STRCLEAR")
endif()

# Typical in-source build layout: every output prefix is below the source.
set(source "${BEXT_TEST_ROOT}/source")
set(build "${source}/build")
set(native "${build}/noinstall")
set(install "${build}/install")
file(MAKE_DIRECTORY "${install}/lib/cmake/Fixture" "${native}")
file(REAL_PATH "${install}" canonical_install)
file(REAL_PATH "${source}" canonical_source)
set(package "${install}/lib/cmake/Fixture/FixtureConfig.cmake")
file(WRITE "${package}"
  "set(paths \"${install}/lib/a;${native}/lib/b;${build}/lib/c;${source}/lib/d;${canonical_install}/lib/e;${canonical_source}/lib/f\")\n"
  "# Preserve unrelated tokens: @BEXT_CANONICAL_INSTALL_PREFIX@\n")
set(expected
  "set(paths \"${install}/lib/a;${install}/lib/b;${install}/lib/c;${install}/lib/d;${install}/lib/e;${install}/lib/f\")\n# Preserve unrelated tokens: @BEXT_CANONICAL_INSTALL_PREFIX@\n")

foreach(pass RANGE 1 2)
  execute_process(COMMAND "${CMAKE_COMMAND}"
    "-DBEXT_INSTALL_ROOT=${install}"
    "-DBEXT_MANIFEST=${build}/bext-install-manifest.json"
    "-DBEXT_SOURCE_ROOT=${source}"
    "-DBEXT_BINARY_ROOT=${build}"
    "-DBEXT_NOINSTALL_ROOT=${native}"
    "-DBEXT_STRCLEAR=${BEXT_STRCLEAR}"
    -DBEXT_SYSTEM_NAME=Windows -DBIN_DIR=bin -DLIB_DIR=lib
    -P "${CMAKE_CURRENT_LIST_DIR}/../FinalizeInstall.cmake"
    RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Finalization pass ${pass} failed")
  endif()
  file(READ "${package}" actual)
  if(NOT actual STREQUAL expected)
    message(FATAL_ERROR "Finalization pass ${pass} changed canonical paths:\n${actual}")
  endif()
endforeach()
message(STATUS "Nested build prefixes and repeated finalization preserve canonical paths")
