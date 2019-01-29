cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})
include (Cooking OPTIONAL)

project (CustomRecipeProject
  LANGUAGES CXX)

find_package (Egg REQUIRED)

add_executable (project
  main.cc)
