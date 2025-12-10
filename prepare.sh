#!/bin/bash
# prepare.sh - Script maître de déploiement

# --- CONFIGURATION ---
# Temps d'attente (en sec) pour laisser la base de données démarrer avant de lancer les scripts
WAIT_TIME=10

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
echo -e "\n${BLUE}[1/4] Préparation des scripts locaux (chmod)...${NC}"

# On cherche tous les fichiers .sh dans le projet et on les rend exécutables.
# Cela remplace ton "ancien prepare.sh" s'il ne faisait que des permissions.
find . -name "*.sh" -exec chmod +x {} \;

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les scripts .sh sont maintenant exécutables.${NC}"
else
    echo -e "${RED}⚠ Erreur lors du changement des permissions.${NC}"
fi

# ---------------------------------------------------------
# ÉTAPE 2 : Reset de Docker (Suppression & Reconstruction)
# ---------------------------------------------------------
echo -e "\n${BLUE}[2/4] Suppression des anciens containers et reconstruction...${NC}"

# Arrêt propre et suppression des containers orphelins
docker-compose down --remove-orphans

# Construction et Démarrage en arrière-plan
# --build force la prise en compte des changements dans les Dockerfile
docker-compose up -d --build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erreur critique : Impossible de lancer Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environnement Docker lancé.${NC}"

# ---------------------------------------------------------
# ÉTAPE 3 : Attente de stabilisation
# ---------------------------------------------------------
echo -e "\n${BLUE}[3/4] Attente de la disponibilité des services (${WAIT_TIME}s)...${NC}"
echo "Laissez le temps à la base de données de s'initialiser..."
sleep $WAIT_TIME

# ---------------------------------------------------------
# ÉTAPE 4 : Exécution automatique des init.sh par service
# ---------------------------------------------------------
echo -e "\n${BLUE}[4/4] Recherche et exécution des 'init.sh' DANS les containers...${NC}"

# Cette boucle cherche tous les fichiers "init.sh" situés dans des sous-dossiers (ex: ./odoo/init.sh)
# Elle déduit le nom du service Docker via le nom du dossier.
find . -mindepth 2 -maxdepth 2 -name "init.sh" | while read script_path; do
    
    # Extrait le nom du dossier (ex: "./odoo/init.sh" -> "odoo")
    SERVICE_NAME=$(dirname "$script_path" | sed 's|./||')
    
    echo -e "${YELLOW}>> Script trouvé pour le service : '${SERVICE_NAME}'${NC}"

    # Vérifie si le service tourne dans Docker
    if docker-compose ps --services --filter "status=running" | grep -q "^${SERVICE_NAME}$"; then
        
        echo "   -> Exécution de ${script_path} à l'intérieur du container..."
        
        # On injecte le contenu du script local directement dans le bash du container
        # L'option -T est importante pour éviter les erreurs de terminal
        docker-compose exec -T "$SERVICE_NAME" /bin/bash < "$script_path"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   -> Succès : Initialisation de ${SERVICE_NAME} terminée.${NC}"
        else
            echo -e "${RED}   -> Échec : Erreur lors de l'exécution sur ${SERVICE_NAME}.${NC}"
        fi

    else
        echo -e "${RED}   -> Ignoré : Le service '${SERVICE_NAME}' n'est pas actif.${NC}"
    fi
done

echo -e "\n${GREEN}##################################################${NC}"
echo -e "${GREEN}#           DÉPLOIEMENT TERMINÉ !                #${NC}"
echo -e "${GREEN}##################################################${NC}"