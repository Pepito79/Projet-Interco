#!/bin/sh
echo "--- Config Serveur_Entreprise_2 ---"
# On supprime la route par défaut Docker et on met la nôtre (20.20.20.1)
ip route del default 2>/dev/null
ip route add default via 20.20.20.1

# On garde le conteneur en vie
tail -f /dev/null