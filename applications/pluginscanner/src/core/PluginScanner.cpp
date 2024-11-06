#include "PluginScanner.hpp"
#include <juce_core/juce_core.h>
#include <juce_audio_processors/juce_audio_processors.h>
#include <pugixml.hpp>
#include <iostream>
#include <thread>
#include <chrono>

#ifdef _WIN32
    #include <windows.h>
    #include <shlobj.h>
#elif defined(__APPLE__)
    #include <sys/sysctl.h>
    #include <mach-o/dyld.h>
#else
    #include <sys/utsname.h>
    #include <dlfcn.h>
#endif

namespace futureboard {

std::ostream& operator<<(std::ostream& os, const PluginFormat& format) {
    switch (format) {
        case PluginFormat::VST2: return os << "VST2";
        case PluginFormat::VST3: return os << "VST3";
        case PluginFormat::CLAP: return os << "CLAP";
        default: return os << "Unknown";
    }
}

PluginScanner::PluginScanner()
    : scanning(false)
    , stopRequested(false)
    , formatManager(std::make_unique<juce::AudioPluginFormatManager>())
    , enableVST2(true)
    , enableVST3(true)
    , enableCLAP(true)
{
    juce::MessageManager::getInstance(); // Ensure message manager is initialized
    initializeJuceFormats();
    auto defaultPaths = getDefaultPluginPaths();
    searchPaths.insert(searchPaths.end(), defaultPaths.begin(), defaultPaths.end());
}

PluginScanner::~PluginScanner() {
    stopScanning();
}

void PluginScanner::initializeJuceFormats() {
    // Add VST3 format first
    if (enableVST3) {
        formatManager->addFormat(new juce::VST3PluginFormat());
    }
    // Then add VST2 format
    if (enableVST2) {
        formatManager->addFormat(new juce::VSTPluginFormat());
    }
}

void PluginScanner::scanPlugins(const ProgressCallback& progress) {
    if (scanning) return;

    scanning = true;
    stopRequested = false;
    progressCallback = progress;

    {
        std::lock_guard<std::mutex> lock(pluginsMutex);
        discoveredPlugins.clear();
    }

    size_t totalPaths = searchPaths.size();
    size_t currentPath = 0;

    for (const auto& path : searchPaths) {
        if (stopRequested) break;

        float pathProgress = static_cast<float>(currentPath) / totalPaths;
        reportProgress("Scanning: " + path.string(), pathProgress);

        scanDirectory(path);
        currentPath++;
    }

    reportProgress("Scan completed", 1.0f);
    scanning = false;
}

void PluginScanner::stopScanning() {
    if (scanning) {
        stopRequested = true;
        while (scanning) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
}

void PluginScanner::scanDirectory(const std::filesystem::path& path) {
    if (!std::filesystem::exists(path)) return;

    try {
        for (const auto& entry : std::filesystem::recursive_directory_iterator(path)) {
            if (stopRequested) return;

            if (!entry.is_regular_file()) continue;

            if (isPluginFile(entry.path())) {
                reportProgress("Scanning: " + entry.path().filename().string(), -1.0f);
                scanAndValidatePlugin(entry.path());
            }
        }
    }
    catch (const std::exception& e) {
        reportProgress("Error scanning directory: " + std::string(e.what()), -1.0f);
    }
}

bool PluginScanner::isPluginFile(const std::filesystem::path& path) {
    auto extension = path.extension().string();
    return (enableVST2 && (extension == ".dll" || extension == ".so" || extension == ".vst")) ||
           (enableVST3 && extension == ".vst3") ||
           (enableCLAP && extension == ".clap");
}

void PluginScanner::scanAndValidatePlugin(const std::filesystem::path& path) {
    PluginInfo info;
    info.path = path.string();
    info.arch = detectSystemArchitecture();

    auto extension = path.extension().string();
    if (extension == ".vst3") {
        info.format = PluginFormat::VST3;
    } else if (extension == ".clap") {
        info.format = PluginFormat::CLAP;
    } else {
        info.format = PluginFormat::VST2;
    }

    bool isValid = false;

    if (info.format == PluginFormat::CLAP) {
        isValid = validateCLAPPlugin(path, info);
    } else {
        isValid = validateWithJuce(path, info);
    }

    if (!isValid) {
        info.name = path.stem().string();
        info.version = "Unknown";
        info.vendor = "Unknown";
    }

    std::lock_guard<std::mutex> lock(pluginsMutex);
    discoveredPlugins.push_back(info);
}

bool PluginScanner::validateWithJuce(const std::filesystem::path& path, PluginInfo& info) {
    juce::String errorMessage;

    juce::AudioPluginFormat* format = nullptr;
    if (path.extension() == ".vst3") {
        // Get VST3 format (should be first in the list after initialization)
        format = formatManager->getFormat(0);
    } else {
        // Get VST2 format (should be second in the list)
        format = formatManager->getFormat(1);
    }

    if (!format) {
        info.error = "Unsupported format";
        return false;
    }

    try {
        juce::OwnedArray<juce::PluginDescription> descriptions;
        format->findAllTypesForFile(descriptions, path.string());

        if (descriptions.isEmpty()) {
            info.error = "No plugin found in file";
            return false;
        }

        auto* desc = descriptions[0];
        if (desc == nullptr) {
            info.error = "Invalid plugin description";
            return false;
        }

        // Fill in the plugin information
        info.name = desc->name.toStdString();
        info.version = desc->version.toStdString();
        info.vendor = desc->manufacturerName.toStdString();
        info.formatName = desc->pluginFormatName;
        info.manufacturerName = desc->manufacturerName;
        info.numInputChannels = desc->numInputChannels;
        info.numOutputChannels = desc->numOutputChannels;
        info.acceptsMidi = desc->isInstrument;
        info.uniqueId = juce::String(desc->uniqueId).toStdString();
        info.categories = { desc->category.toStdString() };
        info.isSynth = desc->isInstrument;
        info.isEffect = !desc->isInstrument;
        info.isValid = true;

        return true;
    }
    catch (const std::exception& e) {
        info.error = std::string("Validation error: ") + e.what();
        return false;
    }
}

bool PluginScanner::validateCLAPPlugin(const std::filesystem::path& path, PluginInfo& info) {
#ifdef _WIN32
    HMODULE handle = LoadLibraryW(path.wstring().c_str());
    if (!handle) {
        info.error = "Failed to load library";
        return false;
    }

    auto factory = getCLAPFactory(handle, path.string());
    if (!factory) {
        FreeLibrary(handle);
        info.error = "No CLAP factory found";
        return false;
    }

    uint32_t count = factory->get_plugin_count(factory);
    if (count == 0) {
        FreeLibrary(handle);
        info.error = "No CLAP plugins found in factory";
        return false;
    }

    const clap_plugin_descriptor* desc = factory->get_plugin_descriptor(factory, 0);
    if (!desc) {
        FreeLibrary(handle);
        info.error = "Failed to get plugin descriptor";
        return false;
    }

    info.name = desc->name;
    info.version = desc->version;
    info.vendor = desc->vendor;
    info.clapId = desc->id;

    for (const char* const* feature = desc->features; *feature != nullptr; ++feature) {
        info.features.push_back(*feature);
        if (strcmp(*feature, CLAP_PLUGIN_FEATURE_INSTRUMENT) == 0) {
            info.isSynth = true;
        }
        if (strcmp(*feature, CLAP_PLUGIN_FEATURE_AUDIO_EFFECT) == 0) {
            info.isEffect = true;
        }
    }

    info.isValid = true;
    FreeLibrary(handle);
    return true;
#else
    void* handle = dlopen(path.c_str(), RTLD_LAZY);
    if (!handle) {
        info.error = dlerror();
        return false;
    }

    auto factory = getCLAPFactory(handle, path.string());
    if (!factory) {
        dlclose(handle);
        info.error = "No CLAP factory found";
        return false;
    }

    // Same validation as Windows...

    info.isValid = true;
    dlclose(handle);
    return true;
#endif
}

const clap_plugin_factory* PluginScanner::getCLAPFactory(void* library, const std::string& path) {
#ifdef _WIN32
    auto entryProc = reinterpret_cast<const clap_plugin_entry*>(
        GetProcAddress((HMODULE)library, "clap_entry"));
#else
    auto entryProc = reinterpret_cast<const clap_plugin_entry*>(
        dlsym(library, "clap_entry"));
#endif

    if (!entryProc) return nullptr;

    if (!entryProc->init(path.c_str())) return nullptr;

    return static_cast<const clap_plugin_factory*>(
        entryProc->get_factory(CLAP_PLUGIN_FACTORY_ID));
}

void PluginScanner::addSearchPath(const std::string& path) {
    if (std::filesystem::exists(path)) {
        searchPaths.push_back(path);
    }
}

void PluginScanner::clearSearchPaths() {
    searchPaths.clear();
}

void PluginScanner::setFormatsToScan(bool scanVST2, bool scanVST3, bool scanCLAP) {
    enableVST2 = scanVST2;
    enableVST3 = scanVST3;
    enableCLAP = scanCLAP;
}

std::vector<std::filesystem::path> PluginScanner::getDefaultPluginPaths() {
    std::vector<std::filesystem::path> paths;

#ifdef _WIN32
    paths.push_back("C:/Program Files/Common Files/VST3");
    paths.push_back("C:/Program Files/Common Files/VST2");
    paths.push_back("C:/Program Files/Common Files/CLAP");
#elif defined(__APPLE__)
    paths.push_back("/Library/Audio/Plug-Ins/VST");
    paths.push_back("/Library/Audio/Plug-Ins/VST3");
    paths.push_back("/Library/Audio/Plug-Ins/CLAP");
#else
    paths.push_back("/usr/lib/vst");
    paths.push_back("/usr/lib/vst3");
    paths.push_back("/usr/lib/clap");
#endif

    return paths;
}

ProcessorArchitecture PluginScanner::detectSystemArchitecture() {
#ifdef _WIN32
    SYSTEM_INFO sysInfo;
    GetNativeSystemInfo(&sysInfo);

    switch (sysInfo.wProcessorArchitecture) {
        case PROCESSOR_ARCHITECTURE_AMD64:
            return ProcessorArchitecture::X86_64;
        case PROCESSOR_ARCHITECTURE_ARM64:
            return ProcessorArchitecture::ARM64;
        case PROCESSOR_ARCHITECTURE_INTEL:
            return ProcessorArchitecture::X86;
        case PROCESSOR_ARCHITECTURE_ARM:
            return ProcessorArchitecture::ARM32;
        default:
            return ProcessorArchitecture::UNKNOWN;
    }
#elif defined(__APPLE__)
    int ret = 0;
    size_t size = sizeof(ret);
    if (sysctlbyname("hw.optional.arm64", &ret, &size, nullptr, 0) == 0 && ret == 1) {
        return ProcessorArchitecture::ARM64;
    } else {
        return ProcessorArchitecture::X86_64;
    }
#else
    struct utsname systemInfo;
    if (uname(&systemInfo) == -1) {
        return ProcessorArchitecture::UNKNOWN;
    }

    std::string machine(systemInfo.machine);
    if (machine == "x86_64") {
        return ProcessorArchitecture::X86_64;
    } else if (machine.find("aarch64") != std::string::npos) {
        return ProcessorArchitecture::ARM64;
    } else if (machine.find("arm") != std::string::npos) {
        return ProcessorArchitecture::ARM32;
    } else if (machine.find("i686") != std::string::npos) {
        return ProcessorArchitecture::X86;
    }
    return ProcessorArchitecture::UNKNOWN;
#endif
}

bool PluginScanner::saveToPreset(const std::string& filePath) {
    return writeXMLPreset(filePath);
}

bool PluginScanner::loadFromPreset(const std::string& filePath) {
    return readXMLPreset(filePath);
}

bool PluginScanner::writeXMLPreset(const std::string& filePath) {
    pugi::xml_document doc;
    auto declNode = doc.append_child(pugi::node_declaration);
    declNode.append_attribute("version") = "1.0";
    declNode.append_attribute("encoding") = "UTF-8";

    auto root = doc.append_child("FutureboardPlugins");
    root.append_attribute("version") = "1.0";

    std::lock_guard<std::mutex> lock(pluginsMutex);
    for (const auto& plugin : discoveredPlugins) {
        auto pluginNode = root.append_child("Plugin");
        pluginNode.append_child("Name").text().set(plugin.name.c_str());
        pluginNode.append_child("Version").text().set(plugin.version.c_str());
        pluginNode.append_child("Path").text().set(plugin.path.c_str());
        pluginNode.append_child("Vendor").text().set(plugin.vendor.c_str());
        pluginNode.append_child("Architecture").text().set(architectureToString(plugin.arch).c_str());
        pluginNode.append_child("Format").text().set(formatToString(plugin.format).c_str());
        pluginNode.append_child("IsValid").text().set(plugin.isValid);

        if (!plugin.error.empty()) {
            pluginNode.append_child("Error").text().set(plugin.error.c_str());
        }

        if (!plugin.categories.empty()) {
            auto categoriesNode = pluginNode.append_child("Categories");
            for (const auto& category : plugin.categories) {
                categoriesNode.append_child("Category").text().set(category.c_str());
            }
        }

        if (!plugin.features.empty()) {
            auto featuresNode = pluginNode.append_child("Features");
            for (const auto& feature : plugin.features) {
                featuresNode.append_child("Feature").text().set(feature.c_str());
            }
        }

        pluginNode.append_child("IsSynth").text().set(plugin.isSynth);
        pluginNode.append_child("IsEffect").text().set(plugin.isEffect);
        pluginNode.append_child("AcceptsMidi").text().set(plugin.acceptsMidi);
        pluginNode.append_child("ProducesMidi").text().set(plugin.producesMidi);
        pluginNode.append_child("NumInputs").text().set(plugin.numInputChannels);
        pluginNode.append_child("NumOutputs").text().set(plugin.numOutputChannels);
    }

    return doc.save_file(filePath.c_str());
}

bool PluginScanner::readXMLPreset(const std::string& filePath) {
    pugi::xml_document doc;
    if (!doc.load_file(filePath.c_str())) return false;

    std::vector<PluginInfo> loadedPlugins;

    auto root = doc.child("FutureboardPlugins");
    for (auto pluginNode : root.children("Plugin")) {
        PluginInfo info;
        info.name = pluginNode.child("Name").text().get();
        info.version = pluginNode.child("Version").text().get();
        info.path = pluginNode.child("Path").text().get();
        info.vendor = pluginNode.child("Vendor").text().get();
        info.arch = stringToArchitecture(pluginNode.child("Architecture").text().get());
        info.format = stringToFormat(pluginNode.child("Format").text().get());
        info.isValid = pluginNode.child("IsValid").text().as_bool();

        if (auto errorNode = pluginNode.child("Error")) {
            info.error = errorNode.text().get();
        }

        if (auto categoriesNode = pluginNode.child("Categories")) {
            for (auto categoryNode : categoriesNode.children("Category")) {
                info.categories.push_back(categoryNode.text().get());
            }
        }

        if (auto featuresNode = pluginNode.child("Features")) {
            for (auto featureNode : featuresNode.children("Feature")) {
                info.features.push_back(featureNode.text().get());
            }
        }

        info.isSynth = pluginNode.child("IsSynth").text().as_bool();
        info.isEffect = pluginNode.child("IsEffect").text().as_bool();
        info.acceptsMidi = pluginNode.child("AcceptsMidi").text().as_bool();
        info.producesMidi = pluginNode.child("ProducesMidi").text().as_bool();
        info.numInputChannels = pluginNode.child("NumInputs").text().as_int();
        info.numOutputChannels = pluginNode.child("NumOutputs").text().as_int();

        loadedPlugins.push_back(info);
    }

    std::lock_guard<std::mutex> lock(pluginsMutex);
    discoveredPlugins = std::move(loadedPlugins);

    return true;
}

void PluginScanner::reportProgress(const std::string& message, float progress) {
    if (progressCallback) {
        progressCallback(message, progress);
    }
}

std::string PluginScanner::architectureToString(ProcessorArchitecture arch) {
    switch (arch) {
        case ProcessorArchitecture::X86_64: return "x86_64";
        case ProcessorArchitecture::X86: return "x86";
        case ProcessorArchitecture::ARM64: return "arm64";
        case ProcessorArchitecture::ARM32: return "arm32";
        default: return "unknown";
    }
}

ProcessorArchitecture PluginScanner::stringToArchitecture(const std::string& archStr) {
    if (archStr == "x86_64") return ProcessorArchitecture::X86_64;
    if (archStr == "x86") return ProcessorArchitecture::X86;
    if (archStr == "arm64") return ProcessorArchitecture::ARM64;
    if (archStr == "arm32") return ProcessorArchitecture::ARM32;
    return ProcessorArchitecture::UNKNOWN;
}

std::string PluginScanner::formatToString(PluginFormat format) {
    switch (format) {
        case PluginFormat::VST2: return "VST2";
        case PluginFormat::VST3: return "VST3";
        case PluginFormat::CLAP: return "CLAP";
        default: return "Unknown";
    }
}

PluginFormat PluginScanner::stringToFormat(const std::string& formatStr) {
    if (formatStr == "VST2") return PluginFormat::VST2;
    if (formatStr == "VST3") return PluginFormat::VST3;
    if (formatStr == "CLAP") return PluginFormat::CLAP;
    return PluginFormat::UNKNOWN;
}

const std::vector<PluginInfo>& PluginScanner::getPlugins() const {
    std::lock_guard<std::mutex> lock(pluginsMutex);
    return discoveredPlugins;
}

bool PluginScanner::isScanning() const {
    return scanning;
}

size_t PluginScanner::getTotalPluginsFound() const {
    std::lock_guard<std::mutex> lock(pluginsMutex);
    return discoveredPlugins.size();
}

} // namespace futureboard
