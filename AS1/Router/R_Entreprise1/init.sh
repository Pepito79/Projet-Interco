#!/bin/sh

# 1. Activation du routage (Obligatoire)
sysctl -w net.ipv4.ip_forward=1

# --- eth0 : Vers R_FAI_1 ---
# Le lien est 120.0.34.0/24. Le FAI est en .1, donc on se met en .2
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 120.0.34.2/24 dev eth0

# --- eth0 : Côté LAN (Réseau Interne Entreprise) ---
# D'après le schéma, le réseau est 10.10.10.0/24
ip addr flush dev eth1
ip link set dev eth1 up
# On attribue l'IP .1 comme passerelle pour l'entreprise
ip addr add 10.10.10.1/24 dev eth1



# Lancement de FRRouting
/usr/lib/frr/docker-start