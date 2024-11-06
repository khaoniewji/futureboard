cmake_minimum_required(VERSION 3.15)

# Set vcpkg toolchain file directly if VCPKG_ROOT is set
if(DEFINED ENV{VCPKG_ROOT})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
endif()

# JUCE specific settings
set(JUCE_GLOBAL_MODULE_SETTINGS_INCLUDED ON)
set(JUCE_USE_CURL OFF)
set(JUCE_WEB_BROWSER OFF)

if(WIN32)
    set(CMAKE_SYSTEM_VERSION 10.0 CACHE STRING "")
endif()

project(vstscanner
    VERSION 0.1.0
    DESCRIPTION "VST Plugin Scanner"
    LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Find dependencies
find_package(pugixml CONFIG REQUIRED)
find_package(JUCE CONFIG REQUIRED)
find_package(clap CONFIG REQUIRED)

# Source files
set(SOURCES
    src/main.cpp
    src/core/PluginScanner.cpp
)

# Headers
set(HEADERS
    src/core/PluginScanner.hpp
)

# Create executable
add_executable(vstscanner ${SOURCES} ${HEADERS})

# Include directories
target_include_directories(vstscanner
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/core
        ${CMAKE_SOURCE_DIR}/SDKs/VST24
)

# Link libraries
target_link_libraries(vstscanner
    PRIVATE
        pugixml::pugixml
        juce::juce_audio_processors
        juce::juce_audio_basics
        juce::juce_core
        clap
)

# JUCE specific settings
target_compile_definitions(vstscanner
    PRIVATE
        JUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1
        JUCE_STANDALONE_APPLICATION=1
        JUCE_USE_CURL=0
        JUCE_WEB_BROWSER=0
        JUCE_PLUGINHOST_VST3=1
        JUCE_PLUGINHOST_VST=1
        JUCE_PLUGINHOST_AU=0
        JUCE_PLUGINHOST_LADSPA=0
        JUCE_DISABLE_ASSERTIONS=1
)

# Windows specific settings
if(WIN32)
    target_compile_definitions(vstscanner
        PRIVATE
            WIN32_LEAN_AND_MEAN
            NOMINMAX
            _CRT_SECURE_NO_WARNINGS
            UNICODE
            _UNICODE
    )
endif()

# Install rules
include(GNUInstallDirs)
install(TARGETS vstscanner
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Enable folders for IDEs
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Set startup project for Visual Studio
set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT vstscanner)

if(WIN32)
    # Configure version resource
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/version.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc
        @ONLY
    )

    # Add only the version resource
    target_sources(vstscanner
        PRIVATE
            ${CMAKE_CURRENT_BINARY_DIR}/version.rc
            # Remove or comment out the icon line if you don't have an icon
            ${CMAKE_CURRENT_SOURCE_DIR}/resources/icon.ico
    )
endif()

# Debug information
message(STATUS "VCPKG_ROOT: $ENV{VCPKG_ROOT}")
message(STATUS "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")
