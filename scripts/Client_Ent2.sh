#!/bin/bash
echo "🚀 Configuration de Client_Ent2 (Entreprise 1) via DHCP..."

# 1. Activer l'interface eth0
docker exec --privileged Client_Ent2 ip link set up dev eth0
sleep 1

# 2. On utilise udhcpc (déjà présent sur Alpine) pour obtenir l'IP du serveur DHCP_Ent_LAN
# On ajoute -n pour ne pas bloquer si le serveur ne répond pas
docker exec --privileged Client_Ent2 udhcpc -i eth0 -n -q

# 3. Vérifier l'adresse IP attribuée (devrait être en 10.10.10.x)
echo "📍 IP attribuée à Client_Ent2 :"
docker exec Client_Ent2 ip -4 addr show eth0 | grep inet