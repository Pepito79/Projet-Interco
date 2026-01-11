#!/bin/sh
echo "--- Config Client C1 (VPN) ---"

# 1. Configuration IP de base (LAN)
ip addr flush dev eth0
ip link set dev eth0 down
ip addr add 192.168.2.10/24 dev eth0
ip link set dev eth0 up

# Route par défaut vers la Box
ip route add default via 192.168.2.1

# ---------------------------------------------------
# 2. LANCEMENT DU VPN
# ---------------------------------------------------
echo "🚀 Démarrage du VPN..."

# Adresse IP Publique du Routeur Entreprise (cible du tunnel)
export VPN_SERVER_IP="120.0.34.2" 

cd /app

# Lancement du script python en arrière-plan
python3 vpn_client.py &

# On attend que l'interface tun0 soit créée
echo "⏳ Attente de tun0..."
while ! ip link show tun0 > /dev/null 2>&1; do sleep 1; done

# Configuration de l'interface virtuelle
ip addr add 10.0.0.2/24 dev tun0
ip link set tun0 up
ip link set tun0 mtu 1200

# 3. ROUTAGE VPN
# A. On force la connexion chiffrée à passer par la vraie passerelle (Internet)
GW_PHYSIQUE="192.168.2.1"
ip route add $VPN_SERVER_IP via $GW_PHYSIQUE dev eth0

# B. On redirige tout le reste du trafic dans le tunnel VPN
ip route del default
ip route add default via 10.0.0.1 dev tun0

# DNS Google
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Maintien du conteneur en vie
tail -f /dev/null