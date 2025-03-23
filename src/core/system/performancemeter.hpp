#ifndef PERFORMANCEMETER_HPP
#define PERFORMANCEMETER_HPP

#include <QObject>
#include <QDateTime>
#include <windows.h>
#include <pdh.h>
#include <psapi.h>

class PerformanceMeter : public QObject {
    Q_OBJECT
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY metricsChanged)
    Q_PROPERTY(QString ramUsage READ ramUsage NOTIFY metricsChanged)
    Q_PROPERTY(QString diskSpeed READ diskSpeed NOTIFY metricsChanged)
    Q_PROPERTY(qint64 totalRam READ totalRam CONSTANT)

public:
    static PerformanceMeter& instance();
    
    double cpuUsage() const { return m_cpuUsage; }
    QString ramUsage() const { return m_ramUsageStr; }
    QString diskSpeed() const { return m_diskSpeedStr; }
    qint64 totalRam() const { return m_totalRam; }

public slots:
    void update();

signals:
    void metricsChanged();

private:
    PerformanceMeter();
    ~PerformanceMeter();

    PDH_HQUERY m_queryHandle;
    PDH_HCOUNTER m_cpuCounter;
    
    double m_cpuUsage;
    QString m_ramUsageStr;
    QString m_diskSpeedStr;
    qint64 m_totalRam;
    qint64 m_lastReadBytes;
    qint64 m_lastWriteBytes;
    QDateTime m_lastCheck;

    void initPerfCounters();
    void updateCPU();
    void updateRAM();
    void updateDiskSpeed();
    QString formatBytes(qint64 bytes);
    QString formatSpeed(qint64 bytesPerSec);
};

#endif // PERFORMANCEMETER_HPP
