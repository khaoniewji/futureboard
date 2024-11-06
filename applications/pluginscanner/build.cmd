@echo off
setlocal

:: Check if VCPKG_ROOT is set
if not defined VCPKG_ROOT (
    echo Error: VCPKG_ROOT environment variable is not set
    exit /b 1
)

:: Create build directory
if not exist build mkdir build

:: Configure
cmake -B build -S . ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake"

if errorlevel 1 (
    echo CMAKE configuration failed
    exit /b 1
)

:: Build
cmake --build build --config Release

if errorlevel 1 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully!
endlocal
