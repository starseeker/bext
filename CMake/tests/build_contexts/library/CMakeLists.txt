cmake_minimum_required(VERSION 3.26)
project(TargetLibrary LANGUAGES C CXX)
if (NOT CMAKE_SYSTEM_NAME STREQUAL EXPECTED_SYSTEM OR
    NOT "${CMAKE_CROSSCOMPILING}" STREQUAL "${EXPECTED_CROSS}")
  message(FATAL_ERROR "ExternalProject lost the target platform")
endif ()
if (NOT CONTEXT_TEST_LIST STREQUAL "first path;second path;;last")
  message(FATAL_ERROR "Toolchain cache list was corrupted: '${CONTEXT_TEST_LIST}'")
endif ()
set(generated "${CMAKE_CURRENT_BINARY_DIR}/generated.c")
add_custom_command(OUTPUT "${generated}"
  COMMAND "${GENERATOR_EXECUTABLE}" "${generated}"
  DEPENDS "${GENERATOR_EXECUTABLE}" VERBATIM)
add_library(context_library STATIC "${generated}" platform.c platform.cpp)
if (TCL_GENERATOR_EXECUTABLE)
  set(tcl_generated "${CMAKE_CURRENT_BINARY_DIR}/tcl_generated.c")
  add_custom_command(OUTPUT "${tcl_generated}"
    COMMAND "${CMAKE_COMMAND}" -E env
      --unset=TCL_LIBRARY --unset=TCLLIBPATH --unset=TK_LIBRARY
      "${TCL_GENERATOR_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/generate.tcl" "${tcl_generated}"
    DEPENDS "${TCL_GENERATOR_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/generate.tcl" VERBATIM)
  target_sources(context_library PRIVATE "${tcl_generated}")
endif ()
if (WIN32)
  target_compile_definitions(context_library PRIVATE EXPECT_WINDOWS)
endif ()
install(TARGETS context_library ARCHIVE DESTINATION lib)
