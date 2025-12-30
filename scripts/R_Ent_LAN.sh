#!/bin/bash
echo "Configuring R_Ent_LAN..."

# Activer les interfaces
docker exec --privileged R_Ent_LAN ip link set up dev eth0  # vers R_Entreprise1
docker exec --privileged R_Ent_LAN ip link set up dev eth1  # vers LAN interne

# Installer dnsmasq si nécessaire
docker exec --privileged R_Ent_LAN apk add --no-cache dnsmasq

# Copier le fichier de config (si pas déjà dans le conteneur)
docker cp ./config/DHCP_Ent_LAN/dnsmasq.conf R_Ent_LAN:/etc/dnsmasq.conf

# Lancer dnsmasq en arrière-plan
docker exec --privileged R_Ent_LAN sh -c "dnsmasq -k -C /etc/dnsmasq.conf &"

echo "R_Ent_LAN configured."
