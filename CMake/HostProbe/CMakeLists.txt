cmake_minimum_required(VERSION 3.26)
project(BextHostProbe LANGUAGES C CXX)

if (CMAKE_CROSSCOMPILING)
  message(FATAL_ERROR "The native build-tool compiler must run on ${CMAKE_HOST_SYSTEM_NAME}")
endif ()
foreach(lang C CXX)
  if (lang STREQUAL "C")
    set(ext c)
  else ()
    set(ext cpp)
  endif ()
  # Do not cache the execution result: compiler selection can change between
  # configure passes, and running the wrong architecture is a hard error.
  try_run(run_result compile_result
    SOURCE_FROM_CONTENT "host.${ext}" "int main(void) { return 0; }\n"
    NO_CACHE COMPILE_OUTPUT_VARIABLE compile_output RUN_OUTPUT_VARIABLE run_output)
  if (NOT compile_result OR NOT "${run_result}" STREQUAL "0")
    message(FATAL_ERROR "Native ${lang} compiler cannot build and run a program:\n${compile_output}\n${run_output}")
  endif ()
endforeach ()
file(WRITE "${CMAKE_BINARY_DIR}/host-info.cmake"
  "set(BEXT_HOST_C_COMPILER [==[${CMAKE_C_COMPILER}]==])\n"
  "set(BEXT_HOST_CXX_COMPILER [==[${CMAKE_CXX_COMPILER}]==])\n"
  "set(BEXT_HOST_EXECUTABLE_SUFFIX [==[${CMAKE_EXECUTABLE_SUFFIX}]==])\n"
  "set(BEXT_HOST_MSVC [==[${MSVC}]==])\n")
