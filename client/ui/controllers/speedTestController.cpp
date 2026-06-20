#include "speedTestController.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QElapsedTimer>
#include <QByteArray>
#include <QSharedPointer>
#include <QString>
#include <QTimer>
#include <QUrl>

namespace
{
constexpr qint64 kDownloadBytes = 20 * 1000 * 1000; // 20 MB
constexpr int kUploadBytes = 8 * 1000 * 1000;       // 8 MB
constexpr int kTimeoutMs = 25000;
} // namespace

SpeedTestController::SpeedTestController(QObject* parent)
    : QObject(parent), m_nam(new QNetworkAccessManager(this))
{
}

void SpeedTestController::setState(int s)
{
    if (m_state != s) {
        m_state = s;
        emit stateChanged();
    }
}

void SpeedTestController::setProgress(int p)
{
    if (p < 0) p = 0;
    if (p > 100) p = 100;
    if (m_progress != p) {
        m_progress = p;
        emit progressChanged();
    }
}

void SpeedTestController::runTest()
{
    if (m_state == 1 || m_state == 2) {
        return; // already running
    }
    m_downloadMbps = 0;
    m_uploadMbps = 0;
    emit resultChanged();
    setProgress(0);
    startDownload();
}

void SpeedTestController::startDownload()
{
    setState(1);
    setProgress(0);

    QUrl url(QStringLiteral("https://speed.cloudflare.com/__down?bytes=%1").arg(kDownloadBytes));
    QNetworkRequest req(url);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply* reply = m_nam->get(req);

    auto timer = QSharedPointer<QElapsedTimer>::create();
    auto started = QSharedPointer<bool>::create(false);
    auto firstBytes = QSharedPointer<qint64>::create(0);
    auto lastBytes = QSharedPointer<qint64>::create(0);

    connect(reply, &QNetworkReply::downloadProgress, this, [this, timer, started, firstBytes, lastBytes](qint64 received, qint64 total) {
        *lastBytes = received;
        if (!*started && received > 0) {
            *started = true;
            *firstBytes = received;
            timer->start();
        }
        if (total > 0) {
            setProgress(static_cast<int>(received * 100 / total));
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, timer, started, firstBytes, lastBytes]() {
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
        if (ok && *started) {
            const double secs = timer->elapsed() / 1000.0;
            const qint64 bytes = *lastBytes - *firstBytes;
            if (secs > 0.05 && bytes > 0) {
                m_downloadMbps = (bytes * 8.0) / secs / 1.0e6;
            }
        }
        if (!ok) {
            setState(4);
            emit resultChanged();
            return;
        }
        emit resultChanged();
        startUpload();
    });

    QTimer::singleShot(kTimeoutMs, reply, [reply]() {
        if (reply->isRunning()) {
            reply->abort();
        }
    });
}

void SpeedTestController::startUpload()
{
    setState(2);
    setProgress(0);

    QByteArray payload(kUploadBytes, '\0');
    QUrl url(QStringLiteral("https://speed.cloudflare.com/__up"));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
    QNetworkReply* reply = m_nam->post(req, payload);

    auto timer = QSharedPointer<QElapsedTimer>::create();
    auto started = QSharedPointer<bool>::create(false);
    auto firstBytes = QSharedPointer<qint64>::create(0);
    auto lastBytes = QSharedPointer<qint64>::create(0);

    connect(reply, &QNetworkReply::uploadProgress, this, [this, timer, started, firstBytes, lastBytes](qint64 sent, qint64 total) {
        *lastBytes = sent;
        if (!*started && sent > 0) {
            *started = true;
            *firstBytes = sent;
            timer->start();
        }
        if (total > 0) {
            setProgress(static_cast<int>(sent * 100 / total));
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, timer, started, firstBytes, lastBytes]() {
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
        if (ok && *started) {
            const double secs = timer->elapsed() / 1000.0;
            const qint64 bytes = *lastBytes - *firstBytes;
            if (secs > 0.05 && bytes > 0) {
                m_uploadMbps = (bytes * 8.0) / secs / 1.0e6;
            }
        }
        setState(ok ? 3 : 4);
        setProgress(100);
        emit resultChanged();
    });

    QTimer::singleShot(kTimeoutMs, reply, [reply]() {
        if (reply->isRunning()) {
            reply->abort();
        }
    });
}