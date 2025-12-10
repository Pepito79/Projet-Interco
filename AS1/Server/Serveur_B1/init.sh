#!/bin/sh

echo "--- Config Serveur B1 ---"

# 1. Nettoyage et adressage IP
# D'après le schéma, le serveur est en .2
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 192.168.1.3/24 dev eth0

# 2. Route par défaut (Vers la Box B1 en .1)
ip route add default via 192.168.1.1

# 3. Lancement du service
# Pour l'instant on fait une pause infinie pour garder le serveur allumé.
# Plus tard, vous pourrez remplacer cela par "python3 -m http.server 80" pour un site web.
sleep infinity