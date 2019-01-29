cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})
include (Cooking OPTIONAL)

project (CustomRecipeConsumer
  LANGUAGES CXX)

add_executable (consumer
  main.cc)
