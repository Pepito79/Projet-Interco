#!/bin/sh

# 1. Activation du forwarding (Base du routeur)
sysctl -w net.ipv4.ip_forward=1

echo "--- Configuration des IPs pour R_FAI_1 ---"

# --- eth0 : Vers Box B1 (Clients Particuliers 1) ---
ip addr flush dev eth0
ip link set dev eth0 down
ip addr add 120.0.32.1/24 dev eth0
ip link set dev eth0 up

# --- eth1 : Vers Box C1 (Clients Particuliers 2) ---
ip addr flush dev eth1
ip link set dev eth1 down
ip addr add 120.0.33.1/24 dev eth1
ip link set dev eth1 up

# --- eth2 : Vers R_Entreprise1 ---
ip addr flush dev eth2
ip link set dev eth2 down
ip addr add 120.0.34.1/24 dev eth2
ip link set dev eth2 up

# --- eth3 : Vers R11 (Services DNS/Web) ---
ip addr flush dev eth3
ip link set dev eth3 down
ip addr add 120.0.35.1/24 dev eth3
ip link set dev eth3 up

# --- eth4 : Vers R_bordure_1 (Sortie vers AS2) ---
# On utilise le subnet 120.0.39.0/24
ip addr flush dev eth4
ip link set dev eth4 down
ip addr add 120.0.39.1/24 dev eth4
ip link set dev eth4 up

# Vérification
ip addr show

echo "--- Lancement de FRRouting ---"
/usr/lib/frr/docker-start