#!/bin/bash
echo "Configuring R_DMZ..."

# interface eth0 -> net_ent_dmz (vers R_Entreprise1)
docker exec --privileged R_Ent_DMZ ip link set up dev eth0

# interface eth1 -> net_dmz (vers DMZ interne)
docker exec --privileged R_Ent_DMZ ip link set up dev eth1
