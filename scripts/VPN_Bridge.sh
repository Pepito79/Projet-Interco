#!/bin/sh
echo "--- Config VPN Bridge ---"

# 1. Config Routeur Physique
# Le bridge est dans le LAN Entreprise (10.10.10.x). Gateway = 10.10.10.1
ip route del default || true
ip route add default via 10.10.10.1

# 2. Lancement du client VPN
# Il utilisera VPN_USERNAME/PASSWORD et VPN_SERVER_IP/TARGET_NET des env vars
cd /app
python3 -u vpn_client.py
