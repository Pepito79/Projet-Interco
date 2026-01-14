#!/bin/bash
echo "🚀 Configuring Box_C1 (DHCP + NAT + Routing)..."

# 1. Activation des interfaces sur la Box
docker exec --privileged Box_C1 ip link set up dev eth0
docker exec --privileged Box_C1 ip link set up dev eth1

# 2. Activation du Forwarding au niveau du noyau
docker exec --privileged Box_C1 sysctl -w net.ipv4.ip_forward=1

# 3. Installation et configuration du DHCP (dnsmasq) sur la Box
echo "📥 Installing DHCP server on Box_C1..."
docker exec --privileged Box_C1 sh -c "
  apk add --no-cache dnsmasq
  echo 'interface=eth1' > /etc/dnsmasq.conf
  echo 'dhcp-range=192.168.2.50,192.168.2.100,24h' >> /etc/dnsmasq.conf
  echo 'dhcp-option=option:router,192.168.2.5' >> /etc/dnsmasq.conf
  echo 'dhcp-option=option:dns-server,8.8.8.8' >> /etc/dnsmasq.conf
  pkill dnsmasq || true
  dnsmasq
"

# 4. Configuration du NAT sur la Box
echo "🛡️ Setting up NAT rules on Box_C1..."
docker exec --privileged Box_C1 sh -c "
  iptables -t nat -F
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
  iptables -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
"

# --- AJOUT POUR LE CLIENT C1 ---
echo "🔧 Configuring Client_C1 (Routes + Python)..."

# Nettoyage des anciennes routes Docker qui bloquent
docker exec --privileged Client_C1 ip route del default || true

# Force le client à passer par la Box
docker exec --privileged Client_C1 ip route add default via 192.168.2.5

# Force un DNS public pour télécharger Python
docker exec --privileged Client_C1 sh -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"

# Installation des outils nécessaires au VPN
echo "📦 Installing Python3 and tools on Client_C1..."
docker exec --privileged Client_C1 pkill -9 apk || true
docker exec Client_C1 apk add --no-cache python3 iptables tcpdump

echo "✅ Box_C1 et Client_C1 sont opérationnels !"