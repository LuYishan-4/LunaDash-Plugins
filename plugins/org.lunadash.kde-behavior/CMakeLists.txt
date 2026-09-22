cmake_minimum_required(VERSION 3.21)
project(lunadash_kde_behavior VERSION 2.0.0 LANGUAGES C CXX)

if(NOT COMMAND lunadash_add_plugin)
    find_package(LunaDashPlugin 2 CONFIG REQUIRED)
endif()
find_package(Qt6 6.4 REQUIRED COMPONENTS Core)

lunadash_add_plugin(lunadash-kde-behavior
    METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json"
    SOURCES Effect.cpp
    FILES KdePanel.qml)
target_link_libraries(lunadash-kde-behavior PRIVATE Qt6::Core)
