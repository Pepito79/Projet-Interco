#!/bin/sh

# 1. Activation du routage (Indispensable)
sysctl -w net.ipv4.ip_forward=1

# --- eth1 : vers R_FAI_1 ---
ip addr flush dev eth1
ip link set dev eth1 up
# Adresse de la Box sur le lien FAI (le FAI est en .1)
ip addr add 120.0.32.2/24 dev eth1

# --- eth0 : vers Client_B1 ---
ip addr flush dev eth0
ip link set dev eth0 up
# Adresse de la passerelle LAN
ip addr add 192.168.101.1/24 dev eth0

# Lancement de FRRouting
/usr/lib/frr/docker-start