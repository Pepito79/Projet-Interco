#!/bin/bash
echo "Configuring R_Entreprise1..."

# interface eth0 -> net_34
docker exec --privileged R_Entreprise1 ip link set up dev eth0

# interface eth1 -> net_ent
docker exec --privileged R_Entreprise1 ip link set up dev eth1
