#include "performancemeter.hpp"
#include <QTimer>
#include <QDebug>

PerformanceMeter::PerformanceMeter() 
    : m_cpuUsage(0)
    , m_lastReadBytes(0)
    , m_lastWriteBytes(0)
    , m_totalRam(0)
{
    initPerfCounters();
    
    QTimer* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &PerformanceMeter::update);
    timer->start(1000); // Update every second
}

PerformanceMeter::~PerformanceMeter() {
    PdhCloseQuery(m_queryHandle);
}

PerformanceMeter& PerformanceMeter::instance() {
    static PerformanceMeter instance;
    return instance;
}

void PerformanceMeter::initPerfCounters() {
    PdhOpenQuery(NULL, 0, &m_queryHandle);
    PdhAddEnglishCounter(m_queryHandle, L"\\Processor(_Total)\\% Processor Time", 0, &m_cpuCounter);
    PdhCollectQueryData(m_queryHandle);
}

void PerformanceMeter::updateCPU() {
    PDH_FMT_COUNTERVALUE counterVal;
    
    PdhCollectQueryData(m_queryHandle);
    PdhGetFormattedCounterValue(m_cpuCounter, PDH_FMT_DOUBLE, NULL, &counterVal);
    m_cpuUsage = counterVal.doubleValue;
}

void PerformanceMeter::updateRAM() {
    MEMORYSTATUSEX memInfo;
    memInfo.dwLength = sizeof(MEMORYSTATUSEX);
    GlobalMemoryStatusEx(&memInfo);
    
    m_totalRam = memInfo.ullTotalPhys;
    qint64 usedRam = memInfo.ullTotalPhys - memInfo.ullAvailPhys;
    
    // Format as GB if > 1024 MB
    if (usedRam > 1024 * 1024 * 1024) {
        double gbUsed = usedRam / (1024.0 * 1024.0 * 1024.0);
        double gbTotal = m_totalRam / (1024.0 * 1024.0 * 1024.0);
        m_ramUsageStr = QString("%1/%2 GB").arg(gbUsed, 0, 'f', 1).arg(gbTotal, 0, 'f', 1);
    } else {
        double mbUsed = usedRam / (1024.0 * 1024.0);
        double mbTotal = m_totalRam / (1024.0 * 1024.0);
        m_ramUsageStr = QString("%1/%2 MB").arg(mbUsed, 0, 'f', 0).arg(mbTotal, 0, 'f', 0);
    }
}

void PerformanceMeter::updateDiskSpeed() {
    HANDLE hDevice = CreateFileW(L"\\\\.\\PhysicalDrive0", 
                               FILE_READ_ATTRIBUTES, 
                               FILE_SHARE_READ | FILE_SHARE_WRITE, 
                               NULL, 
                               OPEN_EXISTING, 
                               0, 
                               NULL);
    
    if (hDevice == INVALID_HANDLE_VALUE) {
        m_diskSpeedStr = "N/A";
        return;
    }

    DISK_PERFORMANCE diskPerf;
    DWORD bytesReturned;
    
    if (DeviceIoControl(hDevice, 
                       IOCTL_DISK_PERFORMANCE, 
                       NULL, 
                       0, 
                       &diskPerf, 
                       sizeof(diskPerf), 
                       &bytesReturned, 
                       NULL)) {
                           
        QDateTime now = QDateTime::currentDateTime();
        qint64 elapsed = m_lastCheck.msecsTo(now);
        
        if (elapsed > 0 && m_lastCheck.isValid()) {
            qint64 readDiff = diskPerf.BytesRead.QuadPart - m_lastReadBytes;
            qint64 writeDiff = diskPerf.BytesWritten.QuadPart - m_lastWriteBytes;
            
            qint64 readSpeed = (readDiff * 1000) / elapsed;
            qint64 writeSpeed = (writeDiff * 1000) / elapsed;
            
            m_diskSpeedStr = QString("R:%1/s W:%2/s")
                .arg(formatSpeed(readSpeed))
                .arg(formatSpeed(writeSpeed));
        }
        
        m_lastReadBytes = diskPerf.BytesRead.QuadPart;
        m_lastWriteBytes = diskPerf.BytesWritten.QuadPart;
        m_lastCheck = now;
    }
    
    CloseHandle(hDevice);
}

QString PerformanceMeter::formatSpeed(qint64 bytesPerSec) {
    const qint64 KB = 1024;
    const qint64 MB = KB * 1024;
    
    if (bytesPerSec >= MB) {
        return QString("%1MB").arg(bytesPerSec / MB);
    } else if (bytesPerSec >= KB) {
        return QString("%1KB").arg(bytesPerSec / KB);
    }
    return QString("%1B").arg(bytesPerSec);
}

void PerformanceMeter::update() {
    updateCPU();
    updateRAM();
    updateDiskSpeed(); // Changed from updateDisk() to updateDiskSpeed()
    emit metricsChanged();
}
