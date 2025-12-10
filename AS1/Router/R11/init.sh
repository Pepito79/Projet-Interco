#!/bin/sh

# 1. Activation du routage
sysctl -w net.ipv4.ip_forward=1

echo "--- Config R11 ---"

# --- eth0 : Vers R_FAI_1 ---
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 120.0.35.2/24 dev eth0

# --- eth2 : Vers R12 (Routeur DNS) ---
# Réseau 120.0.38.0/24. R11 est en .1
ip addr flush dev eth2
ip link set dev eth2 up
ip addr add 120.0.38.1/24 dev eth2

# --- eth1 : Vers Serveur Web 1 ---
# Réseau 120.0.37.0/24. R11 est la passerelle en .1
ip addr flush dev eth1
ip link set dev eth1 up
ip addr add 120.0.37.1/24 dev eth1

# Lancement de FRRouting
/usr/lib/frr/docker-start