#!/bin/bash
echo "Configuring Client_Ent1..."

# interface eth0 -> net_lan
docker exec --privileged Client_Ent1 ip link set up dev eth0

# Default Gateway -> R_LAN (10.10.10.254)
docker exec --privileged Client_Ent1 ip route del default || true
docker exec --privileged Client_Ent1 ip route add default via 10.10.10.1

# Définir le serveur DNS interne
docker exec --privileged Client_Ent1 sh -c "echo 'nameserver 10.10.20.3' > /etc/resolv.conf"
