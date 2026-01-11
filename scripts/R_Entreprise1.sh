# #!/bin/bash
# echo "Configuration de R_Entreprise1..."

# # 1. On active le forwarding (essentiel pour un routeur)
# docker exec --privileged R_Entreprise1 sysctl -w net.ipv4.ip_forward=1

# # 2. On s'assure que les interfaces sont UP (au cas où)
# docker exec --privileged R_Entreprise1 ip link set eth0 up
# docker exec --privileged R_Entreprise1 ip link set eth1 up
# docker exec --privileged R_Entreprise1 ip link set eth2 up

# # 3. Optionnel : Relancer FRR pour qu'il détecte bien les interfaces UP
# # docker exec R_Entreprise1 /usr/lib/frr/frrinit.sh restart

# echo "R_Entreprise1 est prêt."

#!/bin/bash
echo "Configuration de R_Entreprise1..."

# 1. Activation du forwarding
docker exec --privileged R_Entreprise1 sysctl -w net.ipv4.ip_forward=1

# 2. NETTOYAGE DES INTERFACES (Flush)
# Cela supprime les IP en double que tu as vues avec 'ip a'
echo "Nettoyage des IP en double..."
docker exec --privileged R_Entreprise1 ip addr flush dev eth0
docker exec --privileged R_Entreprise1 ip addr flush dev eth1
docker exec --privileged R_Entreprise1 ip addr flush dev eth2

# 3. RE-ASSIGNATION PROPRE (Selon ton YAML)
# eth0 -> net_34
docker exec --privileged R_Entreprise1 ip addr add 120.0.34.2/24 dev eth0
# eth1 -> net_ent_lan
docker exec --privileged R_Entreprise1 ip addr add 10.10.1.1/29 dev eth1
# eth2 -> net_ent_dmz
docker exec --privileged R_Entreprise1 ip addr add 10.10.2.1/29 dev eth2

# 4. Activation des interfaces
docker exec --privileged R_Entreprise1 ip link set eth0 up
docker exec --privileged R_Entreprise1 ip link set eth1 up
docker exec --privileged R_Entreprise1 ip link set eth2 up

# 5. Redémarrage du service FRR
# Maintenant que les IP sont propres, FRR peut lancer OSPF sans crash
docker exec R_Entreprise1 /usr/lib/frr/frrinit.sh restart

echo "R_Entreprise1 est désormais stable et configuré."