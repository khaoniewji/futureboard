@echo off
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --config Debug
%QTDIR%\bin\windeployqt .\build\Debug\Futureboard.exe