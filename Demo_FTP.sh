#!/bin/bash

echo "📦 Installation des outils sur les clients..."
docker exec Client_Ent1 apk add --no-cache curl lftp > /dev/null
docker exec Client_B1 apk add --no-cache curl lftp > /dev/null
echo "✅ Clients prêts (curl et lftp installés)."


GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== TEST FTP AVEC LFTP (SITE VERS SITE) ===${NC}"

# 1. Variables de test
USER_TEST="client_lftp"
PASS_TEST="lftp_pass_123"
FTP_SERVER="120.0.37.5"
WEB_SERVER="120.0.37.2"

# 2. CRÉATION DU COMPTE via le Web
echo -e "\n1. Inscription via le portail Web..."
docker exec Client_Ent1 curl -s -X POST -d "user=$USER_TEST&pass=$PASS_TEST" http://$WEB_SERVER/ | grep "Succès"

# 3. PRÉPARATION DU FICHIER sur le client
docker exec Client_Ent1 sh -c "echo 'Données transférées via lftp' > depot_lftp.txt"

# 4. TRANSFERT AVEC LFTP
echo -e "2. Dépôt du fichier avec lftp..."
# On utilise l'option -c pour exécuter une suite de commandes
docker exec Client_Ent1 lftp -u "$USER_TEST","$PASS_TEST" $FTP_SERVER -e "put depot_lftp.txt; quit"

# 5. VÉRIFICATION SUR LE SERVEUR
echo -e "\n${GREEN}=== VÉRIFICATION SUR LE SERVEUR ===${NC}"
if docker exec Serveur_FTP_Public ls -l /home/$USER_TEST/depot_lftp.txt > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SUCCÈS : Le fichier est présent sur le serveur FTP.${NC}"
    docker exec Serveur_FTP_Public cat /home/$USER_TEST/depot_lftp.txt
else
    echo -e "\033[0;31m❌ ÉCHEC : Le fichier n'a pas été trouvé.\033[0m"
fi

echo -e "\n${BLUE}=== FIN DU TEST ===${NC}"