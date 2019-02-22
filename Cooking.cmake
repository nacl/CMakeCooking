#
# Copyright 2018 Jesse Haber-Kucharsky
# Copyright 2019 Akamai Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

macro (project name)
  set (_cooking_dir ${CMAKE_CURRENT_BINARY_DIR}/_cooking)

  if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set (_cooking_root ON)
  else ()
    set (_cooking_root OFF)
  endif ()

  find_program (Cooking_STOW_EXECUTABLE
    stow
    "Executable path of GNU Stow.")

  if (NOT Cooking_STOW_EXECUTABLE)
    message (FATAL_ERROR "Cooking: GNU Stow is required!")
  endif ()

  set (Cooking_INGREDIENTS_DIR
    ${_cooking_dir}/installed
    CACHE
    PATH
    "Directory where ingredients will be installed.")

  set (Cooking_EXCLUDED_INGREDIENTS
   ""
   CACHE
   STRING
   "Semicolon-separated list of ingredients that are not provided by Cooking.")

  set (Cooking_INCLUDED_INGREDIENTS
   ""
   CACHE
   STRING
   "Semicolon-separated list of ingredients that are provided by Cooking.")

  option (Cooking_LIST_ONLY
    "Available ingredients will be listed and nothing will be installed."
    OFF)

  set (Cooking_RECIPE "" CACHE STRING "Configure ${name}'s dependencies according to the named recipe.")

  if ((NOT DEFINED Cooking_EXCLUDED_INGREDIENTS) OR (Cooking_EXCLUDED_INGREDIENTS STREQUAL ""))
    set (_cooking_is_excluding OFF)
  else ()
    set (_cooking_is_excluding ON)
  endif ()

  if ((NOT DEFINED Cooking_INCLUDED_INGREDIENTS) OR (Cooking_INCLUDED_INGREDIENTS STREQUAL ""))
    set (_cooking_is_including OFF)
  else ()
    set (_cooking_is_including ON)
  endif ()

  if (_cooking_is_excluding AND _cooking_is_including)
    message (
      FATAL_ERROR
      "Cooking: The EXCLUDED_INGREDIENTS and INCLUDED_INGREDIENTS lists are mutually exclusive options!")
  endif ()

  if (_cooking_root)
    _project (${name} ${ARGN})

    if (NOT ("${Cooking_RECIPE}" STREQUAL ""))
      add_custom_target (_cooking_ingredients)

      set (_cooking_ready_marker_file ${_cooking_dir}/ready.txt)

      add_custom_command (
        OUTPUT ${_cooking_ready_marker_file}
        DEPENDS _cooking_ingredients
        COMMAND ${CMAKE_COMMAND} -E touch ${_cooking_ready_marker_file})

      add_custom_target (_cooking_ingredients_ready
        DEPENDS ${_cooking_ready_marker_file})

      set (_cooking_local_synchronize_marker_file ${Cooking_INGREDIENTS_DIR}/.cooking_local_synchronize)

      add_custom_command (
        OUTPUT ${_cooking_local_synchronize_marker_file}
        COMMAND ${CMAKE_COMMAND} -E touch ${_cooking_local_synchronize_marker_file})

      add_custom_target (_cooking_marked_for_local_synchronization
        DEPENDS ${_cooking_local_synchronize_marker_file})

      list (APPEND CMAKE_PREFIX_PATH ${Cooking_INGREDIENTS_DIR})
      include (${Cooking_RECIPE})

      if (NOT EXISTS ${_cooking_ready_marker_file})
        return ()
      endif ()
    endif ()
  endif ()
endmacro ()

function (_cooking_set_union x y var)
  set (r ${${x}})

  foreach (e ${${y}})
    list (APPEND r ${e})
  endforeach ()

  list (REMOVE_DUPLICATES r)
  set (${var} ${r} PARENT_SCOPE)
endfunction ()

function (_cooking_set_difference x y var)
  set (r ${${x}})

  foreach (e ${${y}})
    if (${e} IN_LIST ${x})
       list (REMOVE_ITEM r ${e})
    endif ()
  endforeach ()

  set (${var} ${r} PARENT_SCOPE)
endfunction ()

