#!/bin/sh
echo "--- Config R_Bordure_1 ---"
apk add iptables iproute2
sysctl -w net.ipv4.ip_forward=1

# Nettoyage préventif
ip addr flush dev eth0
ip addr flush dev eth1

# Adresses IP
ip addr add 120.0.39.3/24 dev eth0
ip addr add 120.0.40.1/24 dev eth1

# ROUTAGE
# 1. Vers Internet (AS1) : On remonte tout vers R_FAI_1
ip route add default via 120.0.39.1

# 2. Vers AS2 (Le réseau du FAI 2 et ce qu'il y a derrière)
# Pour atteindre le LAN AS2 (20.20.20.0/24), on passe par FAI 2
ip route add 20.20.20.0/24 via 120.0.40.2

/usr/lib/frr/docker-start