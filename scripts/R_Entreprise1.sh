#!/bin/bash
echo "Configuration fusionnée de R_Entreprise1..."

# 1. Activation du transfert de paquets (Forwarding)
docker exec --privileged R_Entreprise1 sysctl -w net.ipv4.ip_forward=1

# 2. Nettoyage et Configuration des IPs (Ta partie HEAD)
# On s'assure que les interfaces ont les bonnes IPs sans doublons
docker exec --privileged R_Entreprise1 ip addr flush dev eth0
docker exec --privileged R_Entreprise1 ip addr add 120.0.34.2/24 dev eth0
docker exec --privileged R_Entreprise1 ip addr flush dev eth1
docker exec --privileged R_Entreprise1 ip addr add 10.10.2.1/29 dev eth1
docker exec --privileged R_Entreprise1 ip addr flush dev eth2
docker exec --privileged R_Entreprise1 ip addr add 10.10.1.1/29 dev eth2

# 3. Règles NAT pour le VPN (Partie test-vpn)
# Cette règle dit : "Tout ce qui arrive sur l'IP 120.0.34.2 sur le port 9999, 
# envoie-le au serveur VPN 10.10.20.2"
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 9999 -j DNAT --to-destination 10.10.20.2
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -d 10.10.20.2 -p tcp --dport 9999 -j MASQUERADE

# 4. Relance des services (Ta partie HEAD)
docker exec R_Entreprise1 /usr/lib/frr/frrinit.sh restart
echo "✅ R_Entreprise1 est configuré avec le NAT pour le VPN."