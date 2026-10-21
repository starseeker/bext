#                     B E X T R E L E A S E B U I L D . C M A K E
# BRL-CAD
#
# Copyright (c) 2026 United States Government as represented by
# the U.S. Army Research Laboratory.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided
# with the distribution.
#
# 3. The name of the author may not be used to endorse or promote
# products derived from this software without specific prior written
# permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
###

include_guard(GLOBAL)

set(BEXT_BUILD_JOBS "" CACHE STRING "Jobs per dependency build; empty preserves wrapper defaults")
set(BEXT_LINK_JOBS 1 CACHE STRING "Concurrent LLVM link jobs (Ninja generator)")
foreach(jobs_var BEXT_BUILD_JOBS BEXT_LINK_JOBS)
  if (NOT "${${jobs_var}}" STREQUAL "" AND NOT "${${jobs_var}}" MATCHES "^[1-9][0-9]*$")
    message(FATAL_ERROR "${jobs_var} must be a positive integer")
  endif ()
endforeach()
if (NOT BEXT_LINK_JOBS)
  message(FATAL_ERROR "BEXT_LINK_JOBS must be a positive integer")
endif ()

option(BEXT_DISCARD_WORK "Discard installed dependencies' generated work directories" OFF)
# Tcl/Tk/Itk consumers share staged source headers until all installs finish.
set(BEXT_DEFER_DISCARD "TCL_BLD;TK_BLD;ITK_BLD" CACHE STRING
  "Targets whose working trees are retained until all dependencies are installed")
if (BEXT_DISCARD_WORK)
  cmake_path(IS_PREFIX CMAKE_BINARY_DIR "${CMAKE_SOURCE_DIR}" NORMALIZE source_in_build)
  if (source_in_build)
    message(FATAL_ERROR "BEXT_DISCARD_WORK requires a build directory that does not contain the source checkout")
  endif ()
  if (NOT DEFINED EXT_BUILD_ALWAYS OR EXT_BUILD_ALWAYS)
    message(FATAL_ERROR "BEXT_DISCARD_WORK requires EXT_BUILD_ALWAYS=OFF and immutable build inputs")
  endif ()
  if (NOT CMAKE_GENERATOR MATCHES "Ninja|Makefiles")
    message(FATAL_ERROR "BEXT_DISCARD_WORK supports Ninja and Makefile generators")
  endif ()
endif ()

function(bext_register_work_cleanup)
  if (NOT BEXT_DISCARD_WORK)
    return()
  endif ()
  get_property(install_targets GLOBAL PROPERTY BEXT_INSTALL_TARGETS)
  set(deferred_paths)
  foreach(install_target IN LISTS install_targets)
    string(REGEX REPLACE "-install$" "" ep_target "${install_target}")
    set(work_paths)
    ExternalProject_Get_Property(${ep_target} SOURCE_DIR BINARY_DIR)
    foreach(path IN ITEMS "${BINARY_DIR}" "${SOURCE_DIR}")
      _bext_path_is_in_build_tree(in_build "${path}")
      if (NOT in_build OR "${path}" STREQUAL "${CMAKE_BINARY_DIR}")
        continue()
      endif ()
      # The install prefix may be the build root.  Protect the two output
      # trees specifically, while permitting siblings beneath that root.
      foreach(output_root IN ITEMS "${CMAKE_BUNDLE_INSTALL_PREFIX}" "${CMAKE_NOBUNDLE_INSTALL_PREFIX}")
        cmake_path(IS_PREFIX path "${output_root}" NORMALIZE contains_output)
        cmake_path(IS_PREFIX output_root "${path}" NORMALIZE in_output)
        if (contains_output OR in_output)
          message(FATAL_ERROR "Refusing to discard ${ep_target} work directory containing installed outputs: ${path}")
        endif ()
      endforeach()
      list(APPEND work_paths "${path}")
    endforeach()
    list(REMOVE_DUPLICATES work_paths)
    if (NOT work_paths)
      continue()
    endif ()
    if (ep_target IN_LIST BEXT_DEFER_DISCARD)
      list(APPEND deferred_paths ${work_paths})
      continue()
    endif ()
    ExternalProject_Add_Step(${ep_target} discard_work
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${work_paths}
      DEPENDEES install
      COMMENT "Discarding installed ${ep_target} working directories"
      )
    ExternalProject_Add_StepTargets(${ep_target} discard_work)
    add_dependencies(${ep_target} ${ep_target}-discard_work)
    add_dependencies(bext_finalize ${ep_target}-discard_work)
  endforeach()
  if (deferred_paths)
    list(REMOVE_DUPLICATES deferred_paths)
    add_custom_target(bext_discard_deferred ALL
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${deferred_paths}
      DEPENDS bext_finalize
      COMMENT "Discarding deferred dependency working directories"
      VERBATIM
      )
  endif ()
endfunction()
