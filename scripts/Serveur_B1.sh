#!/bin/bash
echo "Configuring Serveur_B1..."

# interface eth0 -> net_b1
docker exec --privileged Serveur_B1 ip addr flush dev eth0
docker exec --privileged Serveur_B1 ip addr add 192.168.101.3/24 dev eth0
docker exec --privileged Serveur_B1 ip link set up dev eth0

# Default Gateway -> Box_B1 (192.168.101.1)
docker exec --privileged Serveur_B1 ip route del default || true
docker exec --privileged Serveur_B1 ip route add default via 192.168.101.1
