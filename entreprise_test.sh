#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' 

# Fonction pour créer des encadrés
draw_box() {
    local title="$1"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -e "${BLUE}|${NC} ${CYAN}TEST : $title${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

clear
echo -e "${YELLOW} tests réseau en temps réel...${NC}"
sleep 1

# 1. TEST DHCP & IP
draw_box "VÉRIFICATION DHCP DU CLIENT"
CMD="docker exec Client_Ent1 ip -4 addr show eth0"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
CLIENT_IP=$(eval $CMD | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -n 1)

if [ -z "$CLIENT_IP" ]; then
    echo -e "${RED}❌ ÉCHEC : Aucune IP attribuée par le DHCP.${NC}"
else
    echo -e "${GREEN}✅ SUCCÈS : IP obtenue -> $CLIENT_IP${NC}"
fi
echo ""

# 2. TEST PING SERVEUR RH
draw_box "CONNECTIVITÉ INTERNE (LAN)"
CMD="docker exec Client_Ent1 ping -c 1 -W 1 10.10.10.5"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
if eval $CMD > /dev/null; then
    echo -e "${GREEN}✅ SUCCÈS : Le serveur RH répond.${NC}"
else
    echo -e "${RED}❌ ÉCHEC : Le serveur RH est injoignable.${NC}"
fi
echo ""

# 3. TEST PING DMZ
draw_box "ROUTAGE VERS LA DMZ"
CMD="docker exec Client_Ent1 ping -c 1 -W 1 10.10.20.2"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
if eval $CMD > /dev/null; then
    echo -e "${GREEN}✅ SUCCÈS : Traversée des routeurs vers la DMZ OK.${NC}"
else
    echo -e "${RED}❌ ÉCHEC : La DMZ est injoignable (Vérifiez OSPF/Forwarding).${NC}"
fi
echo ""

# 4. TEST DNS
draw_box "RÉSOLUTION DE NOM (DNS INTERNE)"
CMD="docker exec Client_Ent1 nslookup www.entreprise.com 10.10.20.3"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
DNS_RESULT=$(eval $CMD 2>/dev/null | grep "Address" | tail -n 1 | awk '{print $2}')

if [[ "$DNS_RESULT" == "10.10.20.2" ]]; then
    echo -e "${GREEN}✅ SUCCÈS : DNS a résolu www.entreprise.com en $DNS_RESULT${NC}"
else
    echo -e "${RED}❌ ÉCHEC : Erreur de résolution.${NC}"
fi

echo -e "\n${YELLOW}=== FIN DES TESTS RÉSEAU ===${NC}"