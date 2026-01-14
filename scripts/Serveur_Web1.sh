# #!/bin/bash
# echo "Configuring Serveur_Web1..."

# # interface eth0 -> net_37
# docker exec --privileged Serveur_Web1 ip link set up dev eth0

# # Default Gateway -> R11 (120.0.37.1)
# docker exec --privileged Serveur_Web1 ip route del default || true
# docker exec --privileged Serveur_Web1 ip route add default via 120.0.37.1


#!/bin/bash
echo "---------------------------------------------------"
echo "| CONFIGURATION : SERVEUR WEB (FRONTEND)          |"
echo "---------------------------------------------------"

# 1. Routage vers R11 (pour sortir du réseau 120.0.37.0)
docker exec --privileged Serveur_Web1 ip route del default || true
docker exec --privileged Serveur_Web1 ip route add default via 120.0.37.1

# 2. Préparation de la clé SSH (indispensable pour cmd SSH dans app.py)
# On crée le dossier et la clé RSA sans mot de passe
docker exec Serveur_Web1 mkdir -p /root/.ssh
docker exec Serveur_Web1 ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

echo -e "✅ Serveur Web prêt.\n"