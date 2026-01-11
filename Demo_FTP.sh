#!/bin/bash

# Couleurs pour la présentation
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DÉMONSTRATION INFRASTRUCTURE FAI - SERVICE FTP ===${NC}"
echo "-------------------------------------------------------"

# ÉTAPE 0 : Préparation (Installation de curl)
echo -e "${BLUE}ÉTAPE 0 : Vérification des outils sur Client_B1${NC}"
docker exec Client_B1 which curl > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "📦 Installation de curl sur Client_B1..."
    docker exec Client_B1 apk add --no-cache curl > /dev/null
    echo -e "${GREEN}✅ curl est maintenant installé.${NC}"
else
    echo -e "${GREEN}✅ curl est déjà présent.${NC}"
fi

echo ""

# ÉTAPE 1 : Test d'échec
echo -e "${BLUE}ÉTAPE 1 : Tentative de connexion sans compte${NC}"
echo "Le client B1 essaie d'accéder au FTP sans s'être inscrit..."
sleep 2
# On capture le résultat pour montrer le refus
RESULT=$(docker exec Client_B1 lftp -u inconnu,mauvaispass -e "ls; quit" 120.0.37.5 2>&1)
if [[ $RESULT == *"Login incorrect"* ]]; then
    echo -e "${RED}❌ Accès refusé (Normal : compte inexistant)${NC}"
fi

echo ""

# ÉTAPE 2 : Inscription Web
echo -e "${BLUE}ÉTAPE 2 : Inscription via le portail Web (API Flask)${NC}"
echo "Le client B1 envoie ses identifiants au serveur Web (120.0.37.2)..."
sleep 2
# Simulation de l'inscription via curl
INSCRIPTION=$(docker exec Client_B1 curl -s -X POST -F "user=fai_user" -F "pass=fai2025" http://120.0.37.2/)
echo "$INSCRIPTION" | grep -q "Succès"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Compte 'fai_user' créé dynamiquement via le réseau !${NC}"
else
    echo -e "${RED}❌ Erreur lors de l'inscription Web.${NC}"
    exit 1
fi

echo ""

# ÉTAPE 3 : Connexion et Transfert
echo -e "${BLUE}ÉTAPE 3 : Connexion FTP et dépôt de fichier${NC}"
echo "Connexion établie avec les nouveaux identifiants. Transfert..."
sleep 2
# Création d'un fichier de preuve
docker exec Client_B1 sh -c "echo 'Fichier de preuve genere par Client_B1 le $(date)' > /tmp/preuve.txt"
# Envoi sur le serveur FTP
docker exec Client_B1 lftp -u fai_user,fai2025 -e "put /tmp/preuve.txt; ls; quit" 120.0.37.5

echo ""

# ÉTAPE 4 : Vérification finale sur le serveur
echo -e "${BLUE}ÉTAPE 4 : Vérification physique sur le serveur FTP${NC}"
echo "On vérifie que le fichier est bien arrivé sur le stockage distant..."
sleep 2
docker exec Serveur_FTP_Public ls -lh /home/fai_user/preuve.txt
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}⭐ DÉMONSTRATION RÉUSSIE ⭐${NC}"
    echo "L'interconnexion Web -> SSH -> FTP est opérationnelle."
else
    echo -e "${RED}❌ Le fichier n'a pas été trouvé sur le serveur.${NC}"
fi