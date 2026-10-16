cmake_minimum_required(VERSION 3.26)
project(BextBuildContextTest LANGUAGES C CXX)
get_filename_component(bext_cmake "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(CMAKE_NOBUNDLE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/noinstall")
set(CMAKE_BUNDLE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install")
include("${bext_cmake}/BextBuildContexts.cmake")
include("${bext_cmake}/BextExternalProject.cmake")

# Include spaces and semicolons to check serialization across nested CMake
# invocations.  The child verifies the complete list, including the empty item.
list(APPEND BEXT_TOOLCHAIN_VARIABLES CONTEXT_TEST_LIST)
set(CONTEXT_TEST_LIST "first path;second path;;last")
bext_initialize_build_contexts()

ExternalProject_Add(native_generator
  BEXT_BUILD_ROLE HOST
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generator"
  CMAKE_ARGS
    "-DCMAKE_C_COMPILER=${BEXT_HOST_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${BEXT_HOST_CXX_COMPILER}"
    "-DCMAKE_INSTALL_PREFIX=${BEXT_HOST_INSTALL_PREFIX}"
  STEP_TARGETS install)
ExternalProject_Add(target_library
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/library"
  CMAKE_ARGS
    "-DGENERATOR_EXECUTABLE=${BEXT_HOST_INSTALL_PREFIX}/bin/context_generator${BEXT_HOST_EXECUTABLE_SUFFIX}"
    "-DEXPECTED_SYSTEM=${CMAKE_SYSTEM_NAME}"
    "-DEXPECTED_CROSS=${CMAKE_CROSSCOMPILING}"
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install"
  STEP_TARGETS install)
ExternalProject_Add_StepDependencies(target_library configure native_generator-install)

# An explicitly empty custom configure command must remain empty.
ExternalProject_Add(no_configure
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/library"
  CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND "")

# No explicit CMAKE_ARGS: the wrapper still forwards the toolchain.
ExternalProject_Add(default_configure
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/identity"
  INSTALL_COMMAND "")
