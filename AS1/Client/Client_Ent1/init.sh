#!/bin/sh

# 1. Configuration IP (10.10.10.4)
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 10.10.10.3/24 dev eth0

# 2. Route par défaut vers le routeur d'entreprise
ip route add default via 10.10.10.1

# 3. Boucle infinie pour garder le conteneur actif
sleep infinity