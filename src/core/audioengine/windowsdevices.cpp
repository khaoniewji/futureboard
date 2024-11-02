#include "windowsdevices.hpp"
#include <iostream>
#include <stdexcept>
#include <propkey.h> // Include this header for property keys

WindowsDevices::WindowsDevices() {
    CoInitialize(nullptr); // Initialize the COM library
}

WindowsDevices::~WindowsDevices() {
    CoUninitialize(); // Clean up the COM library
}

void WindowsDevices::listAudioDevices() {
    HRESULT hr;
    IMMDeviceEnumerator* deviceEnumerator = nullptr;
    IMMDeviceCollection* deviceCollection = nullptr;
    IMMDevice* device = nullptr;
    IPropertyStore* propertyStore = nullptr;

    hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator), (void**)&deviceEnumerator);
    if (FAILED(hr)) {
        throw std::runtime_error("Failed to create device enumerator.");
    }

    hr = deviceEnumerator->EnumAudioEndpoints(eAll, DEVICE_STATE_ACTIVE, &deviceCollection);
    if (FAILED(hr)) {
        deviceEnumerator->Release();
        throw std::runtime_error("Failed to get audio endpoint collection.");
    }

    UINT deviceCount;
    hr = deviceCollection->GetCount(&deviceCount);
    if (FAILED(hr)) {
        deviceCollection->Release();
        deviceEnumerator->Release();
        throw std::runtime_error("Failed to get device count.");
    }

    for (UINT i = 0; i < deviceCount; ++i) {
        hr = deviceCollection->Item(i, &device);
        if (SUCCEEDED(hr)) {
            hr = device->OpenPropertyStore(GENERIC_READ, &propertyStore);
            if (SUCCEEDED(hr)) {
                PROPVARIANT name;
                PropVariantInit(&name);
                hr = propertyStore->GetValue(PKEY_Devices_FriendlyName, &name);
                if (SUCCEEDED(hr)) {
                    deviceList.push_back(_com_util::ConvertBSTRToString(name.bstrVal));
                    PropVariantClear(&name);
                }
                propertyStore->Release();
            }
            device->Release();
        }
    }

    deviceCollection->Release();
    deviceEnumerator->Release();
}

void WindowsDevices::initialDevices() {
    try {
        listAudioDevices();
        for (const auto& device : deviceList) {
            std::cout << "Found audio device: " << device.toStdString() << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error initializing devices: " << e.what() << std::endl;
    }
}

std::vector<QString> WindowsDevices::getDeviceList() const {
    return deviceList; // Return the list of devices
}
