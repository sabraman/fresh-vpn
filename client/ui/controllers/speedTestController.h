#ifndef SPEEDTESTCONTROLLER_H
#define SPEEDTESTCONTROLLER_H

#include <QObject>

class QNetworkAccessManager;

// Speed test via public Cloudflare endpoints (speed.cloudflare.com).
// Measures real throughput through the active tunnel. No API key, INTL contour.
class SpeedTestController : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(double downloadMbps READ downloadMbps NOTIFY resultChanged)
    Q_PROPERTY(double uploadMbps READ uploadMbps NOTIFY resultChanged)
    Q_PROPERTY(int state READ state NOTIFY stateChanged)       // 0 idle, 1 download, 2 upload, 3 done, 4 error
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged) // 0..100 within current phase

    explicit SpeedTestController(QObject* parent = nullptr);

    double downloadMbps() const { return m_downloadMbps; }
    double uploadMbps() const { return m_uploadMbps; }
    int state() const { return m_state; }
    int progress() const { return m_progress; }

public slots:
    void runTest();

signals:
    void resultChanged();
    void stateChanged();
    void progressChanged();

private:
    void startDownload();
    void startUpload();
    void setState(int s);
    void setProgress(int p);

    QNetworkAccessManager* m_nam;
    double m_downloadMbps = 0;
    double m_uploadMbps = 0;
    int m_state = 0;
    int m_progress = 0;
};

#endif // SPEEDTESTCONTROLLER_H