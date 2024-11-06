#include "PluginScanner.hpp"
#include <juce_core/juce_core.h>
#include <juce_audio_processors/juce_audio_processors.h>
#include <windows.h>
#include <iostream>
#include <string>
#include <ctime>
#include <iomanip>
#include <sstream>

void printUsage() {
    std::cout << "VST Scanner Usage:\n"
              << "vstscanner -s [-o output_path]\n"
              << "  -s           : Scan for plugins\n"
              << "  -o path      : Output directory (default: current directory)\n"
              << "Example: vstscanner -s -o C:\\Output\n";
}

void printProgress(const std::string& message) {
    static HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(hConsole, &csbi);

    // Clear line
    SetConsoleCursorPosition(hConsole, { 0, csbi.dwCursorPosition.Y });
    for (int i = 0; i < csbi.dwSize.X; i++) std::cout << " ";
    SetConsoleCursorPosition(hConsole, { 0, csbi.dwCursorPosition.Y });

    // Print message
    std::cout << message << std::flush;
}

std::string getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time), "%Y%m%d_%H%M%S");
    return ss.str();
}

void printPluginInfo(const futureboard::PluginInfo& plugin) {
    std::cout << "Name: " << plugin.name << "\n";
    std::cout << "Format: " << plugin.format << "\n";
    std::cout << "Version: " << plugin.version << "\n";
    std::cout << "Vendor: " << plugin.vendor << "\n";
    std::cout << "Architecture: " << futureboard::PluginScanner::architectureToString(plugin.arch) << "\n";
    std::cout << "Path: " << plugin.path << "\n";
    std::cout << "Valid: " << (plugin.isValid ? "Yes" : "No") << "\n";

    if (!plugin.error.empty()) {
        std::cout << "Error: " << plugin.error << "\n";
    }

    if (plugin.isValid) {
        std::cout << "Type: "
                  << (plugin.isSynth ? "Instrument" : "")
                  << (plugin.isEffect ? "Effect" : "") << "\n";

        std::cout << "Audio: "
                  << plugin.numInputChannels << " in, "
                  << plugin.numOutputChannels << " out\n";

        std::cout << "MIDI: "
                  << (plugin.acceptsMidi ? "Accepts" : "No input")
                  << ", "
                  << (plugin.producesMidi ? "Produces" : "No output") << "\n";

        if (!plugin.categories.empty()) {
            std::cout << "Categories: ";
            for (const auto& category : plugin.categories) {
                std::cout << category << " ";
            }
            std::cout << "\n";
        }

        if (!plugin.features.empty()) {
            std::cout << "Features: ";
            for (const auto& feature : plugin.features) {
                std::cout << feature << " ";
            }
            std::cout << "\n";
        }
    }

    std::cout << "-------------------\n";
}

int main(int argc, char* argv[]) {
    // Set console title and get handle
    SetConsoleTitle(TEXT("Futureboard VST Scanner"));
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

    // Parse command line arguments
    std::string outputPath = ".";
    bool shouldScan = false;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "-s") {
            shouldScan = true;
        }
        else if (arg == "-o" && i + 1 < argc) {
            outputPath = argv[++i];
        }
        else {
            printUsage();
            return 1;
        }
    }

    if (!shouldScan) {
        printUsage();
        return 1;
    }

    try {
        // Create scanner instance
        futureboard::PluginScanner scanner;

        // Print header
        SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN | FOREGROUND_INTENSITY);
        std::cout << "\nFutureboard VST Scanner\n";
        std::cout << "======================\n\n";
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);

        // Start scanning with progress callback
        scanner.scanPlugins([](const std::string& message, float progress) {
            std::stringstream ss;
            ss << message;
            if (progress >= 0) {
                ss << " (" << static_cast<int>(progress * 100) << "%)";
            }
            printProgress(ss.str());
        });

        // Get scan results
        const auto& plugins = scanner.getPlugins();

        // Print results header
        SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN | FOREGROUND_INTENSITY);
        std::cout << "\nFound " << plugins.size() << " plugins:\n\n";
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);

        // Print details for each plugin
        for (const auto& plugin : plugins) {
            printPluginInfo(plugin);
        }

        // Generate output filename with timestamp
        std::filesystem::path outputFilePath = std::filesystem::path(outputPath) /
            ("scan_result_" + getCurrentTimestamp() + ".ftbpreset");

        // Save results
        SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY);
        std::cout << "\nSaving results to: " << outputFilePath << "\n";

        if (scanner.saveToPreset(outputFilePath.string())) {
            SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN | FOREGROUND_INTENSITY);
            std::cout << "Scan completed successfully!\n";
        }
        else {
            throw std::runtime_error("Failed to save scan results");
        }

        // Print summary
        SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN | FOREGROUND_INTENSITY);
        std::cout << "\nScan Summary:\n";
        std::cout << "-------------\n";
        std::cout << "Total plugins found: " << plugins.size() << "\n";

        size_t validCount = 0;
        size_t vst2Count = 0;
        size_t vst3Count = 0;
        size_t clapCount = 0;
        size_t synthCount = 0;
        size_t effectCount = 0;

        for (const auto& plugin : plugins) {
            if (plugin.isValid) validCount++;
            if (plugin.format == futureboard::PluginFormat::VST2) vst2Count++;
            if (plugin.format == futureboard::PluginFormat::VST3) vst3Count++;
            if (plugin.format == futureboard::PluginFormat::CLAP) clapCount++;
            if (plugin.isSynth) synthCount++;
            if (plugin.isEffect) effectCount++;
        }

        std::cout << "Valid plugins: " << validCount << "\n";
        std::cout << "VST2 plugins: " << vst2Count << "\n";
        std::cout << "VST3 plugins: " << vst3Count << "\n";
        std::cout << "CLAP plugins: " << clapCount << "\n";
        std::cout << "Instruments: " << synthCount << "\n";
        std::cout << "Effects: " << effectCount << "\n";
    }
    catch (const std::exception& e) {
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_INTENSITY);
        std::cerr << "\nError: " << e.what() << "\n";
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
        return 1;
    }
    catch (...) {
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_INTENSITY);
        std::cerr << "\nUnknown error occurred\n";
        SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
        return 1;
    }

    // Reset console color
    SetConsoleTextAttribute(hConsole, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
    return 0;
}
