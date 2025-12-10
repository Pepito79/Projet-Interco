#!/bin/sh

# 1. Activation du routage
sysctl -w net.ipv4.ip_forward=1

# --- eth0 : Vers R_FAI_1 ---
ip addr flush dev eth0
ip link set dev eth0 up
# On met l'adresse .2 (le FAI est .1)
ip addr add 120.0.33.2/24 dev eth0

# --- eth1 : vers Client_C1 ---
ip addr flush dev eth1
ip link set dev eth1 up
ip addr add 192.168.2.1/24 dev eth1

# Lancement de FRRouting
/usr/lib/frr/docker-start