#!/bin/sh
echo "=== Démarrage du Serveur VPN (.4) ==="

# 1. Installation des outils (Indispensable sur Alpine)
apk add --no-cache python3 py3-pip iproute2 iptables

echo "Configuration de la passerelle par défaut (Vers R_Ent_DMZ)..."
# On supprime la route par défaut Docker
ip route del default || true
# On ajoute la route vers NOTRE routeur (10.10.20.1)
ip route add default via 10.10.20.1

# 2. Activation du NAT (Le Masquerade qui manquait !)
# C'est LA ligne qui permet au serveur RH de répondre
echo "Activation du NAT (Masquerade)..."
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# 3. Création du dossier tun (nécessaire pour certains linux)
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

# 4. Lancement du serveur Python
echo "Lancement de vpn_server.py..."
cd /app
# On utilise -u pour voir les logs en direct
exec python3 -u vpn_server.py