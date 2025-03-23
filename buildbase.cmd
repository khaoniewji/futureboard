@echo off
@REM cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
rmdir /s /q build
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=M:/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_PREFIX_PATH=%QTDIR% -DCMAKE_BUILD_TYPE=Debug
cmake --build build --config Debug
%QTDIR%\bin\windeployqt --qmldir %QTDIR%\qml  .\build\Debug\Futureboard.exe
copy .\build\external\portaudio\bin\portaudio_x64.dll .\build\Debug
REM End of snippet