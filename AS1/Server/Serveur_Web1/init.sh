#!/bin/sh

echo "--- Config Serveur Web 1 ---"

# 1. Configuration IP (120.0.37.2)
# R11 est la passerelle en .1
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 120.0.37.2/24 dev eth0

# 2. Route par défaut vers R11
ip route add default via 120.0.37.1

# 3. Lancement d'un site web de test (Port 80)
echo "<h1>Site Web de l'AS1</h1>" > index.html
if command -v python3 >/dev/null; then
    echo "Lancement serveur HTTP..."
    python3 -m http.server 80 &
fi

# 4. Maintien du conteneur en vie
sleep infinity