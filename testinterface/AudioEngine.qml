import QtQuick

QtObject {
    id: audioEngine

    // Properties
    property var audioApis: ["MME", "ASIO", "WASAPI"]
    property var devices: []
    property var outputDevices: []
    property string currentInput: ""
    property string currentOutput: ""
    property string deviceInfo: ""
    property string sampleRate: "44100 Hz"
    property string bufferInfo: "256 smp 5.8 ms"
    property string statusText: "Current Project: Untitled.ftbp / A = 440hz"
    property bool isAsioDevice: false
    property int currentApi: 0
    property int bufferSize: 256

    // Methods
    function setCurrentApi(index) {
        if (currentApi !== index) {
            currentApi = index
            isAsioDevice = (index === 1)  // ASIO is index 1
            loadDevices()
        }
    }

    function setBufferSize(size) {
        bufferSize = size
        bufferInfo = size + " smp " + (size/44100*1000).toFixed(1) + " ms"
    }

    function setCurrentInput(device) {
        if (currentInput !== device) {
            currentInput = device
            deviceInfo = isAsioDevice ? "ASIO: " + device : device
        }
    }

    function setCurrentOutput(device) {
        if (currentOutput !== device) {
            currentOutput = device
        }
    }

    function showAsioPanel() {
        console.log("ASIO Control Panel requested")
    }

    function loadDevices() {
        // This would be connected to your Python backend
        // For now using mock data
        const mockDevices = {
            0: ["Microphone", "Line In", "Speakers", "Headphones"], // MME
            1: ["ASIO4ALL", "Focusrite USB ASIO", "Native Instruments"], // ASIO
            2: ["Microphone Array", "Speakers (High Def Audio)", "WASAPI Output"] // WASAPI
        }
        
        devices = mockDevices[currentApi] || []
        if (currentApi === 1) {  // ASIO
            outputDevices = devices
        } else {
            outputDevices = devices.filter(d => d.includes("Output") || d.includes("Speakers"))
        }
    }

    // Initialize
    Component.onCompleted: {
        loadDevices()
    }
}