function (_cooking_set_intersection x y var)
  set (r "")

  foreach (e ${${y}})
    if (${e} IN_LIST ${x})
      list (APPEND r ${e})
    endif ()
  endforeach ()

  list (REMOVE_DUPLICATES r)
  set (${var} ${r} PARENT_SCOPE)
endfunction ()

function (_cooking_query_by_key list key var)
  list (FIND ${list} ${key} index)

  if (${index} EQUAL "-1")
    set (value NOTFOUND)
  else ()
    math (EXPR value_index "${index} + 1")
    list (GET ${list} ${value_index} value)
  endif ()

  set (${var} ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_populate_ep_parameter)
  cmake_parse_arguments (
    pa
    ""
    "EXTERNAL_PROJECT_ARGS_LIST;PARAMETER;DEFAULT_VALUE"
    ""
    ${ARGN})

  string (TOLOWER ${pa_PARAMETER} parameter_lower)
  _cooking_query_by_key (${pa_EXTERNAL_PROJECT_ARGS_LIST} ${pa_PARAMETER} ${parameter_lower})
  set (value ${${parameter_lower}})
  set (var_name _cooking_${parameter_lower})
  set (ep_var_name _cooking_ep_${parameter_lower})

  if (NOT value)
    set (${var_name} ${pa_DEFAULT_VALUE} PARENT_SCOPE)
    set (${ep_var_name} ${pa_PARAMETER} ${pa_DEFAULT_VALUE} PARENT_SCOPE)
  else ()
    set (${var_name} ${value} PARENT_SCOPE)
    set (${ep_var_name} "" PARENT_SCOPE)
  endif ()
endfunction ()

function (_cooking_define_listing_targets)
  cmake_parse_arguments (
    pa
    ""
    "NAME;SOURCE_DIR;RECIPE"
    "REQUIRES"
    ${ARGN})

  set (stale_file ${Cooking_INGREDIENTS_DIR}/.cooking_stale_ingredient_${pa_NAME})

  add_custom_command (
    OUTPUT ${stale_file}
    COMMAND ${CMAKE_COMMAND} -E touch ${stale_file})

  add_custom_target (_cooking_ingredient_${pa_NAME}_stale
    DEPENDS ${stale_file})

  set (commands
    COMMAND
    ${CMAKE_COMMAND} -E touch ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${pa_NAME})

  if (pa_RECIPE)
    if (pa_RECIPE STREQUAL <DEFAULT>)
      set (recipe_args "")
    else ()
      set (recipe_args -r ${pa_RECIPE})
    endif ()

    list (INSERT commands 0
      COMMAND
      ${pa_SOURCE_DIR}/cooking.sh
      ${recipe_args}
      -p ${Cooking_INGREDIENTS_DIR}
      -g ${CMAKE_GENERATOR}
      -x
      -l)
  endif ()

  add_custom_command (
    OUTPUT ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${pa_NAME}
    DEPENDS
      _cooking_ingredient_${pa_NAME}_stale
      ${stale_file}
    ${commands})

  add_custom_target (_cooking_ingredient_${pa_NAME}_listed
    DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${pa_NAME})

  foreach (d ${pa_REQUIRES})
    add_dependencies (_cooking_ingredient_${pa_NAME}_listed _cooking_ingredient_${d}_listed)
  endforeach ()

  add_dependencies (_cooking_ingredients _cooking_ingredient_${pa_NAME}_listed)
endfunction ()

function (_cooking_adjust_requirements)
  cmake_parse_arguments (
    pa
    ""
    "IS_EXCLUDING;IS_INCLUDING;OUTPUT_LIST"
    "REQUIREMENTS"
    ${ARGN})

  if (pa_IS_EXCLUDING)
    # Strip out any dependencies that are excluded.
    _cooking_set_difference (
      pa_REQUIREMENTS
      Cooking_EXCLUDED_INGREDIENTS
      pa_REQUIREMENTS)
  elseif (_cooking_is_including)
    # Eliminate dependencies that have not been included.
    _cooking_set_intersection (
      pa_REQUIREMENTS
      Cooking_INCLUDED_INGREDIENTS
      pa_REQUIREMENTS)
  endif ()

  set (${pa_OUTPUT_LIST} ${pa_REQUIREMENTS} PARENT_SCOPE)
