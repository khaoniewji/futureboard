#ifndef WINDOWSDEVICES_HPP
#define WINDOWSDEVICES_HPP

#include <vector>
#include <string>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <comdef.h>
#include <QString>

class WindowsDevices {
public:
    WindowsDevices();
    ~WindowsDevices();

    void initialDevices(); // Method to initialize devices
    std::vector<QString> getDeviceList() const; // Method to get the list of devices

private:
    std::vector<QString> deviceList; // Store device names
    void listAudioDevices(); // Private method to scan audio devices
};

#endif // WINDOWSDEVICES_HPP
