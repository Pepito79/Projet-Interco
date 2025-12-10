#!/bin/bash
# prepare.sh - Script maître de déploiement (Version Corrigée)

# --- CONFIGURATION ---
# Temps d'attente (en sec) pour laisser les routeurs converger OSPF
WAIT_TIME=30

# Couleurs pour la lisibilité
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}##################################################${NC}"
echo -e "${BLUE}#     DÉMARRAGE DU SCRIPT DE PRÉPARATION         #${NC}"
echo -e "${BLUE}##################################################${NC}"

# ---------------------------------------------------------
# ÉTAPE 1 : Préparation des fichiers sur l'hôte (PC)
# ---------------------------------------------------------
echo -e "\n${BLUE}[1/3] Préparation des scripts locaux (chmod)...${NC}"

# On rend exécutables tous les scripts .sh du projet
find . -name "*.sh" -exec chmod +x {} \;
# Donne les droits de lecture à tout le monde sur les fichiers de config
# Rend tous les fichiers de configuration lisibles par tout le monde
find . -name "frr.conf" -exec chmod 644 {} \;
find . -name "daemons" -exec chmod 644 {} \;

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les scripts .sh sont maintenant exécutables.${NC}"
else
    echo -e "${RED}⚠ Erreur lors du changement des permissions.${NC}"
fi

# ---------------------------------------------------------
# ÉTAPE 2 : Reset de Docker (Suppression & Reconstruction)
# ---------------------------------------------------------
echo -e "\n${BLUE}[2/3] Suppression des anciens containers et reconstruction...${NC}"

# Arrêt propre et suppression des containers orphelins
docker-compose down --remove-orphans

# Construction et Démarrage en arrière-plan
# --build force la prise en compte des changements dans les Dockerfile ou contextes
docker-compose up -d --build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erreur critique : Impossible de lancer Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environnement Docker lancé.${NC}"

# ---------------------------------------------------------
# ÉTAPE 3 : Attente de convergence OSPF
# ---------------------------------------------------------
echo -e "\n${BLUE}[3/3] Attente de la convergence du réseau (${WAIT_TIME}s)...${NC}"
echo -e "${YELLOW}Note : Les scripts 'init.sh' sont exécutés automatiquement par les conteneurs au démarrage.${NC}"
echo "Patientez pendant que les routeurs OSPF s'échangent leurs tables..."

sleep $WAIT_TIME

echo -e "\n${GREEN}##################################################${NC}"
echo -e "${GREEN}#           DÉPLOIEMENT TERMINÉ !                #${NC}"
echo -e "${GREEN}##################################################${NC}"