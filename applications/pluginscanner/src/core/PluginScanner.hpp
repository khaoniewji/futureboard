#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_core/juce_core.h>
#include <clap/clap.h>
#include <string>
#include <vector>
#include <filesystem>
#include <memory>
#include <atomic>
#include <functional>
#include <mutex>
#include <ostream>

namespace futureboard {

enum class ProcessorArchitecture {
    X86_64,
    X86,
    ARM64,
    ARM32,
    UNKNOWN
};

enum class PluginFormat {
    VST2,
    VST3,
    CLAP,
    UNKNOWN
};

// Forward declare operator<< for PluginFormat
std::ostream& operator<<(std::ostream& os, const PluginFormat& format);

struct PluginInfo {
    std::string name;
    std::string version;
    std::string path;
    std::string vendor;
    ProcessorArchitecture arch;
    PluginFormat format;
    bool isValid = false;
    std::string uniqueId;
    std::vector<std::string> categories;
    bool isSynth = false;
    bool isEffect = false;
    std::string error;

    // JUCE specific
    juce::String formatName;
    juce::String manufacturerName;
    int numInputChannels = 0;
    int numOutputChannels = 0;
    bool acceptsMidi = false;
    bool producesMidi = false;

    // CLAP specific
    std::string clapId;
    std::vector<std::string> features;
};

class PluginScanner {
public:
    using ProgressCallback = std::function<void(const std::string&, float)>;

    PluginScanner();
    ~PluginScanner();

    void scanPlugins(const ProgressCallback& progress = nullptr);
    void stopScanning();

    void addSearchPath(const std::string& path);
    void clearSearchPaths();
    void setFormatsToScan(bool scanVST2, bool scanVST3, bool scanCLAP);

    bool saveToPreset(const std::string& filePath);
    bool loadFromPreset(const std::string& filePath);
    const std::vector<PluginInfo>& getPlugins() const;

    bool isScanning() const;
    size_t getTotalPluginsFound() const;

    static ProcessorArchitecture detectSystemArchitecture();
    static std::string architectureToString(ProcessorArchitecture arch);
    static ProcessorArchitecture stringToArchitecture(const std::string& archStr);
    static std::string formatToString(PluginFormat format);
    static PluginFormat stringToFormat(const std::string& formatStr);

private:
    void scanDirectory(const std::filesystem::path& path);
    bool isPluginFile(const std::filesystem::path& path);
    void scanAndValidatePlugin(const std::filesystem::path& path);

    bool validatePlugin(const std::filesystem::path& path, PluginInfo& info);
    bool validateWithJuce(const std::filesystem::path& path, PluginInfo& info);
    bool validateCLAPPlugin(const std::filesystem::path& path, PluginInfo& info);

    bool writeXMLPreset(const std::string& filePath);
    bool readXMLPreset(const std::string& filePath);

    void reportProgress(const std::string& message, float progress);
    std::vector<std::filesystem::path> getDefaultPluginPaths();
    void initializeJuceFormats();

    static const clap_plugin_factory* getCLAPFactory(void* library, const std::string& path);

private:
    std::vector<std::filesystem::path> searchPaths;
    std::vector<PluginInfo> discoveredPlugins;
    std::atomic<bool> scanning;
    std::atomic<bool> stopRequested;
    ProgressCallback progressCallback;
    mutable std::mutex pluginsMutex;

    std::unique_ptr<juce::AudioPluginFormatManager> formatManager;

    bool enableVST2;
    bool enableVST3;
    bool enableCLAP;
};

} // namespace futureboard
