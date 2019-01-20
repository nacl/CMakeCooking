cmake_minimum_required (VERSION 3.5)

project (CaseEPSourceSubdirDep)

add_executable (dep
  ${CMAKE_CURRENT_SOURCE_DIR}/../main.cc)
