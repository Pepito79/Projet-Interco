#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}       DÉMONSTRATION DU PROJET VPN INTERCO       ${NC}"
echo -e "${BLUE}==================================================${NC}"

# ==============================================================================
# PARTIE 1 : CLIENT NOMADE (Client_C1) -> ENTREPRISE 1
# ==============================================================================
echo -e "\n${YELLOW}--- PARTIE 1 : CLIENT NOMADE (Client_C1) ---${NC}"

# 1.1 Nettoyage
echo -e "🧹 Nettoyage des processus VPN existants sur C1..."
docker exec Client_C1 pkill python3 >/dev/null 2>&1
docker exec Client_C1 ip addr flush dev tun0 >/dev/null 2>&1
sleep 1

# 1.2 Preuve d'isolation
echo -e "\n🔍 ${YELLOW}TEST 1 : PREUVE D'ISOLATION (Sans VPN)${NC}"
echo "Tentative de ping vers 10.0.0.1 (VPN Server IP)..."
# On affiche l'erreur (stderr) pour que l'utilisateur la voie
if docker exec Client_C1 ping -c 1 -W 1 10.0.0.1; then
    echo -e "${RED}[ÉCHEC] Le serveur est accessible sans VPN (Anormal)${NC}"
else
    echo -e "${GREEN}[SUCCÈS] Le ping a échoué (Network Unreachable) comme prévu.${NC}"
fi

# 1.3 Connexion VPN
echo -e "\n🔄 ${YELLOW}CONNEXION VPN (Utilisateur: thomas)${NC}"
echo "Lancement du client..." 
# On utilise les variables d'environnement pour éviter le prompt interactif (et le warning getpass)
docker exec -d -e VPN_SERVER_IP="120.0.34.2" -e VPN_USERNAME="thomas" -e VPN_PASSWORD="superpassword" Client_C1 python3 -u /app/vpn_client.py > /tmp/demo_c1.log 2>&1
sleep 5

if docker exec Client_C1 ip link show tun0 >/dev/null 2>&1; then
    echo -e "${GREEN}[SUCCÈS] Interface tun0 créée !${NC}"
    echo -e "Logs client :"
    head -n 5 /tmp/demo_c1.log
else
    echo -e "${RED}[ÉCHEC] Le VPN ne s'est pas connecté.${NC}"
    cat /tmp/demo_c1.log
    exit 1
fi

# 1.4 Test Connectivité
echo -e "\n📡 ${YELLOW}TEST 2 : CONNECTIVITÉ VPN${NC}"
echo "Ping 10.0.0.1..."
if docker exec Client_C1 ping -c 2 10.0.0.1; then
     echo -e "${GREEN}[SUCCÈS] Ping VPN OK (10.0.0.1)${NC}"
else
     echo -e "${RED}[ÉCHEC] Ping VPN Failed${NC}"
fi

# 1.5 Preuve de Cryptage
echo -e "\n🔒 ${YELLOW}TEST 3 : PREUVE DE CRYPTAGE${NC}"
echo "Capture de 5 paquets sur le serveur pendant un ping..."
docker exec Serveur_Entreprise_1 timeout 5s tcpdump -i eth0 port 9999 -X -c 5 > /tmp/demo_crypto.txt 2>&1 &
sleep 2
docker exec Client_C1 ping -c 5 10.0.0.1 >/dev/null 2>&1
sleep 2
echo -e "Affichage d'un paquet capturé :"
grep -A 3 "0x0000" /tmp/demo_crypto.txt | head -n 4
echo -e "${GREEN}Note : Les données sont chiffrées (XOR 0x99).${NC}"

# ==============================================================================
# PARTIE 2 : SITE-A-SITE (ENTREPRISE 1 <-> ENTREPRISE 2)
# ==============================================================================
echo -e "\n\n${BLUE}==================================================${NC}"
echo -e "${YELLOW}--- PARTIE 2 : SITE-TO-SITE (Ent1 <-> Ent2) ---${NC}"
echo -e "${BLUE}==================================================${NC}"

TARGET_IP="10.20.10.9"

# 2.1 Preuve d'isolation
echo -e "\n🔍 ${YELLOW}TEST 4 : ISOLATION GÉOGRAPHIQUE${NC}"
echo "Simulation absence de route..."
docker exec Client_Ent1 ip route del 10.20.10.0/24 >/dev/null 2>&1 || true
docker exec Client_Ent1 ip route add blackhole 10.20.10.0/24

echo "Tentative de ping vers Entreprise 2 ($TARGET_IP)..."
if docker exec Client_Ent1 ping -c 1 -W 1 $TARGET_IP >/dev/null 2>&1; then
    echo -e "${RED}[ÉCHEC] Accessible sans VPN !${NC}"
else
    echo -e "${GREEN}[SUCCÈS] Inaccessible sans VPN (Simulé).${NC}"
fi

# 2.2 Activation Pont
echo -e "\n🌉 ${YELLOW}ACTIVATION DU PONT VPN${NC}"
echo "Ajout de la route vers le Bridge..."
docker exec Client_Ent1 ip route del blackhole 10.20.10.0/24
docker exec Client_Ent1 ip route add 10.20.10.0/24 via 10.10.10.200

# 2.3 Accès Données
echo -e "\n📁 ${YELLOW}TEST 5 : ACCÈS PING${NC}"
if docker exec Client_Ent1 ping -c 2 $TARGET_IP; then
    echo -e "${GREEN}[SUCCÈS] Ping Ent2 OK via Tunnel !${NC}"
else
    echo -e "${RED}[ÉCHEC] Ping Ent2 Failed.${NC}"
fi

# 2.4 Accès Web
echo -e "\n🌐 ${YELLOW}TEST 6 : ACCÈS SITE WEB (Tunnel VPN)${NC}"
echo "Démarrage serveur Web interne sur le portail VPN (10.0.0.1)..."
# Le serveur VPN a déjà python3. On lance un serveur HTTP sur l'IP du tunnel.
docker exec -d Serveur_VPN_Ent2 sh -c "mkdir -p /tmp/www && echo '<h1>Bienvenue sur le Intranet Ent2</h1>' > /tmp/www/index.html && cd /tmp/www && python3 -m http.server 8080 --bind 0.0.0.0"
sleep 2

echo -e "Ajout route vers l'infrastructure VPN (10.0.0.0/24)..."
docker exec Client_Ent1 ip route add 10.0.0.0/24 via 10.10.10.200 >/dev/null 2>&1 || true

echo -e "Téléchargement page Web depuis Client_Ent1..."
OUTPUT=$(docker exec Client_Ent1 wget -qO- --timeout=5 http://10.0.0.1:8080)

if [[ -n "$OUTPUT" ]]; then
     echo -e "${GREEN}[SUCCÈS] Page Intranet reçue !${NC}"
     echo -e "Contenu : $OUTPUT"
else
     echo -e "${RED}[ÉCHEC] Pas de réponse Web (10.0.0.1:8080).${NC}"
fi

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}       DÉMONSTRATION TERMINÉE        ${NC}"
echo -e "${BLUE}==================================================${NC}"
