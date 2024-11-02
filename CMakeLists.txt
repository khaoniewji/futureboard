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
find_package(Qt6 CONFIG REQUIRED COMPONENTS Core Gui Quick Widgets QuickWidgets)

# Source files
file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
    "src/*.cpp"
    "src/*.hpp"
)

# Find the PortAudio package
find_package(PortAudio REQUIRED)

# Include the PortAudio headers
include_directories(${PORTAUDIO_INCLUDE_DIRS})
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
    ${PORTAUDIO_LIBRARIES}
)

# Link libraries to the target
target_link_libraries(${PROJECT_NAME} 
    PRIVATE
    Qt6::Core 
    Qt6::Gui 
    Qt6::Quick 
    Qt6::Widgets
    Qt6::QuickWidgets
)

# Set include directories for headers
target_include_directories(${PROJECT_NAME} 
    PRIVATE 
    src
)

# Enable automatic MOC, RCC, and UIC
set_target_properties(${PROJECT_NAME} PROPERTIES
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
)

# Enable platform-specific options
if(PLATFORM STREQUAL "desktop")
    target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM_DESKTOP)
elseif(PLATFORM STREQUAL "mobile")
    target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM_MOBILE)
endif()

# Add feature summary
include(FeatureSummary)
feature_summary(WHAT ALL)
