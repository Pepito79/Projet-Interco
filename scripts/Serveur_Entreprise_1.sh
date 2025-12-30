#!/bin/sh
echo "--- Config Serveur Entreprise (VPN) ---"

# 1. Configuration de base
ip link set dev eth0 up

# 2. Route par défaut vers le Routeur Entreprise (10.10.10.1)
ip route del default 2>/dev/null || true
ip route add default via 10.10.10.1

# ---------------------------------------------------
# 3. LANCEMENT DU VPN
# ---------------------------------------------------
echo "🔥 Démarrage du Serveur VPN..."
cd /app

# Lancement du serveur VPN en arrière-plan
python3 vpn_server.py &

# Attente de tun0
echo "⏳ Attente de tun0..."
while ! ip link show tun0 > /dev/null 2>&1; do sleep 1; done

# Config IP virtuelle du tunnel
ip addr add 10.0.0.1/24 dev tun0
ip link set tun0 up
ip link set tun0 mtu 1200

# 4. NAT (Masquerade)
# Permet au client VPN (10.0.0.2) de parler aux autres machines (10.10.10.x)
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# Garder le conteneur actif
tail -f /dev/null

# interface eth0 -> net_dmz
#docker exec --privileged Serveur_Entreprise_1 ip link set up dev eth0

# Default Gateway -> R_DMZ (10.10.20.1)
#docker exec --privileged Serveur_Entreprise_1 ip route del default || true
#docker exec --privileged Serveur_Entreprise_1 ip route add default via 10.10.20.1
