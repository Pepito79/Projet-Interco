#!/bin/bash

# Definition des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'

TARGET_IP="10.10.10.5" # Serveur_Interne_RH

echo -e "${BOLD}🔒 Démarrage du test de sécurité VPN...${NC}"
echo "--------------------------------------------------------"

# 0. Reset Environnement (Firewall)
echo -e "🔄 Réapplication des règles de sécurité..."
./scripts/firewall.sh > /dev/null 2>&1
echo "✅ Firewall appliqué."

# 1. Test depuis Client_B1 (Non autorisé)
echo -e "\n${BOLD}[1/2] Test d'accès NON-AUTORISÉ depuis Client_B1 (Internet)${NC}"
echo "Tentative de ping vers ${TARGET_IP}..."

# On lance un ping avec un timeout court (-W 2) et count 2
docker exec Client_B1 ping -c 2 -W 2 "${TARGET_IP}" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${GREEN}✅ SUCCESS : L'accès est bien bloqué pour Client_B1.${NC}"
else
    echo -e "${RED}❌ FAILURE : Client_B1 a réussi à pinger le serveur ! Faille de sécurité !${NC}"
fi

# 2. Test depuis Client_C1 (Autorisé via VPN)
echo -e "\n${BOLD}[2/2] Test d'accès AUTORISÉ depuis Client_C1 (VPN Client)${NC}"

# Demander les identifiants à l'utilisateur
echo -e "\n${BOLD}🔑 Authentification VPN Requise${NC}"
read -p "Nom d'utilisateur : " VPN_USER
read -s -p "Mot de passe : " VPN_PASS
echo ""

echo -e "🔄 Redémarrage du client VPN avec l'utilisateur ${BOLD}$VPN_USER${NC}..."
# Tuer TOUS les processus python3 pour garantir l'arrêt du VPN précédent
docker exec Client_C1 killall python3 > /dev/null 2>&1
sleep 2

# Démarrer le nouveau avec les arguments
docker exec -d Client_C1 python3 /vpn/vpn_client.py "$VPN_USER" "$VPN_PASS"

# Attendre la négociation du tunnel
sleep 5

# Démarrer une capture tcpdump en arrière-plan pour voir le chiffrement
echo -e "${BOLD}🕵️  Capture du trafic sur l'interface publique (eth0) pour vérifier le chiffrement...${NC}"
# On capture 1 paquet UDP 9999 en Hex/Ascii (-X) sur eth0
docker exec -d Client_C1 sh -c "tcpdump -U -i eth0 -X -c 1 udp port 9999 > /tmp/capture.txt 2>&1"

# Petit délai pour laisser tcpdump démarrer
sleep 1

echo "Tentative de ping vers ${TARGET_IP} via le tunnel VPN..."
docker exec Client_C1 ping -c 4 "${TARGET_IP}" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SUCCESS : Client_C1 accède bien au serveur via le VPN.${NC}"
    
    echo -e "\n${BOLD}🔍 Analyse du paquet capturé (Preuve de chiffrement) :${NC}"
    echo "Si le VPN fonctionne, vous ne devriez PAS voir de texte clair comme 'PING' ou 'abc...'."
    docker exec Client_C1 cat /tmp/capture.txt
else
    echo -e "${RED}❌ FAILURE : Client_C1 n'arrive pas à joindre le serveur. Vérifiez le VPN.${NC}"
fi

echo "--------------------------------------------------------"
echo -e "${BOLD}Fin du test.${NC}"
