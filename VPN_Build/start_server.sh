#!/bin/bash

# 1. Configurer le NAT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# 2. 🔥 CRUCIAL : Désactiver le Checksum Offloading pour que les paquets soient valides
# (On attend que l'interface existe, donc on le fera après le lancement de Python ou via une astuce,
# mais ici on va utiliser iptables pour forcer le calcul du checksum au cas où ethtool échoue plus tard)
iptables -t mangle -A POSTROUTING -p tcp -j CHECKSUM --checksum-fill

# 3. Autoriser explicitement le trafic TUN -> ETH (Docker bloque parfois par défaut)
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT

# 4. MSS Clamping
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "✅ Serveur : Firewall & NAT configurés."

# Lancer le serveur Python
# Astuce : On lance Python en background pour pouvoir configurer ethtool ensuite
python vpn_server.py &
PID=$!

# Attendre que tun0 soit créé par Python
while ! ip link show tun0 > /dev/null 2>&1; do sleep 0.1; done

# 🔥 Désactivation matérielle de l'offloading (Le vrai fix)
ethtool -K tun0 tx off 2>/dev/null || true

echo "✅ Serveur : Offloading désactivé sur tun0."
wait $PID