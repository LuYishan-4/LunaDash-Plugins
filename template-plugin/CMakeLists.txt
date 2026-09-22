cmake_minimum_required(VERSION 3.21)
project(lunadash_example_plugin VERSION 1.0.1 LANGUAGES CXX)

find_package(LunaDashPlugin 2 CONFIG REQUIRED)

lunadash_add_plugin(lunadash-example-plugin
    METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json"
    FILES Main.qml)
