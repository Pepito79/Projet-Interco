#!/bin/bash

echo "🔄 Résolution de l'IP du serveur..."
export VPN_SERVER_IP=$(getent hosts vpn-server | awk '{ print $1 }')

# 1. Lancer Python (Mode Silencieux)
python vpn_client.py &
PID=$!

# 2. Attendre tun0
echo "⏳ Attente de tun0..."
while ! ip link show tun0 > /dev/null 2>&1; do sleep 0.1; done

# 3. Optimisations Réseau
ethtool -K tun0 tx off rx off > /dev/null 2>&1 || true

# 👇 MSS SÉCURISÉ (1160) : On laisse beaucoup de place
iptables -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1160

# 4. Routage
GATEWAY_IP=$(ip route show | grep default | awk '{ print $3 }')
ip route add $VPN_SERVER_IP via $GATEWAY_IP dev eth0 2>/dev/null || ip route add $VPN_SERVER_IP dev eth0

# 5. Route par défaut
ip route del default
ip route add default via 10.0.0.1 dev tun0

# 6. DNS et MTU
echo "nameserver 8.8.8.8" > /etc/resolv.conf
# 👇 MTU SÉCURISÉ (1200)
ip link set tun0 mtu 1200

# 7. Proxy
if [ -f /etc/tinyproxy/tinyproxy.conf ]; then
    sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf
    grep -q "DisableViaHeader Yes" /etc/tinyproxy/tinyproxy.conf || echo "DisableViaHeader Yes" >> /etc/tinyproxy/tinyproxy.conf
    # Augmenter le timeout du proxy pour éviter qu'il ne coupe trop vite
    grep -q "Timeout 600" /etc/tinyproxy/tinyproxy.conf || echo "Timeout 600" >> /etc/tinyproxy/tinyproxy.conf
fi

service tinyproxy restart

echo "🚀 VPN Mode Performance (Logs OFF + MTU 1200) prêt !"
wait $PID