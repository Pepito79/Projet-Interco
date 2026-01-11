#!/bin/sh

echo "🔥 Application des règles de redirection VPN (NAT)..."

# 1. Redirection de port (DNAT) : Tout ce qui arrive sur 9999 -> va vers le serveur VPN
iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 9999 -j DNAT --to-destination 10.10.20.4:9999

# 2. Autorisation de traversée (FORWARD)
iptables -A FORWARD -p tcp -d 10.10.20.4 --dport 9999 -j ACCEPT

echo "✅ Règles VPN appliquées avec succès."