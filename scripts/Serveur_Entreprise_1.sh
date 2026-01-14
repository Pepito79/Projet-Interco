#!/bin/bash
echo "Configuring Serveur_Entreprise_1..."

# interface eth0 -> net_dmz
docker exec --privileged Serveur_Entreprise_1 ip link set up dev eth0

# Default Gateway -> R_DMZ (10.10.20.1)
docker exec --privileged Serveur_Entreprise_1 ip route del default || true
docker exec --privileged Serveur_Entreprise_1 ip route add default via 10.10.20.1


