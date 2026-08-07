#include "ipSplitTunnelingController.h"
#include "core/utils/networkUtilities.h"
#include <QJsonObject>

namespace {
// Bump on every change to russianDirectSites() so existing installs pick it up.
// 1 = the original list, seeded by the old boolean flag.
constexpr int kRuDirectSeedVersion = 2;
}

IpSplitTunnelingController::IpSplitTunnelingController(SecureAppSettingsRepository* appSettingsRepository, QObject* parent)
    : QObject(parent),
      m_appSettingsRepository(appSettingsRepository)
{
    m_currentRouteMode = m_appSettingsRepository->routeMode();

    // #4 Fresh: route Russian services directly (outside VPN), like the Happ subscription.
    //
    // This used to latch on a plain bool, so an edit to russianDirectSites() only
    // ever reached installs that had never launched: two machines of different
    // vintages held different lists off the same source file. Seeding by version
    // lets a list revision land on existing installs too.
    const int seededVersion = m_appSettingsRepository->ruDirectSeedVersion();
    if (seededVersion < kRuDirectSeedVersion) {
        const bool neverSeeded = (seededVersion == 0 && !m_appSettingsRepository->isRuDirectSeedDone());
        if (neverSeeded) {
            // First launch: our defaults apply in full.
            applyRussianDirectPreset();
            m_appSettingsRepository->setRuDirectSeedDone(true);
            m_appSettingsRepository->setRuDirectSeedVersion(kRuDirectSeedVersion);
        } else if (m_currentRouteMode == RouteMode::VpnAllExceptSites) {
            // Upgrade: add what is new, touch nothing the user owns.
            topUpRussianDirectSites();
            m_appSettingsRepository->setRuDirectSeedVersion(kRuDirectSeedVersion);
        }
        // Any other route mode: the list is dormant there, and addSite() writes into
        // whichever mode is current - topping up now would file these hosts under the
        // wrong mode and route them THROUGH the VPN instead of around it. Leave the
        // version unrecorded so the top-up still happens if they switch back.
        m_currentRouteMode = m_appSettingsRepository->routeMode();
    }

    if (m_currentRouteMode == RouteMode::VpnAllSites) { // for old split tunneling configs
        m_appSettingsRepository->setRouteMode(RouteMode::VpnOnlyForwardSites);
        m_currentRouteMode = RouteMode::VpnOnlyForwardSites;
    }
    fillSites();
}

void IpSplitTunnelingController::topUpRussianDirectSites()
{
    // Only ever called while m_currentRouteMode is VpnAllExceptSites, so addSite()
    // - and the async resolver callback it starts - files these under the mode they
    // belong to. addSiteInternal() already skips hosts that are present, so this is
    // an add-only pass: user-added sites and user preferences survive untouched.
    const QStringList sites = russianDirectSites();
    for (const QString &site : sites) {
        addSite(site);
    }
}

void IpSplitTunnelingController::applyRussianDirectPreset()
{
    // Route everything through the VPN EXCEPT these Russian services (they go direct
    // via the local/RU connection) so banking, gov and RU services are not geo-blocked.
    setRouteMode(RouteMode::VpnAllExceptSites);
    const QStringList sites = russianDirectSites();
    for (const QString &site : sites) {
        addSite(site);
    }
    m_appSettingsRepository->setSitesSplitTunnelingEnabled(true);
}

