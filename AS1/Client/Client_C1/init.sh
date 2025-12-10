#!/bin/sh

# 1. Nettoyage et adressage IP (LAN)
ip addr flush dev eth0
ip link set dev eth0 up
# On lui donne l'adresse .10 dans le réseau 192.168.2.0
ip addr add 192.168.2.2/24 dev eth0

# 2. Route par défaut (Vers la Box C1)
# Tout ce qui n'est pas local est envoyé à 192.168.2.1
ip route add default via 192.168.2.1

# 3. Maintien du conteneur en vie
sleep infinity