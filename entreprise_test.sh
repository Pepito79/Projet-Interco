#!/bin/bash

echo "--- Nettoyage et Configuration du Routage ---"

# --- CONFIGURATION R_Entreprise1 ---
echo "[1/3] Configuration de R_Entreprise1..."
# Nettoyage total des interfaces pour éviter les conflits
docker exec --privileged R_Entreprise1 ip addr flush dev eth1
docker exec --privileged R_Entreprise1 ip addr flush dev eth2
# Réassignation propre
docker exec --privileged R_Entreprise1 ip addr add 10.10.1.1/29 dev eth1
docker exec --privileged R_Entreprise1 ip addr add 10.10.2.1/29 dev eth2
# Activation du forwarding
docker exec --privileged R_Entreprise1 sysctl -w net.ipv4.ip_forward=1
# Ajout des routes vers les réseaux finaux
docker exec R_Entreprise1 ip route add 10.10.10.0/24 via 10.10.1.2 dev eth1 2>/dev/null
docker exec R_Entreprise1 ip route add 10.10.20.0/24 via 10.10.2.2 dev eth2 2>/dev/null

# --- CONFIGURATION R_Ent_LAN ---
echo "[2/3] Configuration de R_Ent_LAN..."
docker exec --privileged R_Ent_LAN sysctl -w net.ipv4.ip_forward=1
# Route par défaut pour que le LAN puisse sortir vers Internet via R_Entreprise1
docker exec R_Ent_LAN ip route add default via 10.10.1.1 2>/dev/null

# --- CONFIGURATION R_Ent_DMZ ---
echo "[3/3] Configuration de R_Ent_DMZ..."
docker exec --privileged R_Ent_DMZ sysctl -w net.ipv4.ip_forward=1
# Route par défaut pour que la DMZ puisse répondre
docker exec R_Ent_DMZ ip route add default via 10.10.2.1 2>/dev/null

echo "--- Configuration terminée ! ---"
echo "Test du ping R_Entreprise1 -> Client_Ent1 (10.10.10.2) :"
docker exec R_Entreprise1 ping -c 2 10.10.10.2