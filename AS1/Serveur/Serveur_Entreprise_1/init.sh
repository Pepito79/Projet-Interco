#!/bin/sh

echo "--- Config Serveur Entreprise 1 ---"

# 1. Configuration IP (10.10.10.3)
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 10.10.10.2/24 dev eth0

# 2. Route par défaut vers le routeur d'entreprise
ip route add default via 10.10.10.1

# 3. Simulation d'un service Web simple (Port 80)
# Cela permet de tester si on peut "voir" le serveur via HTTP
# Si python3 n'est pas installé par défaut sur votre image alpine, 
# la commande échouera et passera au sleep infinity.
echo "Lancement serveur web de test..."
if command -v python3 >/dev/null; then
    python3 -m http.server 80 &
fi

# 4. Maintien du conteneur en vie
sleep infinity