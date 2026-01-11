#!/bin/sh
echo "--- Démarrage Gateway VPN Site 2 (Mode Python) ---"

# 1. Installation des outils
apk add --no-cache python3 iproute2 iptables

# 2. Routage de base (Sortie vers Internet via R_Entreprise2)
ip route del default 2>/dev/null
ip route add default via 10.20.10.9
echo "Route par défaut configurée via 10.20.10.9"

# 3. Préparation du script Python
# On copie le script client officiel dans un dossier de travail
cp /app/vpn_client.py /root/vpn_client.py
cd /root

# HACK : Ton script vpn_client.py est codé en dur sur le port 9999.
# Le Site-to-Site utilise le port 10000. On change ça à la volée.
sed -i 's/SERVER_PORT = 9999/SERVER_PORT = 10000/' vpn_client.py

# 4. Lancement du VPN
# IP Publique de R_Entreprise1 (Site 1)
export VPN_SERVER_IP="120.0.34.2"

echo "Connexion au VPN Site 1 ($VPN_SERVER_IP:10000)..."

# On injecte les identifiants définis dans vpn_server.py (site2_gw / azerty123)
# Le script Python attend qu'on tape ces infos, donc on utilise printf pour les lui donner.
printf "site2_gw\nazerty123\n" | python3 -u vpn_client.py > /var/log/vpn.log 2>&1 &

# 5. Configuration de l'interface Tunnel
echo "Attente de l'interface tun0..."
while ! ip link show tun0 > /dev/null 2>&1; do sleep 1; done

echo "Interface tun0 active ! Configuration IP..."
ip link set tun0 up
ip link set tun0 mtu 1200
# On force l'IP (Même si le serveur la donne, c'est plus sûr pour la gateway)
ip addr add 10.0.1.50/24 dev tun0

# 6. ROUTAGE VERS L'ENTREPRISE 1
# Tout le trafic pour 10.10.0.0/16 (Site 1) doit passer par le tunnel
ip route add 10.10.0.0/16 via 10.0.1.1 dev tun0

# 7. NAT (Masquerade)
# Indispensable : Quand un PC du Site 2 passe par cette Gateway, 
# il prend l'IP du tunnel (10.0.1.50) pour être accepté en face.
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

echo "✅ VPN SITE-TO-SITE CONNECTÉ."
# On affiche les logs en direct
tail -f /var/log/vpn.log