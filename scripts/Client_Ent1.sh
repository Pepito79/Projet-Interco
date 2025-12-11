#!/bin/bash
echo "Configuring Client_Ent1..."

# interface eth0 -> net_ent
docker exec --privileged Client_Ent1 ip link set up dev eth0

# Default Gateway -> R_Entreprise1 (10.10.10.1)
docker exec --privileged Client_Ent1 ip route del default || true
docker exec --privileged Client_Ent1 ip route add default via 10.10.10.1
