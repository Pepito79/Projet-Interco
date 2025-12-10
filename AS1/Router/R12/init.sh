#!/bin/sh

# 1. Activation du routage
sysctl -w net.ipv4.ip_forward=1

# --- eth2 : Vers R11 ---
# Réseau 120.0.38.0/24. R11 est .1, donc R12 est .2
ip addr flush dev eth2
ip link set dev eth2 up
ip addr add 120.0.38.2/24 dev eth2

# --- eth1 : Vers Serveur DNS ---
# Réseau 120.0.36.0/24. R12 est la passerelle .1
ip addr flush dev eth1
ip link set dev eth1 up
ip addr add 120.0.36.1/24 dev eth1

# --- eth0 : Vers R_FAI_1
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 120.0.39.2/24 dev eth0



# Lancement de FRRouting
/usr/lib/frr/docker-start