QStringList IpSplitTunnelingController::russianDirectSites()
{
    return QStringList {
        // Banks & payments
        "sberbank.ru", "online.sberbank.ru", "sberbank.com", "tbank.ru", "tinkoff.ru",
        "alfabank.ru", "alfabank.com", "vtb.ru", "gazprombank.ru", "raiffeisen.ru",
        "open.ru", "psbank.ru", "sovcombank.ru", "rshb.ru", "mkb.ru", "pochtabank.ru",
        "yoomoney.ru", "nspk.ru", "mironline.ru", "cbr.ru", "qiwi.com",
        // Government services
        "gosuslugi.ru", "nalog.ru", "nalog.gov.ru", "mos.ru", "pfr.gov.ru", "sfr.gov.ru",
        "fss.ru", "government.ru", "kremlin.ru", "mvd.ru", "gibdd.ru", "rosreestr.ru",
        "rosreestr.gov.ru", "fedsfm.ru",
        // Marketplaces & retail
        "ozon.ru", "www.ozon.ru", "ozone.ru", "cdn1.ozone.ru", "cdn2.ozone.ru", "xapi.ozon.ru", "api.ozon.ru", "ozon.travel", "wildberries.ru", "www.wildberries.ru", "wb.ru", "wbbasket.ru", "basket-01.wbbasket.ru", "avito.ru", "www.avito.ru", "avito.st", "market.yandex.ru",
        "megamarket.ru", "sbermegamarket.ru", "dns-shop.ru", "mvideo.ru", "citilink.ru",
        "eldorado.ru", "lamoda.ru", "aliexpress.ru", "leroymerlin.ru", "vseinstrumenti.ru",
        "petrovich.ru",
        // Media, streaming & social
        "vk.com", "vk.ru", "vkvideo.ru", "ok.ru", "dzen.ru", "kinopoisk.ru", "rutube.ru",
        "smotrim.ru", "premier.one", "ivi.ru", "okko.tv", "wink.ru", "more.tv", "start.ru",
        "kion.ru", "music.yandex.ru", "zvuk.com",
        // Yandex, mail & portals
        "yandex.ru", "ya.ru", "disk.yandex.ru", "mail.yandex.ru", "taxi.yandex.ru",
        "mail.ru", "list.ru", "bk.ru", "inbox.ru", "rambler.ru",
        // Telecom
        "mts.ru", "beeline.ru", "megafon.ru", "tele2.ru", "rt.ru",
        // Travel
        "rzd.ru", "aeroflot.ru", "pobeda.aero", "s7.ru", "tutu.ru", "aviasales.ru",
        // Misc
        "hh.ru", "2gis.ru", "gismeteo.ru", "drom.ru", "pochta.ru", "cdek.ru"
    };
}

bool IpSplitTunnelingController::addSiteInternal(const QString &hostname, const QString &ip)
{
    QVariantMap existing = m_appSettingsRepository->vpnSites(m_currentRouteMode);
    if (existing.contains(hostname) && ip.isEmpty()) {
        return false;
    }

    for (int i = 0; i < m_sites.size(); i++) {
        if (m_sites[i].first == hostname && (m_sites[i].second.isEmpty() && !ip.isEmpty())) {
            m_sites[i].second = ip;
            m_appSettingsRepository->addVpnSite(m_currentRouteMode, hostname, ip);
            return true;
        } else if (m_sites[i].first == hostname && (m_sites[i].second == ip)) {
            return false;
        }
    }
    m_sites.append(qMakePair(hostname, ip));
    m_appSettingsRepository->addVpnSite(m_currentRouteMode, hostname, ip);
    return true;
}

void IpSplitTunnelingController::addSites(const QMap<QString, QString> &sites, bool replaceExisting)
{
    if (replaceExisting) {
        m_sites.clear();
    }
    for (auto it = sites.constBegin(); it != sites.constEnd(); ++it) {
        const QString &hostname = it.key();
        const QString &ip = it.value();
        bool found = false;
        for (int i = 0; i < m_sites.size(); i++) {
            if (m_sites[i].first == hostname) {
                if (!ip.isEmpty()) {
                    m_sites[i].second = ip;
                }
                found = true;
                break;
            }
        }
        if (!found) {
            m_sites.append(qMakePair(hostname, ip));
        }
    }
    if (replaceExisting) {
        m_appSettingsRepository->removeAllVpnSites(m_currentRouteMode);
    }
    m_appSettingsRepository->addVpnSites(m_currentRouteMode, sites);
}

bool IpSplitTunnelingController::addSite(const QString &hostname)
{
    QString normalizedHostname = normalizeHostname(hostname);
    
    if (!validateHostname(normalizedHostname)) {
        return false;
    }
    
    if (NetworkUtilities::ipAddressWithSubnetRegExp().exactMatch(normalizedHostname)) {
        processSite(normalizedHostname, "");
        return true;
    }
    
    if (addSiteInternal(normalizedHostname, "")) {
        QHostInfo::lookupHost(normalizedHostname, this, SLOT(onHostResolved(QHostInfo)));
        return true;
    }
    
    return false;
}

bool IpSplitTunnelingController::removeSite(const QString &hostname)
{
    for (int i = 0; i < m_sites.size(); i++) {
        if (m_sites[i].first == hostname) {
            m_sites.removeAt(i);
            m_appSettingsRepository->removeVpnSite(m_currentRouteMode, hostname);
            return true;
        }
    }
    return false;
}

void IpSplitTunnelingController::removeSites()
{
    m_sites.clear();
    m_appSettingsRepository->removeAllVpnSites(m_currentRouteMode);
}