endfunction ()

function (_cooking_populate_ep_depends)
  cmake_parse_arguments (
    pa
    ""
    ""
    "REQUIREMENTS"
    ${ARGN})

  if (pa_REQUIREMENTS)
    set (value DEPENDS)

    foreach (d ${pa_REQUIREMENTS})
      list (APPEND value ingredient_${d})
    endforeach ()
  else ()
    set (value "")
  endif ()

  set (_cooking_ep_depends ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_prepare_restrictions_arguments)
  cmake_parse_arguments (
    pa
    ""
    "IS_EXCLUDING;IS_INCLUDING;OUTPUT_LIST"
    "REQUIREMENTS"
    ${ARGN})

  set (args "")

  if (pa_IS_INCLUDING)
    _cooking_set_difference (
      Cooking_INCLUDED_INGREDIENTS
      pa_REQUIREMENTS
      included)

    foreach (x ${included})
      list (APPEND args -i ${x})
    endforeach ()
  elseif (pa_IS_EXCLUDING)
    _cooking_set_union (
      Cooking_EXCLUDED_INGREDIENTS
      pa_REQUIREMENTS
      excluded)

    foreach (x ${excluded})
      list (APPEND args -e ${x})
    endforeach ()
  else ()
    foreach (x ${pa_REQUIREMENTS})
      list (APPEND args -e ${x})
    endforeach ()
  endif ()

  set (${pa_OUTPUT_LIST} ${args} PARENT_SCOPE)
endfunction ()

function (_cooking_determine_common_cmake_args output)
  string (REPLACE ";" ":::" prefix_path_with_colons "${CMAKE_PREFIX_PATH}")

  set (${output}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_PREFIX_PATH=${prefix_path_with_colons}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    PARENT_SCOPE)
endfunction ()

