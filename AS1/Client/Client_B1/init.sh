#!/bin/sh

echo "--- Config Client B1 ---"

# 1. Nettoyage et adressage IP (LAN)
# On donne l'adresse .10 dans le réseau 192.168.1.0
ip addr flush dev eth0
ip link set dev eth0 down
ip addr add 192.168.1.10/24 dev eth0
ip link set dev eth0 up

# 2. Route par défaut (Vers la Box B1)
ip route add default via 192.168.1.1

# 3. Maintien du conteneur en vie
sleep infinity