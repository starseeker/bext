# Shared repository selection for configure-time and bootstrap submodule updates.
# Keep .gitmodules canonical and scope all overrides to the Git process tree.
include_guard(GLOBAL)

set(_BEXT_GIT_CANONICAL_ROOT "https://github.com/BRL-CAD")
set(BEXT_REPOSITORY_ROOT "${_BEXT_GIT_CANONICAL_ROOT}" CACHE STRING
  "Repository URL or local mirror directory containing bext's dependency repositories")

function(bext_git_repository_root out_root out_local)
  set(root "${BEXT_REPOSITORY_ROOT}")
  set(local FALSE)
  if (root STREQUAL "")
    message(FATAL_ERROR "BEXT_REPOSITORY_ROOT must be a repository URL or local mirror directory")
  endif ()

  # Check drive paths before URL schemes or scp-style SSH locations.
  if (root MATCHES "^file://")
    set(local TRUE)
    string(REPLACE "=" "%3D" root "${root}")
  elseif (root MATCHES "^[A-Za-z]:[/\\\\]" OR
      NOT (root MATCHES "^[A-Za-z][A-Za-z0-9+.-]*://" OR root MATCHES "^[^/]+:.+"))
    set(local TRUE)
    string(REPLACE "\\" "/" root "${root}")
    if (WIN32 OR NOT root MATCHES "^[A-Za-z]:/")
      get_filename_component(root "${root}" ABSOLUTE
        BASE_DIR "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/..")
    endif ()
    # Encode path characters with special meaning in a file URL.  In
    # particular, a literal % in a native path must not become a URL escape.
    string(REPLACE "%" "%25" root "${root}")
    string(REPLACE " " "%20" root "${root}")
    string(REPLACE "#" "%23" root "${root}")
    string(REPLACE "?" "%3F" root "${root}")
    string(REPLACE "=" "%3D" root "${root}")
    if (root MATCHES "^[A-Za-z]:/")
      set(root "file:///${root}")
    elseif (root MATCHES "^//")
      set(root "file:${root}")
    else ()
      set(root "file://${root}")
    endif ()
  endif ()

  if (NOT root MATCHES "^file:///*$")
    string(REGEX REPLACE "/+$" "" root "${root}")
    string(APPEND root "/")
  else ()
    set(root "file:///")
  endif ()
  set(${out_root} "${root}" PARENT_SCOPE)
  set(${out_local} "${local}" PARENT_SCOPE)
endfunction()

function(bext_git_submodule_update working_directory)
  find_program(GIT_EXECUTABLE git)
  if (NOT GIT_EXECUTABLE)
    message(FATAL_ERROR "Need to populate Git submodules, but unable to find git executable")
  endif ()

  bext_git_repository_root(root local)
  set(git_command "${GIT_EXECUTABLE}")
  if (WIN32)
    list(APPEND git_command -c core.longpaths=true)
  endif ()
  if (NOT root STREQUAL "${_BEXT_GIT_CANONICAL_ROOT}/")
    list(APPEND git_command -c "url.${root}.insteadOf=${_BEXT_GIT_CANONICAL_ROOT}/")
  endif ()

  set(shallow_args)
  if (local)
    list(APPEND git_command -c protocol.file.allow=always)
    # The environment restriction also reaches recursive Git processes and
    # overrides any protocol permissions in the user's Git configuration.
    list(PREPEND git_command "${CMAKE_COMMAND}" -E env GIT_ALLOW_PROTOCOL=file --)
    list(APPEND shallow_args --no-recommend-shallow)
  elseif (GIT_SHALLOW_CLONE)
    list(APPEND shallow_args --recommend-shallow)
  endif ()

  execute_process(
    COMMAND ${git_command} submodule update --init --recursive ${shallow_args} ${ARGN}
    WORKING_DIRECTORY "${working_directory}"
    RESULT_VARIABLE git_result
  )
  if (NOT git_result STREQUAL "0")
    set(local_note "")
    if (local)
      set(local_note " Only file transport is permitted; all required repositories and pinned commits must be available locally, including recursive submodules.")
    endif ()
    message(FATAL_ERROR
      "Git submodule update failed in ${working_directory} using BEXT_REPOSITORY_ROOT=${BEXT_REPOSITORY_ROOT} (${git_result}).${local_note}")
  endif ()
endfunction()

bext_git_repository_root(_bext_git_root _bext_git_local)
message(STATUS "bext repository root: ${_bext_git_root}")
if (_bext_git_local)
  message(STATUS "bext Git updates: file transport only, shallow recommendations disabled")
  if (GIT_SHALLOW_CLONE)
    message(STATUS "Ignoring GIT_SHALLOW_CLONE for the local repository mirror")
  endif ()
endif ()
unset(_bext_git_root)
unset(_bext_git_local)
