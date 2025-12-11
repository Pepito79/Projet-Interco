#!/bin/bash
echo "Configuring Serveur_Web1..."

# interface eth0 -> net_37
docker exec --privileged Serveur_Web1 ip link set up dev eth0

# Default Gateway -> R11 (120.0.37.1)
docker exec --privileged Serveur_Web1 ip route del default || true
docker exec --privileged Serveur_Web1 ip route add default via 120.0.37.1
