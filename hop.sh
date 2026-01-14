#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}   DÉMONSTRATION INTERCONNEXION SITE-TO-SITE       ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. Vérification de la présence du tunnel
echo -e "\n${GREEN}[1/4] Vérification de l'interface VPN sur la Gateway Site 2...${NC}"
docker exec VPN_Gateway_Ent2 ip addr show tun0 | grep "inet 10.8.0.3" > /dev/null
if [ $? -eq 0 ]; then
    echo -e "✅ Interface tun0 active (IP: 10.8.0.3)"
else
    echo -e "${RED}❌ Erreur : Le tunnel n'est pas monté sur la Gateway.${NC}"
    exit 1
fi

# 2. Test de connectivité (Ping)
echo -e "\n${GREEN}[2/4] Test de ping : Client Site 2 -> Serveur DMZ Siège...${NC}"
docker exec Client1_Ent_Site2 ping -c 3 10.10.20.2
if [ $? -eq 0 ]; then
    echo -e "✅ Communication établie avec succès à travers le tunnel."
else
    echo -e "${RED}❌ Échec de la communication.${NC}"
fi

# 3. Analyse du chemin (Traceroute)
echo -e "\n${GREEN}[3/4] Analyse du chemin réseau (Traceroute)...${NC}"
docker exec Client1_Ent_Site2 traceroute -n 10.10.20.2

# 4. Démonstration de l'accès aux services internes
echo -e "\n${GREEN}[4/4] Accès au service Web du Siège depuis l'Agence...${NC}"
RESPONSE=$(docker exec Client1_Ent_Site2 wget -qO- http://10.10.20.2)
if [ ! -z "$RESPONSE" ]; then
    echo -e "✅ Données reçues du serveur distant : ${BLUE}Serveur Entreprise 1 OK${NC}"
else
    echo -e "${RED}❌ Impossible de joindre le serveur Web.${NC}"
fi

echo -e "\n${BLUE}===================================================${NC}"
echo -e "${BLUE}       FIN DE LA DÉMONSTRATION TECHNIQUE           ${NC}"
echo -e "${BLUE}===================================================${NC}"