#!/bin/bash
echo "Configuring DNS_Ent_1..."

# interface eth0 -> net_dmz
docker exec --privileged DNS_Ent_1 ip link set up dev eth0

# route par défaut -> R_DMZ (10.10.20.1)
docker exec --privileged DNS_Ent_1 ip route del default || true
docker exec --privileged DNS_Ent_1 ip route add default via 10.10.20.1


