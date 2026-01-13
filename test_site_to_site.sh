#!/bin/bash

# Definition des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'

TARGET_IP="20.20.20.2" # Client1_Ent2 (Site 2 LAN)
# Source: Client_Ent1 (10.10.10.2)

echo -e "${BOLD}🌍 Démarrage du test VPN CLIENT-to-CLIENT (Site-to-Site)...${NC}"
echo "--------------------------------------------------------"

# 1. Vérification de la configuration préalable
echo -e "\n${BOLD}[1/3] Vérification des routes et du firewall${NC}"
./scripts/firewall.sh > /dev/null 2>&1
./scripts/configure_site2.sh > /dev/null 2>&1
echo "✅ Configuration réseau appliquée."

# 2. Test Ping Site-to-Site
echo -e "\n${BOLD}[2/3] Test de connectivité (Ping)${NC}"
echo "Tentative de ping depuis Client_Ent1 vers ${TARGET_IP}..."

# On lance un ping count 4
docker exec Client_Ent1 ping -c 4 "${TARGET_IP}" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SUCCESS : Le VPN Site-to-Site est fonctionnel !${NC}"
    echo "Le trafic passe de LAN 1 (10.10.10.0/24) vers LAN 2 (20.20.20.0/24)."
else
    echo -e "${RED}❌ FAILURE : Le ping a échoué. Vérifiez le tunnel VPN et le routage.${NC}"
    exit 1
fi

# 3. Test Négatif (Accès Internet -> Site 2)
echo -e "\n${BOLD}[3/4] Test de refus d'accès (Internet -> LAN 2)${NC}"
echo "Tentative de ping depuis Client_B1 (Internet) vers ${TARGET_IP}..."

# On lance un ping avec timeout court
docker exec Client_B1 ping -c 2 -W 2 "${TARGET_IP}" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${GREEN}✅ SUCCESS : L'accès direct depuis Internet est bien BLOQUÉ.${NC}"
else
    echo -e "${RED}❌ FAILURE : Client_B1 a réussi à joindre LAN 2 ! Fail de sécurité !${NC}"
fi

# 4. Vérification du chiffrement
echo -e "\n${BOLD}[4/4] Vérification du chiffrement sur le lien public${NC}"
echo -e "${BOLD}🕵️  Capture du trafic sur R_Entreprise2 (Interface Publique)...${NC}"

# On capture sur R_Entreprise2 eth0 (vers Internet)
# On cherche UDP 9999
docker exec -d R_Entreprise2 sh -c "tcpdump -U -i eth0 -X -c 1 udp port 9999 > /tmp/capture_site.txt 2>&1"

# On relance un ping pour générer du trafic
docker exec Client_Ent1 ping -c 2 "${TARGET_IP}" > /dev/null 2>&1

sleep 2

# Vérification du fichier capture
if docker exec R_Entreprise2 [ -f /tmp/capture_site.txt ]; then
    echo -e "${BOLD}🔍 Analyse du paquet capturé :${NC}"
    echo "Si le VPN fonctionne, le contenu doit être illisible (chiffré)."
    docker exec R_Entreprise2 cat /tmp/capture_site.txt
    
    # Nettoyage
    docker exec R_Entreprise2 rm /tmp/capture_site.txt
else
    echo -e "${RED}⚠️  Pas de paquet capturé. Le tunnel est peut-être inactif ou le trafic ne passe pas par eth0.${NC}"
fi

echo "--------------------------------------------------------"
echo -e "${BOLD}Fin du test Site-to-Site.${NC}"
