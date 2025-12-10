#!/bin/sh

# 1. Nettoyage et adressage IP (LAN)
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 192.168.1.2/24 dev eth0

# 2. Route par défaut (Vers la Box B1)
ip route add default via 192.168.1.1

# 3. Maintien du conteneur en vie
sleep infinity