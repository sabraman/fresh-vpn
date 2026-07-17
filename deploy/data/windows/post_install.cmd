sc stop AmneziaWGTunnel$AmneziaVPN
sc delete AmneziaWGTunnel$AmneziaVPN
taskkill /IM "FreshVPN-service.exe" /F
taskkill /IM "FreshVPN.exe" /F
exit /b 0
