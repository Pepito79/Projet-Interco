#!/bin/bash

#chmod +x prepare.sh
#./prepare

echo "--- Mise à jour des permissions ---"

# Cette commande cherche tous les fichiers "init.sh" dans le dossier courant et les sous-dossiers
# et applique "chmod +x" dessus.
find . -name "init.sh" -exec chmod +x {} \;

echo "Tous les scripts init.sh sont maintenant exécutables."