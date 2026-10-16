cmake_minimum_required(VERSION 3.26)
project(BextStepcodeConsumer LANGUAGES C CXX)

set(BEXT_STEPCODE_PREFIX "" CACHE PATH "Installed target STEPcode prefix")
set(STEPCODE_HOST_ROOT "" CACHE PATH "Installed native STEPcode tools prefix")
get_filename_component(bext_cmake "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
list(APPEND CMAKE_MODULE_PATH "${bext_cmake}")
list(APPEND CMAKE_FIND_ROOT_PATH "${BEXT_STEPCODE_PREFIX}")
set(STEPCODE_ROOT "${BEXT_STEPCODE_PREFIX}")
find_package(STEPCODE REQUIRED)

set(schema "${CMAKE_CURRENT_SOURCE_DIR}/sample.exp")
set(generated "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${generated}")
# The generator's manifest determines which translation units to compile.
execute_process(COMMAND "${EXP2CXX_EXECUTABLE}" -k 64:8 "${schema}"
  WORKING_DIRECTORY "${generated}" RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "The installed native exp2cxx failed: ${result}")
endif()
include("${generated}/SdaiBEXT_CROSS.sources.cmake")
list(TRANSFORM STEPCODE_GENERATED_SCHEMA_SOURCES PREPEND "${generated}/")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${schema}")
add_custom_command(OUTPUT ${STEPCODE_GENERATED_SCHEMA_SOURCES}
  COMMAND "${EXP2CXX_EXECUTABLE}" -k 64:8 "${schema}"
  WORKING_DIRECTORY "${generated}"
  DEPENDS "${schema}" "${EXP2CXX_EXECUTABLE}" VERBATIM)

add_executable(stepcode_consumer consumer.cc ${STEPCODE_GENERATED_SCHEMA_SOURCES})
target_compile_features(stepcode_consumer PRIVATE cxx_std_11)
target_compile_definitions(stepcode_consumer PRIVATE SC_SCHEMA_DLL_EXPORTS)
target_include_directories(stepcode_consumer PRIVATE
  "${generated}" ${STEPCODE_INCLUDE_DIRS})
target_link_libraries(stepcode_consumer PRIVATE ${STEPCODE_LIBRARIES})
enable_testing()
if(NOT CMAKE_CROSSCOMPILING OR CMAKE_CROSSCOMPILING_EMULATOR)
  add_test(NAME generated_schema COMMAND stepcode_consumer)
endif()