void IpSplitTunnelingController::setRouteMode(RouteMode routeMode)
{
    m_currentRouteMode = routeMode;
    fillSites();
    m_appSettingsRepository->setRouteMode(routeMode);
}

void IpSplitTunnelingController::toggleSplitTunneling(bool enabled)
{
    m_appSettingsRepository->setSitesSplitTunnelingEnabled(enabled);
}

RouteMode IpSplitTunnelingController::getRouteMode() const
{
    return m_currentRouteMode;
}

bool IpSplitTunnelingController::isSplitTunnelingEnabled() const
{
    return m_appSettingsRepository->isSitesSplitTunnelingEnabled();
}

QVector<QPair<QString, QString>> IpSplitTunnelingController::getCurrentSites() const
{
    return m_sites;
}

void IpSplitTunnelingController::fillSites()
{
    QVariantMap sitesMap = m_appSettingsRepository->vpnSites(m_currentRouteMode);
    m_sites.clear();
    for (auto it = sitesMap.begin(); it != sitesMap.end(); ++it) {
        m_sites.append(qMakePair(it.key(), it.value().toString()));
    }
}

QString IpSplitTunnelingController::normalizeHostname(const QString &hostname) const
{
    QString normalized = hostname;
    normalized.replace("https://", "");
    normalized.replace("http://", "");
    normalized.replace("ftp://", "");
    normalized = normalized.split("/", Qt::SkipEmptyParts).first();
    return normalized;
}

bool IpSplitTunnelingController::validateHostname(const QString &hostname) const
{
    if (hostname.isEmpty()) {
        return false;
    }
    if (!hostname.contains(".") && !NetworkUtilities::ipAddressWithSubnetRegExp().exactMatch(hostname)) {
        return false;
    }
    return true;
}


void IpSplitTunnelingController::onHostResolved(const QHostInfo &hostInfo)
{
    const QList<QHostAddress> &addresses = hostInfo.addresses();
    QString hostname = hostInfo.hostName();
    
    for (const QHostAddress &addr : addresses) {
        if (addr.protocol() == QAbstractSocket::NetworkLayerProtocol::IPv4Protocol) {
            processSiteAfterResolve(hostname, addr.toString());
            break;
        }
    }
}

void IpSplitTunnelingController::processSiteAfterResolve(const QString &hostname, const QString &ip)
{
    for (int i = 0; i < m_sites.size(); i++) {
        if (m_sites[i].first == hostname && m_sites[i].second.isEmpty()) {
            m_sites[i].second = ip;
            m_appSettingsRepository->addVpnSite(m_currentRouteMode, hostname, ip);
            break;
        }
    }
}

void IpSplitTunnelingController::processSite(const QString &hostname, const QString &ip)
{
    addSiteInternal(hostname, ip);
}

bool IpSplitTunnelingController::importSitesFromJson(const QByteArray& jsonData, bool replaceExisting, QString &errorMessage)
{
    QJsonParseError parseError;
    QJsonDocument jsonDocument = QJsonDocument::fromJson(jsonData, &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        errorMessage = tr("Failed to parse JSON data: %1").arg(parseError.errorString());
        return false;
    }
    
    if (!jsonDocument.isArray()) {
        errorMessage = tr("The JSON data is not an array");
        return false;
    }
    
    QJsonArray jsonArray = jsonDocument.array();
    QMap<QString, QString> sites;
    
    for (auto jsonValue : jsonArray) {
        QJsonObject jsonObject = jsonValue.toObject();
        QString hostname = jsonObject.value("hostname").toString("");
        QString ip = jsonObject.value("ip").toString("");
        
        QString normalizedHostname = normalizeHostname(hostname);
        
        if (!validateHostname(normalizedHostname)) {
            qDebug() << normalizedHostname << " not look like ip adress or domain name";
            continue;
        }
        
        sites.insert(normalizedHostname, ip);
    }
    
    addSites(sites, replaceExisting);
    
    return true;
}

QByteArray IpSplitTunnelingController::exportSitesToJson() const
{
    QVector<QPair<QString, QString>> sites = getCurrentSites();
    QJsonArray jsonArray;
    
    for (const auto &site : sites) {
        QJsonObject jsonObject;
        jsonObject["hostname"] = site.first;
        jsonObject["ip"] = site.second;
        jsonArray.append(jsonObject);
    }
    
    QJsonDocument jsonDocument(jsonArray);
    return jsonDocument.toJson();
}

