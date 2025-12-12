#!/bin/bash
echo "Configuring R_Entreprise1..."

# Activer les interfaces réseau
docker exec --privileged R_Entreprise1 ip link set up dev eth0  # net_34 (vers FAI)
docker exec --privileged R_Entreprise1 ip link set up dev eth1  # net_ent_lan (vers LAN employés)
docker exec --privileged R_Entreprise1 ip link set up dev eth2  # net_ent_dmz (vers DMZ)
