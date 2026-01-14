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
echo -e "${YELLOW}Lancement des tests DNS et HTTP...${NC}"
sleep 1

# ==========================================
# 1. TEST CLIENT B1 (Acces Public)
# ==========================================
draw_box "CLIENT B1 : Résolution DNS & Accès Web"

# 1.1 NSLOOKUP
echo -e "${YELLOW}1. Test DNS (nslookup www.siteglobal.com)${NC}"
CMD="docker exec Client_B1 nslookup www.siteglobal.com"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
DNS_OUT=$(eval $CMD 2>&1)
DNS_IP=$(echo "$DNS_OUT" | grep "Address" | tail -n 1 | awk '{print $2}')

if [[ "$DNS_IP" == "120.0.37.2" ]]; then
    echo -e "${GREEN}✅ SUCCÈS : DNS résolu en $DNS_IP${NC}"
else
    echo -e "${RED}❌ ÉCHEC : Résolution incorrecte ou échouée.${NC}"
    echo -e "Sortie :\n$DNS_OUT"
fi
echo ""

# 1.2 WGET
echo -e "${YELLOW}2. Test HTTP (wget http://www.siteglobal.com)${NC}"
CMD="docker exec Client_B1 wget -qO- http://www.siteglobal.com"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
WGET_OUT=$(eval $CMD)

if echo "$WGET_OUT" | grep -q "FAI - Inscription FTP"; then
    echo -e "${GREEN}✅ SUCCÈS : Page web récupérée correctement.${NC}"
    # Affichage partiel pour confirmation visuelle
    echo -e "${CYAN}Aperçu du contenu :${NC}"
    echo "$WGET_OUT" | head -n 5
    echo "..."
else
    echo -e "${RED}❌ ÉCHEC : Impossible de récupérer la page web.${NC}"
fi
echo ""


# ==========================================
# 2. TEST CLIENT ENTREPRISE 1 (Acces Interne/DMZ -> Public)
# ==========================================
draw_box "CLIENT ENT1 : Résolution DNS & Accès Web"

# 2.1 NSLOOKUP
echo -e "${YELLOW}1. Test DNS (nslookup www.siteglobal.com)${NC}"
CMD="docker exec Client_Ent1 nslookup www.siteglobal.com"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
DNS_OUT=$(eval $CMD 2>&1)
DNS_IP=$(echo "$DNS_OUT" | grep "Address" | tail -n 1 | awk '{print $2}')

if [[ "$DNS_IP" == "120.0.37.2" ]]; then
    echo -e "${GREEN}✅ SUCCÈS : DNS résolu en $DNS_IP${NC}"
else
    echo -e "${RED}❌ ÉCHEC : Résolution incorrecte ou échouée.${NC}"
    echo -e "Sortie :\n$DNS_OUT"
fi
echo ""

# 2.2 WGET
echo -e "${YELLOW}2. Test HTTP (wget http://www.siteglobal.com)${NC}"
CMD="docker exec Client_Ent1 wget -qO- http://www.siteglobal.com"
echo -e "${NC}Exécution : ${YELLOW}$CMD${NC}"
WGET_OUT=$(eval $CMD)

if echo "$WGET_OUT" | grep -q "FAI - Inscription FTP"; then
    echo -e "${GREEN}✅ SUCCÈS : Page web récupérée correctement.${NC}"
    echo -e "${CYAN}Aperçu du contenu :${NC}"
    echo "$WGET_OUT" | head -n 5
    echo "..."
else
    echo -e "${RED}❌ ÉCHEC : Impossible de récupérer la page web.${NC}"
fi

echo -e "\n${YELLOW}=== FIN DES TESTS DNS ===${NC}"
