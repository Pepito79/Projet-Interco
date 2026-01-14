#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== INSTALLATION DES OUTILS (PYTHON3 & TCPDUMP) ===${NC}"

# 1. On s'assure que Client_C1 peut sortir sur Internet pour télécharger
echo -e "${GREEN}🔧 Préparation de Client_C1...${NC}"
docker exec Client_C1 sh -c "ip route del default || true; ip route add default via 192.168.2.5; echo 'nameserver 120.0.36.2' > /etc/resolv.conf"

# 2. Installation des paquets
# On installe Python3 pour le script VPN et tcpdump pour la preuve de chiffrement
echo -e "${GREEN}📥 Installation sur Client_C1...${NC}"
docker exec Client_C1 apk add --no-cache python3 iptables tcpdump curl lftp

echo -e "${GREEN}📥 Installation sur Serveur_VPN_Ent1...${NC}"
docker exec Serveur_VPN_Ent1 apk add --no-cache python3 iptables tcpdump

echo -e "${BLUE}=== INSTALLATION TERMINÉE ===${NC}"