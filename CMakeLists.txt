# Set the minimum CMake version required
cmake_minimum_required(VERSION 3.16)

# Project name and version
project(Futureboard VERSION 1.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set Qt prefix path if needed
if(NOT DEFINED CMAKE_PREFIX_PATH AND DEFINED ENV{QTDIR})
    set(CMAKE_PREFIX_PATH "$ENV{QTDIR}")
endif()

# Find required packages
find_package(Qt6 CONFIG REQUIRED COMPONENTS 
    Core 
    Gui 
    Quick 
    Widgets 
    QuickWidgets 
    Qml
    QuickControls2  # Add this line
)
# Add ExternalProject support
include(ExternalProject)

# Set runtime library settings (before ExternalProject_Add)
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    set(MSVC_RUNTIME_FLAGS 
        $<$<CONFIG:Debug>:/MDd>
        $<$<CONFIG:Release>:/MD>
        $<$<CONFIG:RelWithDebInfo>:/MD>
        $<$<CONFIG:MinSizeRel>:/MD>
    )
endif()

# Set ASIO SDK path - adjust this to your ASIO SDK location
set(ASIOSDK_ROOT_DIR "${CMAKE_SOURCE_DIR}/external/ASIOSDK" CACHE PATH "Path to ASIO SDK")

# Verify ASIO SDK exists
if(NOT EXISTS "${ASIOSDK_ROOT_DIR}/common/iasiodrv.h")
    message(FATAL_ERROR "ASIO SDK not found at ${ASIOSDK_ROOT_DIR}. Please install the ASIO SDK from Steinberg's website.")
endif()

# Configure PortAudio as external project
ExternalProject_Add(portaudio
    GIT_REPOSITORY    https://github.com/PortAudio/portaudio.git
    GIT_TAG          v19.7.0
    CMAKE_ARGS      -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/portaudio
                    -DPA_BUILD_STATIC=OFF
                    -DPA_BUILD_SHARED=ON
                    -DPA_USE_ASIO=ON
                    -DASIOSDK_ROOT_DIR=${ASIOSDK_ROOT_DIR}
                    -DPA_USE_WASAPI=ON
                    -DPA_USE_WDMKS=ON
                    -DPA_USE_DS=ON
                    -DPA_USE_WMME=ON
                    -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY}
                    "-DCMAKE_C_FLAGS=${MSVC_RUNTIME_FLAGS}"
                    "-DCMAKE_CXX_FLAGS=${MSVC_RUNTIME_FLAGS}"
    PREFIX          ${CMAKE_BINARY_DIR}/external/portaudio
    BUILD_BYPRODUCTS ${CMAKE_BINARY_DIR}/external/portaudio/bin/portaudio_x64.dll
)

# Source files
file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
    "src/*.cpp"
    "src/*.hpp"
    "src/*.h"
)

# Specify the Windows SDK include directory
include_directories("C:/Program Files (x86)/Windows Kits/10/Include/10.0.22621.0/um")
include_directories("C:/Program Files (x86)/Windows Kits/10/Include/10.0.22621.0/shared")
include_directories("C:/Program Files (x86)/Windows Kits/10/Include/10.0.22621.0/winrt")

# Resource files
set(RESOURCE_FILES ${CMAKE_SOURCE_DIR}/resources/shared.qrc)
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/resources/app.rc")

# Add the executable target and include resource files
add_executable(${PROJECT_NAME} WIN32 
    ${SRC_FILES}
    ${RESOURCE_FILES}
    ${app_icon_resource_windows}
)

# Link libraries to the target
target_link_libraries(${PROJECT_NAME} 
    PRIVATE
    Qt6::Core 
    Qt6::Gui 
    Qt6::Quick 
    Qt6::Widgets
    Qt6::QuickWidgets
    Qt::Qml
    Qt6::QuickControls2  # Add this line
    pdh
    ${CMAKE_BINARY_DIR}/external/portaudio/lib/portaudio_x64${CMAKE_IMPORT_LIBRARY_SUFFIX}
)

# Add dependency on portaudio build
add_dependencies(${PROJECT_NAME} portaudio)

# Remove JUCE-specific settings
target_compile_definitions(${PROJECT_NAME} 
    PRIVATE 
        PLATFORM_DESKTOP=$<BOOL:${PLATFORM_DESKTOP}>
        _WIN32_WINNT=0x0601  # Windows 7 target
)

# Set include directories for headers
target_include_directories(${PROJECT_NAME} 
    PRIVATE 
    src
    ${CMAKE_BINARY_DIR}/external/portaudio/include
    ${CMAKE_BINARY_DIR}/external/portaudio/src/portaudio/include
    ${CMAKE_BINARY_DIR}/external/portaudio/src/portaudio/src/common
    ${CMAKE_BINARY_DIR}/external/portaudio/src/portaudio/src/hostapi/asio/ASIOSDK/common
    ${ASIOSDK_ROOT_DIR}/common
    ${ASIOSDK_ROOT_DIR}/host
    ${ASIOSDK_ROOT_DIR}/host/pc
)

# # Add ASIO SDK source files
# target_sources(Futureboard PRIVATE
#     ${CMAKE_SOURCE_DIR}/external/asio/asio.cpp
#     ${CMAKE_SOURCE_DIR}/external/asio/asiodrivers.cpp
#     ${CMAKE_SOURCE_DIR}/external/asio/asiolist.cpp
# )

# # Add ASIO SDK include directories
# target_include_directories(Futureboard PRIVATE
#     ${CMAKE_SOURCE_DIR}/external/asio
# )

# Enable automatic MOC, RCC, and UIC
set_target_properties(${PROJECT_NAME} PROPERTIES
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
)

# Add linker flags to handle LIBCMTD conflict
if(MSVC)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        LINK_FLAGS "/NODEFAULTLIB:LIBCMTD"
    )
endif()

# Enable platform-specific options
if(PLATFORM STREQUAL "desktop")
    target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM_DESKTOP)
elseif(PLATFORM STREQUAL "mobile")
    target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM_MOBILE)
endif()

# Add feature summary
include(FeatureSummary)
feature_summary(WHAT ALL)

# Install rules
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
    LIBRARY DESTINATION lib
)

# Install QML modules
install(DIRECTORY ${CMAKE_SOURCE_DIR}/resources/qml/Styles
        DESTINATION ${CMAKE_BINARY_DIR}/qml
        FILES_MATCHING PATTERN "*.qml" PATTERN "qmldir"
)

# Copy QML modules to build directory
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/resources/qml/Styles
    ${CMAKE_BINARY_DIR}/qml/Styles
)

# Copy PortAudio DLL to output directories
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    # COMMAND ${CMAKE_COMMAND} -E copy_if_different
    #     ${CMAKE_BINARY_DIR}/external/portaudio/bin/portaudio${CMAKE_SHARED_LIBRARY_SUFFIX}
    #     $<TARGET_FILE_DIR:${PROJECT_NAME}>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/external/portaudio/bin/portaudio_x64${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${CMAKE_BINARY_DIR}/Debug
)

# Set QML import path
set(QML_IMPORT_PATH ${CMAKE_BINARY_DIR}/qml CACHE STRING "Qt Creator extra QML import paths" FORCE)

# Set runtime library for our project to match Qt's MD/MDd
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()