function (_cooking_populate_ep_configure_command)
  cmake_parse_arguments (
    pa
    ""
    "IS_EXCLUDING;IS_INCLUDING;RECIPE;EXTERNAL_PROJECT_ARGS_LIST"
    "REQUIREMENTS;CMAKE_ARGS;COOKING_CMAKE_ARGS"
    ${ARGN})

  if (pa_RECIPE)
    if (pa_RECIPE STREQUAL <DEFAULT>)
      set (recipe_args "")
    else ()
      set (recipe_args -r ${pa_RECIPE})
    endif ()

    _cooking_prepare_restrictions_arguments (
      IS_EXCLUDING ${pa_IS_EXCLUDING}
      IS_INCLUDING ${pa_IS_INCLUDING}
      REQUIREMENTS ${pa_REQUIREMENTS}
      OUTPUT_LIST restrictions_args)

    set (value
      CONFIGURE_COMMAND
      <SOURCE_DIR>/cooking.sh
      ${recipe_args}
      -d <BINARY_DIR>
      -p ${Cooking_INGREDIENTS_DIR}
      -g ${CMAKE_GENERATOR}
      -x
      ${restrictions_args}
      --
      ${pa_COOKING_CMAKE_ARGS})
  elseif (NOT (CONFIGURE_COMMAND IN_LIST ${pa_EXTERNAL_PROJECT_ARGS_LIST}))
    set (value "<DEFAULT>")
  else ()
    set (value "")
  endif ()

  set (_cooking_ep_configure_command ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_populate_ep_build_command ep_args_list)
  if (NOT (BUILD_COMMAND IN_LIST ${ep_args_list}))
    set (value BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR>)
  else ()
    set (value "")
  endif ()

  set (_cooking_ep_build_command ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_populate_ep_install_command ep_args_list)
  if (NOT (INSTALL_COMMAND IN_LIST ${ep_args_list}))
    set (value INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install)
  else ()
    set (value "")
  endif ()

  set (_cooking_ep_install_command ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_define_ep)
  cmake_parse_arguments (
    pa
    ""
    "NAME;SOURCE_DIR;BINARY_DIR;EXTERNAL_PROJECT_ARGS_LIST;RECIPE;INGREDIENT_DIR;STOW_DIR;LOCAL_RECONFIGURE;LOCAL_REBUILD"
    "DEPENDS;CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND;CMAKE_ARGS"
    ${ARGN})

  string (REPLACE "<DISABLE>" "" forwarded_ep_args "${${pa_EXTERNAL_PROJECT_ARGS_LIST}}")
  set (ep_name ingredient_${pa_NAME})
  include (ExternalProject)

  # Arguments that could be set to <DEFAULT> (which will be left unset in the ExternalProject_add
  # invocation) are not even provided to ExternalProject_add.
  set (ep_defaultable_args_list)
  if (NOT (pa_CONFIGURE_COMMAND STREQUAL "<DEFAULT>"))
    list (APPEND ep_defaultable_args_list CONFIGURE_COMMAND ${pa_CONFIGURE_COMMAND})
  endif()

  set (stamp_dir ${pa_INGREDIENT_DIR}/stamp)

  ExternalProject_add (${ep_name}
    DEPENDS ${pa_DEPENDS}
    SOURCE_DIR ${pa_SOURCE_DIR}
    BINARY_DIR ${pa_BINARY_DIR}
    BUILD_COMMAND ${pa_BUILD_COMMAND}
    INSTALL_COMMAND ${pa_INSTALL_COMMAND}
    PREFIX ${pa_INGREDIENT_DIR}
    STAMP_DIR ${stamp_dir}
    INSTALL_DIR ${pa_STOW_DIR}/${pa_NAME}
    CMAKE_ARGS ${pa_CMAKE_ARGS}
    LIST_SEPARATOR :::
    STEP_TARGETS install
    "${ep_defaultable_args_list}"
    "${forwarded_ep_args}")

  set (stow_marker_file ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${pa_NAME})
  set (lock_file ${Cooking_INGREDIENTS_DIR}/.cooking_stow.lock)

  add_custom_command (
    OUTPUT ${stow_marker_file}
    DEPENDS
      ${ep_name}-install
      ${stamp_dir}/ingredient_${pa_NAME}-install
    COMMAND
      flock
      --wait 30
      ${lock_file}
      ${Cooking_STOW_EXECUTABLE}
      -t ${Cooking_INGREDIENTS_DIR}
      -d ${pa_STOW_DIR}
      ${pa_NAME}
    COMMAND ${CMAKE_COMMAND} -E touch ${stow_marker_file})

  add_custom_target (_cooking_ingredient_${pa_NAME}_stowed
    DEPENDS ${stow_marker_file})

  if (pa_RECIPE)
    set (reconfigure_marker_file ${Cooking_INGREDIENTS_DIR}/.cooking_reconfigure_ingredient_${pa_NAME})

    add_custom_command (
      OUTPUT ${reconfigure_marker_file}
      COMMAND ${CMAKE_COMMAND} -E touch ${reconfigure_marker_file})

    add_custom_target (_cooking_ingredient_${pa_NAME}_marked_for_reconfigure
      DEPENDS ${reconfigure_marker_file})

    ExternalProject_add_step (${ep_name}
      cooking-reconfigure
      DEPENDERS configure
      DEPENDS ${reconfigure_marker_file}
      COMMAND ${CMAKE_COMMAND} -E echo_append)

    ExternalProject_add_stepdependencies (${ep_name}
      cooking-reconfigure
      _cooking_ingredient_${pa_NAME}_marked_for_reconfigure)
  endif ()

  foreach (d ${pa_DEPENDS})
    ExternalProject_add_stepdependencies (${ep_name}
      configure
      _cooking_${d}_stowed)
  endforeach ()

  add_dependencies (_cooking_ingredients _cooking_ingredient_${pa_NAME}_stowed)

  if (pa_LOCAL_RECONFIGURE OR pa_LOCAL_REBUILD)
    if (pa_LOCAL_RECONFIGURE)
      set (step configure)
    else ()
      set (step build)
    endif ()

    ExternalProject_add_step (${ep_name}
      cooking-local-${step}
      DEPENDERS ${step}
      DEPENDS ${_cooking_local_synchronize_marker_file}
      COMMAND ${CMAKE_COMMAND} -E echo_append)

    ExternalProject_add_stepdependencies (${ep_name}
      cooking-local-${step}
      _cooking_marked_for_local_synchronization)
  endif ()
endfunction ()

