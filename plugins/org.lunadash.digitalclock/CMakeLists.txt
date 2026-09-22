cmake_minimum_required(VERSION 3.21)
project(lunadash_digital_clock VERSION 2.1.0 LANGUAGES CXX)

find_package(LunaDashPlugin 2 CONFIG REQUIRED)

lunadash_add_plugin(lunadash-digital-clock
    METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json"
    FILES Main.qml)
