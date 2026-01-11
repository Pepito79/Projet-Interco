#!/bin/bash
echo "Nettoyage et Configuration de R_Ent_LAN..."

# 1. Activation du routage
docker exec --privileged R_Ent_LAN sysctl -w net.ipv4.ip_forward=1

# 2. NETTOYAGE : On enlève les IPs automatiques de Docker pour éviter les doublons
# On vide eth1 (LAN) pour être sûr de n'avoir QUE la .1
docker exec --privileged R_Ent_LAN ip addr flush dev eth1

# 3. ATTRIBUTION PROPRE
# On remet l'IP Gateway sur eth1
docker exec --privileged R_Ent_LAN ip addr add 10.10.10.1/24 dev eth1

# 4. ALLUMAGE
docker exec --privileged R_Ent_LAN ip link set eth0 up
docker exec --privileged R_Ent_LAN ip link set eth1 up

# 5. SYNCHRO FRR (A chaud)
# On utilise 'replace' ou on ré-applique pour que Zebra soit synchro
docker exec R_Ent_LAN vtysh -c "conf t" \
  -c "int eth0" \
  -c " ip address 10.10.1.2/29" \
  -c "int eth1" \
  -c " ip address 10.10.10.1/24" \
  -c "end" -c "write"

echo "Vérification de l'état (Il ne doit y avoir qu'une IP par interface) :"
docker exec R_Ent_LAN ip -4 a show eth1

sudo chown -R $USER:$USER ./config