macro (cooking_ingredient name)
  set (_cooking_args "${ARGN}")

  if ((_cooking_is_excluding AND (${name} IN_LIST Cooking_EXCLUDED_INGREDIENTS))
      OR (_cooking_is_including AND (NOT (${name} IN_LIST Cooking_INCLUDED_INGREDIENTS))))
    # Nothing.
  else ()
    set (_cooking_ingredient_dir ${_cooking_dir}/ingredient/${name})

    cmake_parse_arguments (
      _cooking_pa
      "LOCAL_RECONFIGURE;LOCAL_REBUILD"
      "COOKING_RECIPE"
      "CMAKE_ARGS;COOKING_CMAKE_ARGS;EXTERNAL_PROJECT_ARGS;REQUIRES"
      ${_cooking_args})

    _cooking_populate_ep_parameter (
      EXTERNAL_PROJECT_ARGS_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS
      PARAMETER SOURCE_DIR
      DEFAULT_VALUE ${_cooking_ingredient_dir}/src)

    _cooking_populate_ep_parameter (
      EXTERNAL_PROJECT_ARGS_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS
      PARAMETER BINARY_DIR
      DEFAULT_VALUE ${_cooking_ingredient_dir}/build)

    _cooking_populate_ep_parameter (
      EXTERNAL_PROJECT_ARGS_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS
      PARAMETER BUILD_IN_SOURCE
      DEFAULT_VALUE OFF)

    if (_cooking_build_in_source)
       set (_cooking_ep_binary_dir "")
    endif ()

    if (Cooking_LIST_ONLY)
      _cooking_define_listing_targets (
        NAME ${name}
        SOURCE_DIR ${_cooking_source_dir}
        RECIPE ${_cooking_pa_COOKING_RECIPE}
        REQUIRES ${_cooking_pa_REQUIRES})
    else ()
      _cooking_adjust_requirements (
        IS_EXCLUDING ${_cooking_is_excluding}
        IS_INCLUDING ${_cooking_is_including}
        REQUIREMENTS ${_cooking_pa_REQUIRES}
        OUTPUT_LIST _cooking_pa_REQUIRES)

      _cooking_populate_ep_depends (
        REQUIREMENTS ${_cooking_pa_REQUIRES})

      _cooking_determine_common_cmake_args (_cooking_common_cmake_args)

      _cooking_populate_ep_configure_command (
        IS_EXCLUDING ${_cooking_is_excluding}
        IS_INCLUDING ${_cooking_is_including}
        RECIPE ${_cooking_pa_COOKING_RECIPE}
        REQUIREMENTS ${_cooking_pa_REQUIRES}
        EXTERNAL_PROJECT_ARGS_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS
        CMAKE_ARGS
          ${_cooking_common_cmake_args}
          ${_cooking_pa_CMAKE_ARGS}
        COOKING_CMAKE_ARGS
          ${_cooking_common_cmake_args}
          ${_cooking_pa_COOKING_CMAKE_ARGS})

      _cooking_populate_ep_build_command (_cooking_pa_EXTERNAL_PROJECT_ARGS)
      _cooking_populate_ep_install_command (_cooking_pa_EXTERNAL_PROJECT_ARGS)

      _cooking_define_ep (
        NAME ${name}
        RECIPE ${_cooking_pa_COOKING_RECIPE}
        DEPENDS ${_cooking_ep_depends}
        SOURCE_DIR ${_cooking_ep_source_dir}
        BINARY_DIR ${_cooking_ep_binary_dir}
        CONFIGURE_COMMAND ${_cooking_ep_configure_command}
        BUILD_COMMAND ${_cooking_ep_build_command}
        INSTALL_COMMAND ${_cooking_ep_install_command}
        INGREDIENT_DIR ${_cooking_ingredient_dir}
        STOW_DIR ${_cooking_dir}/stow
        CMAKE_ARGS ${_cooking_common_cmake_args}
        EXTERNAL_PROJECT_ARGS_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS
        LOCAL_RECONFIGURE ${_cooking_pa_LOCAL_RECONFIGURE}
        LOCAL_REBUILD ${_cooking_pa_LOCAL_REBUILD})
    endif ()
  endif ()
endmacro ()
