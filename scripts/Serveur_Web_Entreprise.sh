#!/bin/bash
echo "Configuring Serveur_Web_Entreprise..."

# interface eth0 -> net_dmz
docker exec --privileged Serveur_Web_Entreprise ip link set up dev eth0

# Default Gateway -> R_DMZ (10.10.20.254)
docker exec --privileged Serveur_Web_Entreprise ip route del default || true
docker exec --privileged Serveur_Web_Entreprise ip route add default via 10.10.20.254

# Lancer le serveur web (Python simple) dans le dossier monté
docker exec --privileged Serveur_Web_Entreprise apk add --no-cache python3
docker exec --privileged Serveur_Web_Entreprise sh -c "cd /var/www/html && python3 -m http.server 80"
