#!/bin/bash
echo "Configuring R_Entreprise_LAN..."

# interface eth0 -> net_ent_lan (vers R_Entreprise1)
docker exec --privileged R_Entreprise_LAN ip link set up dev eth0

# interface eth1 -> net_lan (vers LAN interne des employés)
docker exec --privileged R_Entreprise_LAN ip link set up dev eth1
