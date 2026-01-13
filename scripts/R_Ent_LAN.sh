#!/bin/bash
echo "Nettoyage et Configuration de R_Ent_LAN..."

# 1. Activation du routage
docker exec --privileged R_Ent_LAN sysctl -w net.ipv4.ip_forward=1

# 2. Activation des interfaces (IPs gérées par docker-compose)
docker exec --privileged R_Ent_LAN ip link set eth0 up
docker exec --privileged R_Ent_LAN ip link set eth1 up

# 3. Apply FRR Config
# docker exec R_Ent_LAN /usr/lib/frr/frrinit.sh restart

echo "Vérification de l'état (Il ne doit y avoir qu'une IP par interface) :"
docker exec R_Ent_LAN ip -4 a show eth1

sudo chown -R $USER:$USER ./config