#!/bin/bash
echo "Configuring R_Entreprise1..."

# interface eth0 -> net_34
docker exec --privileged R_Entreprise1 ip addr flush dev eth0
docker exec --privileged R_Entreprise1 ip addr add 120.0.34.2/24 dev eth0
docker exec --privileged R_Entreprise1 ip link set up dev eth0

# interface eth1 -> net_ent
docker exec --privileged R_Entreprise1 ip addr flush dev eth1
docker exec --privileged R_Entreprise1 ip addr add 10.10.10.1/24 dev eth1
docker exec --privileged R_Entreprise1 ip link set up dev eth1
