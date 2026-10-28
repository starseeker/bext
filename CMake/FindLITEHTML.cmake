# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindLITEHTML
-----------

Find litehtml, preferring its upstream CMake package configuration.

Defines ``LITEHTML_FOUND``, ``LITEHTML_INCLUDE_DIRS``, ``LITEHTML_LIBRARIES``,
and the imported target ``LITEHTML::LITEHTML``.  ``LITEHTML_ROOT`` may be set
to an installation prefix.  Installations without a package configuration
must also provide Gumbo, which is needed when linking static litehtml.
#]=======================================================================]

if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()

find_package(litehtml CONFIG QUIET HINTS ${LITEHTML_ROOT})

if(litehtml_FOUND AND TARGET litehtml)
  set(LITEHTML_LIBRARIES litehtml)
  get_target_property(LITEHTML_INCLUDE_DIRS litehtml INTERFACE_INCLUDE_DIRECTORIES)
  set(_LITEHTML_REQUIRED_VARS LITEHTML_LIBRARIES LITEHTML_INCLUDE_DIRS)
else()
  find_path(LITEHTML_INCLUDE_DIR NAMES litehtml.h
    HINTS ${LITEHTML_ROOT} PATH_SUFFIXES include include/litehtml)
  find_library(LITEHTML_LIBRARY NAMES litehtml
    HINTS ${LITEHTML_ROOT} PATH_SUFFIXES lib lib64)
  find_library(LITEHTML_GUMBO_LIBRARY NAMES gumbo
    HINTS ${LITEHTML_ROOT} PATH_SUFFIXES lib lib64)
  mark_as_advanced(LITEHTML_INCLUDE_DIR LITEHTML_LIBRARY LITEHTML_GUMBO_LIBRARY)

  set(LITEHTML_INCLUDE_DIRS "${LITEHTML_INCLUDE_DIR}")
  set(LITEHTML_LIBRARIES "${LITEHTML_LIBRARY};${LITEHTML_GUMBO_LIBRARY}")
  set(_LITEHTML_REQUIRED_VARS LITEHTML_LIBRARY LITEHTML_INCLUDE_DIR LITEHTML_GUMBO_LIBRARY)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LITEHTML
  REQUIRED_VARS ${_LITEHTML_REQUIRED_VARS})
unset(_LITEHTML_REQUIRED_VARS)

if(LITEHTML_FOUND AND NOT TARGET LITEHTML::LITEHTML)
  if(litehtml_FOUND AND TARGET litehtml)
    add_library(LITEHTML::LITEHTML INTERFACE IMPORTED)
    set_target_properties(LITEHTML::LITEHTML PROPERTIES
      INTERFACE_LINK_LIBRARIES litehtml)
  else()
    add_library(LITEHTML::LITEHTML UNKNOWN IMPORTED)
    set_target_properties(LITEHTML::LITEHTML PROPERTIES
      IMPORTED_LOCATION "${LITEHTML_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${LITEHTML_INCLUDE_DIRS}"
      INTERFACE_LINK_LIBRARIES "${LITEHTML_GUMBO_LIBRARY}")
  endif()
endif()
