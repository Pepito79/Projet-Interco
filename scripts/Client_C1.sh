#!/bin/sh
echo "--- Config Client C1 (VPN) ---"

# Tue les anciens processus Python qui bloquent le tunnel
docker exec -it Client_C1 pkill -9 python3
# Supprime l'interface tun0 si elle existe
docker exec -it Client_C1 ip link delete tun0

# 1. Configuration de base (On s'assure que l'interface est UP)
ip link set dev eth0 up

# 2. Route par défaut vers la Box C1 (192.168.2.1)
ip route del default 2>/dev/null || true
ip route add default via 192.168.2.1

# ---------------------------------------------------
# 3. LANCEMENT DU VPN
# ---------------------------------------------------
echo "🚀 Démarrage du VPN..."

# Adresse IP Publique du routeur R_Entreprise1
export VPN_SERVER_IP="120.0.34.2" 

# On se place dans le dossier contenant le code Python
cd /app

# Lancement du client VPN en arrière-plan
python3 vpn_client.py &

# Attente de la création de l'interface tun0
echo "⏳ Attente de tun0..."
while ! ip link show tun0 > /dev/null 2>&1; do sleep 1; done

# Config IP virtuelle du tunnel
ip addr add 10.0.0.2/24 dev tun0
ip link set tun0 up
ip link set tun0 mtu 1200

# 4. ROUTAGE VPN
# A. On force la connexion cryptée vers le serveur VPN à passer par la Box (Internet)
GW_PHYSIQUE="192.168.2.1"
ip route add $VPN_SERVER_IP via $GW_PHYSIQUE dev eth0

# B. On redirige tout le reste du trafic via le tunnel VPN
ip route del default
ip route add default via 10.0.0.1 dev tun0

# DNS Google
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Garder le conteneur actif
tail -f /dev/null