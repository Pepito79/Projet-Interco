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
docker exec --privileged R_Entreprise1 ip link set eth0 up
docker exec --privileged R_Entreprise1 ip link set eth1 up
docker exec --privileged R_Entreprise1 ip link set eth2 up

# 2. Restart FRR (Removed to prevent container exit)
# docker exec R_Entreprise1 /usr/lib/frr/frrinit.sh restart

echo "R_Entreprise1 est désormais stable et configuré."